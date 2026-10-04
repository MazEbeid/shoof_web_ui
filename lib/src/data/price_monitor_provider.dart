import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'anchor_prices_provider.dart';
import 'cities_constants.dart';
import 'postgrest_paging.dart';
import 'supabase_client_provider.dart';
import 'widget_data_providers.dart';

/// Crowd-entry price sanity floor (user-decided 2026-07-08): no tracked SKU
/// sells under 5 EGP, so cheaper "prices" are typos and are excluded from
/// every price aggregate (fn_price_monitor applies the same floor in SQL).
/// Raw Data deliberately still shows them — it is the audit surface.
const double kMinValidPrice = 5;

/// Time aggregation mode for price widgets
enum PriceTimeMode { today, wow, mom }

extension PriceTimeModeExtension on PriceTimeMode {
  String get label => switch (this) {
        PriceTimeMode.today => 'Today',
        PriceTimeMode.wow => 'WoW',
        PriceTimeMode.mom => 'MoM',
      };
}

/// Filters for price monitor widgets
class PriceFilterParams {
  final String missionId;
  final Set<String> skuKeys;
  final String? region;
  final String? city;
  final String? channel;
  final String? company;
  final String? brand;
  final String? package;
  final String? size;
  final DateTime? startDate;
  final DateTime? endDate;
  final PriceTimeMode timeMode;

  const PriceFilterParams({
    required this.missionId,
    this.skuKeys = const {},
    this.region,
    this.city,
    this.channel,
    this.company,
    this.brand,
    this.package,
    this.size,
    this.startDate,
    this.endDate,
    this.timeMode = PriceTimeMode.wow,
  });

  bool get hasFilters =>
      skuKeys.isNotEmpty ||
      region != null ||
      city != null ||
      channel != null ||
      company != null ||
      brand != null ||
      package != null ||
      size != null ||
      startDate != null ||
      endDate != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceFilterParams &&
          missionId == other.missionId &&
          setEquals(skuKeys, other.skuKeys) &&
          region == other.region &&
          city == other.city &&
          channel == other.channel &&
          company == other.company &&
          brand == other.brand &&
          package == other.package &&
          size == other.size &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          timeMode == other.timeMode;

  @override
  int get hashCode => Object.hash(
        missionId,
        Object.hashAllUnordered(skuKeys),
        region,
        city,
        channel,
        company,
        brand,
        package,
        size,
        startDate,
        endDate,
        timeMode,
      );
}

/// Single price observation row
class PriceObservation {
  final String skuKey;
  final String productName;
  final String? category;
  final String? brandOwner;
  final String? size;
  final String? packaging;
  final String? city;
  final String? channel;
  final String? locationName;
  final String observedDate;
  final double price;

  const PriceObservation({
    required this.skuKey,
    required this.productName,
    this.category,
    this.brandOwner,
    this.size,
    this.packaging,
    this.city,
    this.channel,
    this.locationName,
    required this.observedDate,
    required this.price,
  });

  String? get region {
    if (city == null) return null;
    final cityKey = city!.toLowerCase().replaceAll(' ', '');
    for (final entry in CITIES.entries) {
      final english = (entry.value['english'] as String?)?.toLowerCase();
      if (english == city!.toLowerCase() || entry.key == cityKey) {
        return entry.value['region'] as String?;
      }
    }
    return null;
  }

  factory PriceObservation.fromMap(Map<String, dynamic> map) {
    final productName =
        (map['product_name'] ?? map['product_name_ar'] ?? 'Unknown') as String;
    final size = map['size'] as String?;
    final packaging = map['packaging'] as String?;
    return PriceObservation(
      skuKey: '$productName|${size ?? ''}|${packaging ?? ''}',
      productName: productName,
      category: map['category'] as String? ?? map['brand_owner'] as String?,
      brandOwner: map['brand_owner'] as String?,
      size: size,
      packaging: packaging,
      city: map['city'] as String?,
      channel: map['channel'] as String?,
      locationName: map['location_name'] as String?,
      observedDate: map['observed_date']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PriceTrendPoint {
  final String label;
  final double? avgPrice;
  final int count;

  const PriceTrendPoint({
    required this.label,
    this.avgPrice,
    this.count = 0,
  });

  bool get hasData => avgPrice != null;
}

class PriceTrendSeries {
  final String skuKey;
  final String skuLabel;
  final int colorIndex;
  final List<PriceTrendPoint> points;

  const PriceTrendSeries({
    required this.skuKey,
    required this.skuLabel,
    required this.colorIndex,
    required this.points,
  });
}

class PriceTrendChartData {
  final List<String> dateLabels;
  final List<PriceTrendSeries> series;

  /// Set when the provider changed granularity (or has too little history)
  /// so the widget can explain what is being shown.
  final String? granularityNote;

  const PriceTrendChartData({
    this.dateLabels = const [],
    this.series = const [],
    this.granularityNote,
  });

  bool get isEmpty => series.isEmpty || dateLabels.isEmpty;
}

/// Distinct colors for multi-SKU trend lines (widget maps index to Color).
const priceTrendColorCount = 12;

class PriceVsAnchorRow {
  final String skuKey;
  final String productName;
  final String? channel;
  final String? city;
  final double observedAvg;
  final double? anchorPrice;
  final int observationCount;

  const PriceVsAnchorRow({
    required this.skuKey,
    required this.productName,
    this.channel,
    this.city,
    required this.observedAvg,
    this.anchorPrice,
    required this.observationCount,
  });

  double? get deviationPercent {
    if (anchorPrice == null || anchorPrice == 0) return null;
    return ((observedAvg - anchorPrice!) / anchorPrice!) * 100;
  }
}

DateTime _todayDate() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

(bool, String, String) _dateRangeForMode(PriceTimeMode mode) {
  final today = _todayDate();
  switch (mode) {
    case PriceTimeMode.today:
      final s = _formatDate(today);
      return (true, s, s);
    case PriceTimeMode.wow:
      final start = today.subtract(const Duration(days: 56));
      return (false, _formatDate(start), _formatDate(today));
    case PriceTimeMode.mom:
      final start = today.subtract(const Duration(days: 180));
      return (false, _formatDate(start), _formatDate(today));
  }
}

List<String> _citiesForRegion(String? region) {
  if (region == null) return [];
  return CITIES.entries
      .where((e) => e.value['region'] == region)
      .map((e) => e.value['english'] as String)
      .toList();
}

bool _matchesRegion(PriceObservation obs, String? region) {
  if (region == null) return true;
  return obs.region == region;
}

final priceCategoriesForMissionProvider =
    FutureProvider.family<List<String>, String>((ref, missionId) async {
  final supabase = ref.watch(sharedSupabaseProvider);
  try {
    final response = await supabase
        .from('mission_price_sku_cache')
        .select('brand_owner')
        .eq('mission_id', missionId);
    return (response as List)
        .map((e) => e['brand_owner'] as String?)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  } catch (e) {
    return [];
  }
});

class PriceSkuListParams {
  final String missionId;
  final String? category;

  const PriceSkuListParams({
    required this.missionId,
    this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceSkuListParams &&
          missionId == other.missionId &&
          category == other.category;

  @override
  int get hashCode => Object.hash(missionId, category);
}

class PriceSkuOption {
  final String skuKey;
  final String label;
  final String? category;

  const PriceSkuOption({
    required this.skuKey,
    required this.label,
    this.category,
  });
}

/// Distinct SKUs for a mission, optionally filtered by brand/category.
final priceSkuOptionsProvider =
    FutureProvider.family<List<PriceSkuOption>, PriceSkuListParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);
  try {
    var query = supabase
        .from('mission_price_sku_cache')
        .select('product_name, size, packaging, brand_owner')
        .eq('mission_id', params.missionId);

    if (params.category != null) {
      query = query.eq('brand_owner', params.category!);
    }

    final response = await query.order('product_name');
    final seen = <String>{};
    final options = <PriceSkuOption>[];

    for (final row in response as List) {
      final name = row['product_name'] as String? ?? 'Unknown';
      final size = row['size'] as String?;
      final packaging = row['packaging'] as String?;
      final skuKey = priceSkuKey(
        productName: name,
        size: size,
        packaging: packaging,
      );
      if (seen.contains(skuKey)) continue;
      seen.add(skuKey);
      options.add(PriceSkuOption(
        skuKey: skuKey,
        label: priceSkuLabel(skuKey),
        category: row['brand_owner'] as String?,
      ));
    }

    options.sort((a, b) => a.label.compareTo(b.label));
    return options;
  } catch (e) {
    return [];
  }
});

final priceSkusForMissionProvider =
    FutureProvider.family<List<String>, String>((ref, missionId) async {
  final options = await ref.watch(
      priceSkuOptionsProvider(PriceSkuListParams(missionId: missionId)).future);
  return options.map((o) => o.skuKey).toList()..sort();
});

/// RAW observation rows - ONLY for the drill-down dialog
/// (price_observations_dialog.dart). Every chart/table aggregates server-side
/// via [fetchPriceSeries]; never feed a widget from this provider again.
/// Capped at 5 pages so a broad filter cannot page the whole window.
final rawPriceObservationsProvider =
    FutureProvider.family<List<PriceObservation>, PriceFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);
  final (_, modeStart, modeEnd) = _dateRangeForMode(params.timeMode);
  final hasExplicitDateRange =
      params.startDate != null || params.endDate != null;

  try {
    // Paged fetch: PostgREST caps every response at 1,000 rows regardless
    // of .limit(), and price windows run to ~85K rows. Narrow columns to
    // exactly what PriceObservation.fromMap reads; stable order for paging.
    final response = await fetchAllPages((from, to) {
      var query = supabase
          .from('v_price_observations')
          .select('product_name, product_name_ar, size, packaging, category, '
              'brand_owner, city, channel, location_name, observed_date, price, id')
          .eq('mission_id', params.missionId)
          .gte('price', kMinValidPrice);

      // Explicit user range wins; otherwise the mode window bounds the fetch
      // (today = today, WoW = 56 days, MoM = 180 days) so we never pull the
      // whole mission history.
      if (hasExplicitDateRange) {
        query = query
            .gte(
              'observed_date',
              _formatDate(params.startDate ?? DateTime(2000)),
            )
            .lte(
              'observed_date',
              _formatDate(params.endDate ?? _todayDate()),
            );
      } else {
        query = query
            .gte('observed_date', modeStart)
            .lte('observed_date', modeEnd);
      }

      if (params.city != null) {
        query = query.eq('city', params.city!);
      }
      if (params.channel != null) {
        query = query.eq('channel', params.channel!);
      }
      return query.order('id', ascending: true).range(from, to);
    }, maxRows: 5000);
    var list = response.map(PriceObservation.fromMap).toList();

    if (params.skuKeys.isNotEmpty) {
      list = list.where((o) => params.skuKeys.contains(o.skuKey)).toList();
    }
    if (params.region != null) {
      list = list.where((o) => _matchesRegion(o, params.region)).toList();
    }

    return list;
  } catch (e) {
    return [];
  }
});

// =============================================================================
// fn_price_series — the ONE server-side aggregation behind the trend, SKU
// summary, price-vs-anchor, comparison and availability-vs-price widgets.
// Raw observations never reach the browser: PostgREST caps responses at
// 1,000 rows and an 8-week window holds ~50K observations (2026-09-08).
// =============================================================================

enum PriceBucket { none, day, month }

/// One grouped row of fn_price_series. Label columns are null for the
/// dimensions the caller did not group by.
class PriceSeriesRow {
  final String bucket;
  final String? skuKey;
  final String? productName;
  final String? size;
  final String? packaging;
  final String? city;
  final String? channel;
  final double avgPrice;
  final double minPrice;
  final double maxPrice;
  final int count;

  const PriceSeriesRow({
    required this.bucket,
    this.skuKey,
    this.productName,
    this.size,
    this.packaging,
    this.city,
    this.channel,
    required this.avgPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.count,
  });

  factory PriceSeriesRow.fromMap(Map<String, dynamic> m) => PriceSeriesRow(
        bucket: m['bucket']?.toString() ?? 'all',
        skuKey: m['sku_key'] as String?,
        productName: m['product_name'] as String?,
        size: m['size'] as String?,
        packaging: m['packaging'] as String?,
        city: m['city'] as String?,
        channel: m['channel'] as String?,
        avgPrice: _monitorDouble(m['avg_price']) ?? 0,
        minPrice: _monitorDouble(m['min_price']) ?? 0,
        maxPrice: _monitorDouble(m['max_price']) ?? 0,
        count: (m['n'] as num?)?.toInt() ?? 0,
      );
}

/// Grouped price aggregates for [params] via fn_price_series. Region is
/// resolved to the mission's DB city values (same as the overview widgets);
/// the date window comes from explicit dates or the time mode. Errors
/// rethrow by design so widgets show an error state, never silent zeros.
Future<List<PriceSeriesRow>> fetchPriceSeries(
  Ref ref,
  PriceFilterParams params, {
  PriceBucket bucket = PriceBucket.none,
  bool groupSku = true,
  bool groupCity = false,
  bool groupChannel = false,
  Set<String>? skuKeys,
}) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  List<String>? regionCities;
  if (params.region != null) {
    final cities =
        await ref.watch(missionCitiesProvider(params.missionId).future);
    regionCities = citiesForRegion(params.region!, cities);
  }

  final (_, modeStart, modeEnd) = _dateRangeForMode(params.timeMode);
  final hasExplicitDateRange =
      params.startDate != null || params.endDate != null;
  final start = hasExplicitDateRange
      ? _formatDate(params.startDate ?? DateTime(2000))
      : modeStart;
  final end = hasExplicitDateRange
      ? _formatDate(params.endDate ?? _todayDate())
      : modeEnd;

  final keys = skuKeys ?? params.skuKeys;
  final rpcParams = <String, dynamic>{
    'p_mission_id': params.missionId,
    'p_sku_keys': keys.isEmpty ? null : (keys.toList()..sort()),
    'p_city': params.city,
    'p_cities': regionCities,
    'p_channel': params.channel,
    'p_start_date': start,
    'p_end_date': end,
    'p_bucket': bucket.name,
    'p_group_sku': groupSku,
    'p_group_city': groupCity,
    'p_group_channel': groupChannel,
  };

  // Grouped output is small, but sku x city x channel can pass the 1,000-row
  // cap - page it (the RPC orders its rows deterministically).
  final rows = await fetchAllPages((from, to) async {
    final res =
        await supabase.rpc('fn_price_series', params: rpcParams).range(from, to);
    return res as List<dynamic>;
  });
  return rows.map(PriceSeriesRow.fromMap).toList();
}

PriceBucket _bucketForMode(PriceTimeMode mode) => switch (mode) {
      PriceTimeMode.today => PriceBucket.none,
      PriceTimeMode.wow => PriceBucket.day,
      PriceTimeMode.mom => PriceBucket.month,
    };

final priceTrendProvider =
    FutureProvider.family<PriceTrendChartData, PriceFilterParams>(
        (ref, params) async {
  if (params.skuKeys.isEmpty) {
    return const PriceTrendChartData();
  }

  var effectiveMode = params.timeMode;
  String? granularityNote;

  var rows =
      await fetchPriceSeries(ref, params, bucket: _bucketForMode(effectiveMode));
  if (rows.isEmpty) return const PriceTrendChartData();

  // Granularity fallback: MoM with less than 2 months of history collapses
  // every series to a single dot - drop to daily buckets and say so.
  if (effectiveMode == PriceTimeMode.mom &&
      rows.map((r) => r.bucket).toSet().length < 2) {
    effectiveMode = PriceTimeMode.wow; // buckets by day
    granularityNote =
        'Not enough monthly history for month-over-month - showing daily prices';
    rows = await fetchPriceSeries(ref, params, bucket: PriceBucket.day);
  }
  if (effectiveMode != PriceTimeMode.today &&
      granularityNote == null &&
      rows.map((r) => r.bucket).toSet().length < 2) {
    granularityNote = 'Only one day of price data so far';
  }

  final sortedSkuKeys = params.skuKeys.toList()..sort();
  final perSku = <String, Map<String, PriceTrendPoint>>{};
  for (final r in rows) {
    final key = r.skuKey;
    if (key == null) continue;
    final label = effectiveMode == PriceTimeMode.today ? 'Today' : r.bucket;
    perSku.putIfAbsent(key, () => {})[label] =
        PriceTrendPoint(label: label, avgPrice: r.avgPrice, count: r.count);
  }
  if (perSku.isEmpty) return const PriceTrendChartData();

  final dateLabels =
      perSku.values.expand((points) => points.keys).toSet().toList()..sort();

  final series = <PriceTrendSeries>[];
  var colorIndex = 0;
  for (final skuKey in sortedSkuKeys) {
    final byLabel = perSku[skuKey];
    if (byLabel == null) continue;

    series.add(PriceTrendSeries(
      skuKey: skuKey,
      skuLabel: priceSkuLabel(skuKey),
      colorIndex: colorIndex % priceTrendColorCount,
      points: dateLabels.map((label) {
        final point = byLabel[label];
        return PriceTrendPoint(
          label: label,
          avgPrice: point?.avgPrice,
          count: point?.count ?? 0,
        );
      }).toList(),
    ));
    colorIndex++;
  }

  return PriceTrendChartData(
    dateLabels: dateLabels,
    series: series,
    granularityNote: granularityNote,
  );
});

class PriceSkuSummary {
  final String skuKey;
  final String skuLabel;
  final double avgPrice;
  final double minPrice;
  final double maxPrice;
  final int observationCount;
  final int colorIndex;

  const PriceSkuSummary({
    required this.skuKey,
    required this.skuLabel,
    required this.avgPrice,
    this.minPrice = 0,
    this.maxPrice = 0,
    required this.observationCount,
    required this.colorIndex,
  });
}

class PriceSpreadSummary {
  final double spread;
  final String highLabel;
  final String lowLabel;
  final int hiddenSkuCount;

  const PriceSpreadSummary({
    required this.spread,
    required this.highLabel,
    required this.lowLabel,
    this.hiddenSkuCount = 0,
  });
}

class PriceSkuSummaryData {
  final List<PriceSkuSummary> skus;
  final PriceSpreadSummary? spread;

  const PriceSkuSummaryData({
    this.skus = const [],
    this.spread,
  });

  bool get isEmpty => skus.isEmpty;
}

/// Average / min / max shelf price per selected SKU for the current filter
/// window (fn_price_series grouped by SKU).
final priceSkuSummaryProvider =
    FutureProvider.family<PriceSkuSummaryData, PriceFilterParams>(
        (ref, params) async {
  if (params.skuKeys.isEmpty) return const PriceSkuSummaryData();

  final rows = await fetchPriceSeries(ref, params);
  if (rows.isEmpty) return const PriceSkuSummaryData();
  final bySku = {
    for (final r in rows)
      if (r.skuKey != null) r.skuKey!: r,
  };

  final sortedSkuKeys = params.skuKeys.toList()..sort();
  final summaries = <PriceSkuSummary>[];
  var colorIndex = 0;

  for (final skuKey in sortedSkuKeys) {
    final r = bySku[skuKey];
    if (r == null) continue;
    summaries.add(PriceSkuSummary(
      skuKey: skuKey,
      skuLabel: priceSkuLabel(skuKey),
      avgPrice: r.avgPrice,
      minPrice: r.minPrice,
      maxPrice: r.maxPrice,
      observationCount: r.count,
      colorIndex: colorIndex % priceTrendColorCount,
    ));
    colorIndex++;
  }

  PriceSpreadSummary? spread;
  if (summaries.length >= 2) {
    final sorted = [...summaries]..sort((a, b) => b.avgPrice.compareTo(a.avgPrice));
    final high = sorted.first;
    final low = sorted.last;
    spread = PriceSpreadSummary(
      spread: high.avgPrice - low.avgPrice,
      highLabel: high.skuLabel,
      lowLabel: low.skuLabel,
      hiddenSkuCount: 0,
    );
  }

  return PriceSkuSummaryData(skus: summaries, spread: spread);
});

/// Observed average per (SKU, channel, city) for every SKU that has an
/// anchor (fn_price_series grouped by all three), sorted by deviation.
final priceVsAnchorProvider =
    FutureProvider.family<List<PriceVsAnchorRow>, PriceVsAnchorParams>(
        (ref, params) async {
  if (params.anchorPrices.isEmpty) return [];

  final rows = await fetchPriceSeries(
    ref,
    params.filters,
    groupSku: true,
    groupCity: true,
    groupChannel: true,
    skuKeys: params.anchorPrices.keys.toSet(),
  );

  return rows
      .where((r) => r.skuKey != null && params.anchorPrices[r.skuKey!] != null)
      .map((r) => PriceVsAnchorRow(
            skuKey: r.skuKey!,
            productName: r.productName ?? r.skuKey!,
            channel: r.channel,
            city: r.city,
            observedAvg: r.avgPrice,
            anchorPrice: params.anchorPrices[r.skuKey!],
            observationCount: r.count,
          ))
      .toList()
    ..sort((a, b) =>
        (b.deviationPercent ?? 0).compareTo(a.deviationPercent ?? 0));
});

class PriceVsAnchorParams {
  final PriceFilterParams filters;
  final Map<String, double> anchorPrices;

  const PriceVsAnchorParams({
    required this.filters,
    this.anchorPrices = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceVsAnchorParams &&
          filters == other.filters &&
          _mapEquals(anchorPrices, other.anchorPrices);

  @override
  int get hashCode => Object.hash(filters, anchorPrices.length);

  static bool _mapEquals(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Region list derived from CITIES constant
List<String> get priceRegions {
  return CITIES.values
      .map((c) => c['region'] as String)
      .toSet()
      .toList()
    ..sort();
}

/// Cities for a given region
List<String> citiesForPriceRegion(String? region) => _citiesForRegion(region);

// =============================================================================
// PRICE COMPARISON (avg price by city / channel)
// =============================================================================

enum PriceGroupDimension { city, channel }

class PriceComparisonParams {
  final PriceFilterParams filters;
  final PriceGroupDimension dimension;

  const PriceComparisonParams({
    required this.filters,
    this.dimension = PriceGroupDimension.city,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceComparisonParams &&
          filters == other.filters &&
          dimension == other.dimension;

  @override
  int get hashCode => Object.hash(filters, dimension);
}

class PriceGroupStat {
  final String label;
  final double avgPrice;
  final int observationCount;

  const PriceGroupStat({
    required this.label,
    required this.avgPrice,
    required this.observationCount,
  });
}

/// Average price of the selected SKUs grouped by city or channel
/// (fn_price_series grouped by that one dimension, SKUs pooled).
final priceComparisonProvider =
    FutureProvider.family<List<PriceGroupStat>, PriceComparisonParams>(
        (ref, params) async {
  if (params.filters.skuKeys.isEmpty) return [];

  final byCity = params.dimension == PriceGroupDimension.city;
  final rows = await fetchPriceSeries(
    ref,
    params.filters,
    groupSku: false,
    groupCity: byCity,
    groupChannel: !byCity,
  );
  if (rows.isEmpty) return [];

  // Blank labels pool into 'Unknown' (observation-weighted average).
  final sums = <String, double>{};
  final counts = <String, int>{};
  for (final r in rows) {
    final raw = byCity ? r.city : r.channel;
    final label = (raw == null || raw.trim().isEmpty) ? 'Unknown' : raw.trim();
    sums[label] = (sums[label] ?? 0) + r.avgPrice * r.count;
    counts[label] = (counts[label] ?? 0) + r.count;
  }

  return sums.entries
      .map((e) => PriceGroupStat(
            label: e.key,
            avgPrice: counts[e.key]! == 0 ? 0 : e.value / counts[e.key]!,
            observationCount: counts[e.key]!,
          ))
      .toList()
    ..sort((a, b) => b.avgPrice.compareTo(a.avgPrice));
});

// =============================================================================
// AVAILABILITY vs PRICE (Availability Analysis price view)
// =============================================================================

class AvailabilityPriceRow {
  final String skuLabel;
  final double availabilityRate; // 0–100
  final double? avgPrice; // null when no price observation matched
  final int totalChecks;
  final int observationCount;
  final bool flagged; // scarce (<50% availability) AND priced above median

  const AvailabilityPriceRow({
    required this.skuLabel,
    required this.availabilityRate,
    this.avgPrice,
    required this.totalChecks,
    required this.observationCount,
    required this.flagged,
  });
}

String _normalizedProductName(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// Joins availability % (fn_sku_availability_filtered) with the avg observed
/// price (fn_price_series) per SKU, matched on normalized product name.
/// Unmatched SKUs are kept with a null price rather than dropped.
final availabilityVsPriceProvider =
    FutureProvider.family<List<AvailabilityPriceRow>, PriceFilterParams>(
        (ref, params) async {
  // Thread the caller's filters through both sides so the join reflects the
  // same slice of data (previously only missionId was passed).
  final availability = await ref.watch(skuAvailabilityForWidgetProvider(
    WidgetFilterParams(
      missionId: params.missionId,
      company: params.company,
      brand: params.brand,
      package: params.package,
      size: params.size,
      city: params.city,
      channel: params.channel,
      startDate: params.startDate,
      endDate: params.endDate,
    ),
  ).future);
  if (availability.isEmpty) return [];

  // Per-SKU price aggregates for the same slice, server-side. The SKU dims
  // are applied by restricting to the availability side's SKU name-set below
  // (fn_price_series has no company/brand columns to filter on).
  final priceRows = await fetchPriceSeries(
    ref,
    PriceFilterParams(
      missionId: params.missionId,
      city: params.city,
      channel: params.channel,
      startDate: params.startDate,
      endDate: params.endDate,
      timeMode: params.timeMode,
    ),
  );

  final availabilityNames = availability
      .map((sku) => _normalizedProductName(sku.skuEnglish))
      .toSet();

  // Sizes/packagings of one product pool into a single observation-weighted
  // average, exactly as the raw-row version did.
  final sumByName = <String, double>{};
  final countsByName = <String, int>{};
  for (final r in priceRows) {
    final name = r.productName;
    if (name == null) continue;
    final key = _normalizedProductName(name);
    if (!availabilityNames.contains(key)) continue;
    sumByName[key] = (sumByName[key] ?? 0) + r.avgPrice * r.count;
    countsByName[key] = (countsByName[key] ?? 0) + r.count;
  }

  final avgByName = sumByName.map(
      (key, sum) => MapEntry(key, sum / (countsByName[key] ?? 1)));

  double? medianPrice;
  if (avgByName.isNotEmpty) {
    final sorted = avgByName.values.toList()..sort();
    medianPrice = sorted[sorted.length ~/ 2];
  }

  final rows = availability.map((sku) {
    final key = _normalizedProductName(sku.skuEnglish);
    final avgPrice = avgByName[key];
    final flagged = avgPrice != null &&
        medianPrice != null &&
        sku.availabilityRate < 50 &&
        avgPrice > medianPrice;
    return AvailabilityPriceRow(
      skuLabel: sku.skuEnglish,
      availabilityRate: sku.availabilityRate,
      avgPrice: avgPrice,
      totalChecks: sku.totalChecks,
      observationCount: countsByName[key] ?? 0,
      flagged: flagged,
    );
  }).toList()
    ..sort((a, b) {
      if (a.flagged != b.flagged) return a.flagged ? -1 : 1;
      return a.availabilityRate.compareTo(b.availabilityRate);
    });

  return rows;
});

// =============================================================================
// PRICE MONITOR (fn_price_monitor) — analyst table: modal latest-week price,
// latest vs trailing-4-week average, min/max spread, weekly sparkline series,
// latest-week price histogram (anchor compliance computed in the widget).
// =============================================================================

double? _monitorDouble(Object? v) =>
    v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));

/// One SKU row of the Price Monitor table.
class PriceMonitorRow {
  final String sku;
  final String? brand;
  final String? company;
  final String? size;
  final String? packaging;
  final double? latestMode;
  final double? latestAvg;
  final int latestObs;
  final double? trailingAvg;
  final double? minPrice;
  final double? maxPrice;
  final int totalObs;

  /// Ordered weekly averages across the window (sparkline).
  final List<double> weeklyAvgs;

  /// Latest-week price histogram: exact shelf price -> observation count.
  final Map<double, int> latestPrices;

  const PriceMonitorRow({
    required this.sku,
    this.brand,
    this.company,
    this.size,
    this.packaging,
    this.latestMode,
    this.latestAvg,
    required this.latestObs,
    this.trailingAvg,
    this.minPrice,
    this.maxPrice,
    required this.totalObs,
    required this.weeklyAvgs,
    required this.latestPrices,
  });

  /// Latest-week average vs trailing 4-week average, in percent.
  double? get changePercent =>
      (latestAvg != null && trailingAvg != null && trailingAvg != 0)
          ? (latestAvg! - trailingAvg!) / trailingAvg! * 100
          : null;

  factory PriceMonitorRow.fromMap(Map<String, dynamic> map) {
    final weekly = (map['weekly'] as List? ?? const [])
        .map((e) => _monitorDouble((e as Map)['a']))
        .whereType<double>()
        .toList();
    final hist = <double, int>{};
    (map['latest_prices'] as Map? ?? const {}).forEach((k, v) {
      final price = double.tryParse(k.toString());
      if (price != null) hist[price] = (v as num).toInt();
    });
    return PriceMonitorRow(
      sku: map['sku'] as String? ?? 'Unknown',
      brand: map['brand'] as String?,
      company: map['company'] as String?,
      size: map['size'] as String?,
      packaging: map['packaging'] as String?,
      latestMode: _monitorDouble(map['latest_mode']),
      latestAvg: _monitorDouble(map['latest_avg']),
      latestObs: (map['latest_obs'] as num?)?.toInt() ?? 0,
      trailingAvg: _monitorDouble(map['trailing_avg']),
      minPrice: _monitorDouble(map['min_price']),
      maxPrice: _monitorDouble(map['max_price']),
      totalObs: (map['total_obs'] as num?)?.toInt() ?? 0,
      weeklyAvgs: weekly,
      latestPrices: hist,
    );
  }
}

/// Price Monitor rows, RPC-always (errors rethrow by design). Sorted by
/// change magnitude so the SKUs that moved lead the table.
final priceMonitorProvider =
    FutureProvider.family<List<PriceMonitorRow>, WidgetFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);
  final regionCities = await citiesForRegionFilter(ref, params);

  final rpcResponse = await supabase.rpc('fn_price_monitor', params: {
    'p_mission_id': params.missionId,
    'p_city': params.city,
    'p_cities': regionCities,
    'p_channel': params.channel,
    'p_company': params.company,
    'p_brand': params.brand,
    'p_package': params.package,
    'p_size': params.size,
    'p_start_date': params.startDate?.toIso8601String().split('T')[0],
    'p_end_date': params.endDate?.toIso8601String().split('T')[0],
  });

  return ((rpcResponse as List)
      .map((e) => PriceMonitorRow.fromMap(e as Map<String, dynamic>))
      .toList())
    ..sort((a, b) => (b.changePercent?.abs() ?? -1)
        .compareTo(a.changePercent?.abs() ?? -1));
});
