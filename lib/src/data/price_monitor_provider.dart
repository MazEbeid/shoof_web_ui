import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'anchor_prices_provider.dart';
import 'cities_constants.dart';
import 'supabase_client_provider.dart';
import 'widget_data_providers.dart';

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
  final DateTime? startDate;
  final DateTime? endDate;
  final PriceTimeMode timeMode;

  const PriceFilterParams({
    required this.missionId,
    this.skuKeys = const {},
    this.region,
    this.city,
    this.channel,
    this.startDate,
    this.endDate,
    this.timeMode = PriceTimeMode.wow,
  });

  bool get hasFilters =>
      skuKeys.isNotEmpty ||
      region != null ||
      city != null ||
      channel != null ||
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

  const PriceTrendChartData({
    this.dateLabels = const [],
    this.series = const [],
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
        .from('v_price_observations')
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
        .from('v_price_observations')
        .select('product_name, size, packaging, brand_owner')
        .eq('mission_id', params.missionId)
        .gt('price', 0);

    if (params.category != null) {
      query = query.eq('brand_owner', params.category!);
    }

    final response = await query.limit(10000);
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
  final observations =
      await ref.watch(rawPriceObservationsProvider(PriceFilterParams(missionId: missionId)).future);
  return observations.map((o) => o.skuKey).toSet().toList()..sort();
});

final rawPriceObservationsProvider =
    FutureProvider.family<List<PriceObservation>, PriceFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);
  final (_, modeStart, modeEnd) = _dateRangeForMode(params.timeMode);
  final hasExplicitDateRange =
      params.startDate != null || params.endDate != null;

  try {
    var query = supabase
        .from('v_price_observations')
        .select()
        .eq('mission_id', params.missionId)
        .gt('price', 0);

    // Only constrain dates when the user picks a range, or for the Today widget.
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
    } else if (params.timeMode == PriceTimeMode.today) {
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

    final response = await query.limit(20000);
    var list = (response as List)
        .map((e) => PriceObservation.fromMap(e as Map<String, dynamic>))
        .toList();

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

String _bucketKey(String observedDate, PriceTimeMode mode) {
  if (mode == PriceTimeMode.mom) {
    return observedDate.length >= 7 ? observedDate.substring(0, 7) : observedDate;
  }
  return observedDate;
}

List<PriceTrendPoint> _bucketObservations(
  List<PriceObservation> observations,
  PriceTimeMode mode,
) {
  final buckets = <String, List<double>>{};
  for (final obs in observations) {
    final key = _bucketKey(obs.observedDate, mode);
    buckets.putIfAbsent(key, () => []).add(obs.price);
  }
  final keys = buckets.keys.toList()..sort();
  return keys.map((key) {
    final prices = buckets[key]!;
    return PriceTrendPoint(
      label: key,
      avgPrice: prices.reduce((a, b) => a + b) / prices.length,
      count: prices.length,
    );
  }).toList();
}

final priceTrendProvider =
    FutureProvider.family<PriceTrendChartData, PriceFilterParams>(
        (ref, params) async {
  if (params.skuKeys.isEmpty) {
    return const PriceTrendChartData();
  }

  final baseParams = PriceFilterParams(
    missionId: params.missionId,
    skuKeys: params.skuKeys,
    region: params.region,
    city: params.city,
    channel: params.channel,
    startDate: params.startDate,
    endDate: params.endDate,
    timeMode: params.timeMode,
  );

  final observations =
      await ref.watch(rawPriceObservationsProvider(baseParams).future);
  if (observations.isEmpty) return const PriceTrendChartData();

  final sortedSkuKeys = params.skuKeys.toList()..sort();
  final perSkuBuckets = <String, List<PriceTrendPoint>>{};

  for (final skuKey in sortedSkuKeys) {
    final skuObs =
        observations.where((o) => o.skuKey == skuKey).toList();
    if (skuObs.isEmpty) continue;

    if (params.timeMode == PriceTimeMode.today) {
      final prices = skuObs.map((o) => o.price).toList();
      perSkuBuckets[skuKey] = [
        PriceTrendPoint(
          label: 'Today',
          avgPrice: prices.reduce((a, b) => a + b) / prices.length,
          count: prices.length,
        ),
      ];
    } else {
      perSkuBuckets[skuKey] = _bucketObservations(skuObs, params.timeMode);
    }
  }

  if (perSkuBuckets.isEmpty) return const PriceTrendChartData();

  final dateLabels = perSkuBuckets.values
      .expand((points) => points.map((p) => p.label))
      .toSet()
      .toList()
    ..sort();

  final series = <PriceTrendSeries>[];
  var colorIndex = 0;
  for (final skuKey in sortedSkuKeys) {
    final buckets = perSkuBuckets[skuKey];
    if (buckets == null) continue;

    final byLabel = {for (final p in buckets) p.label: p};
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

  return PriceTrendChartData(dateLabels: dateLabels, series: series);
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

/// Raw average shelf price per selected SKU for the current filter window.
final priceSkuSummaryProvider =
    FutureProvider.family<PriceSkuSummaryData, PriceFilterParams>(
        (ref, params) async {
  if (params.skuKeys.isEmpty) return const PriceSkuSummaryData();

  final observations =
      await ref.watch(rawPriceObservationsProvider(params).future);
  if (observations.isEmpty) return const PriceSkuSummaryData();

  final sortedSkuKeys = params.skuKeys.toList()..sort();
  final summaries = <PriceSkuSummary>[];
  var colorIndex = 0;

  for (final skuKey in sortedSkuKeys) {
    final skuObs = observations.where((o) => o.skuKey == skuKey).toList();
    if (skuObs.isEmpty) continue;

    final prices = skuObs.map((o) => o.price).toList()..sort();
    summaries.add(PriceSkuSummary(
      skuKey: skuKey,
      skuLabel: priceSkuLabel(skuKey),
      avgPrice: prices.reduce((a, b) => a + b) / prices.length,
      minPrice: prices.first,
      maxPrice: prices.last,
      observationCount: prices.length,
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

final priceVsAnchorProvider =
    FutureProvider.family<List<PriceVsAnchorRow>, PriceVsAnchorParams>(
        (ref, params) async {
  final observations =
      await ref.watch(rawPriceObservationsProvider(params.filters).future);
  if (observations.isEmpty) return [];

  final groupKey = (PriceObservation o) =>
      '${o.skuKey}|${o.channel ?? ''}|${o.city ?? ''}';
  final groups = <String, List<PriceObservation>>{};
  for (final obs in observations) {
    groups.putIfAbsent(groupKey(obs), () => []).add(obs);
  }

  return groups.entries.map((entry) {
    final obs = entry.value.first;
    final avg =
        entry.value.map((o) => o.price).reduce((a, b) => a + b) / entry.value.length;
    return PriceVsAnchorRow(
      skuKey: obs.skuKey,
      productName: obs.productName,
      channel: obs.channel,
      city: obs.city,
      observedAvg: avg,
      anchorPrice: params.anchorPrices[obs.skuKey],
      observationCount: entry.value.length,
    );
  }).where((row) => row.anchorPrice != null).toList()
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

/// Average price of the selected SKUs grouped by city or channel.
final priceComparisonProvider =
    FutureProvider.family<List<PriceGroupStat>, PriceComparisonParams>(
        (ref, params) async {
  if (params.filters.skuKeys.isEmpty) return [];

  final observations =
      await ref.watch(rawPriceObservationsProvider(params.filters).future);
  if (observations.isEmpty) return [];

  final groups = <String, List<double>>{};
  for (final obs in observations) {
    final raw = params.dimension == PriceGroupDimension.city
        ? obs.city
        : obs.channel;
    final label = (raw == null || raw.trim().isEmpty) ? 'Unknown' : raw.trim();
    groups.putIfAbsent(label, () => []).add(obs.price);
  }

  final stats = groups.entries
      .map((e) => PriceGroupStat(
            label: e.key,
            avgPrice: e.value.reduce((a, b) => a + b) / e.value.length,
            observationCount: e.value.length,
          ))
      .toList()
    ..sort((a, b) => b.avgPrice.compareTo(a.avgPrice));
  return stats;
});

// =============================================================================
// PRICE MOVERS (biggest WoW / MoM changes)
// =============================================================================

class PriceMoverRow {
  final String skuKey;
  final String skuLabel;
  final String previousLabel;
  final String currentLabel;
  final double previousAvg;
  final double currentAvg;
  final int observationCount;

  const PriceMoverRow({
    required this.skuKey,
    required this.skuLabel,
    required this.previousLabel,
    required this.currentLabel,
    required this.previousAvg,
    required this.currentAvg,
    required this.observationCount,
  });

  double get changePercent =>
      previousAvg == 0 ? 0 : ((currentAvg - previousAvg) / previousAvg) * 100;
}

/// Monday of the ISO week, used as a sortable weekly bucket key.
String _weekBucketKey(String observedDate) {
  final date = DateTime.tryParse(observedDate);
  if (date == null) return observedDate;
  final monday = date.subtract(Duration(days: date.weekday - 1));
  return _formatDate(monday);
}

/// SKUs with the biggest average-price change between the two most recent
/// periods (weeks for WoW, months for MoM). Computed client-side from
/// v_price_observations — no aggregate view exists in Supabase.
final priceMoversProvider =
    FutureProvider.family<List<PriceMoverRow>, PriceFilterParams>(
        (ref, params) async {
  final mode = params.timeMode == PriceTimeMode.mom
      ? PriceTimeMode.mom
      : PriceTimeMode.wow;
  final baseParams = PriceFilterParams(
    missionId: params.missionId,
    skuKeys: params.skuKeys,
    region: params.region,
    city: params.city,
    channel: params.channel,
    timeMode: mode,
  );

  final observations =
      await ref.watch(rawPriceObservationsProvider(baseParams).future);
  if (observations.isEmpty) return [];

  // sku -> bucket -> prices
  final perSku = <String, Map<String, List<double>>>{};
  for (final obs in observations) {
    final bucket = mode == PriceTimeMode.mom
        ? _bucketKey(obs.observedDate, PriceTimeMode.mom)
        : _weekBucketKey(obs.observedDate);
    perSku
        .putIfAbsent(obs.skuKey, () => {})
        .putIfAbsent(bucket, () => [])
        .add(obs.price);
  }

  final movers = <PriceMoverRow>[];
  perSku.forEach((skuKey, buckets) {
    if (buckets.length < 2) return;
    final keys = buckets.keys.toList()..sort();
    final previousKey = keys[keys.length - 2];
    final currentKey = keys.last;
    final previousPrices = buckets[previousKey]!;
    final currentPrices = buckets[currentKey]!;
    movers.add(PriceMoverRow(
      skuKey: skuKey,
      skuLabel: priceSkuLabel(skuKey),
      previousLabel: previousKey,
      currentLabel: currentKey,
      previousAvg:
          previousPrices.reduce((a, b) => a + b) / previousPrices.length,
      currentAvg: currentPrices.reduce((a, b) => a + b) / currentPrices.length,
      observationCount: previousPrices.length + currentPrices.length,
    ));
  });

  movers.sort(
      (a, b) => b.changePercent.abs().compareTo(a.changePercent.abs()));
  return movers.take(10).toList();
});

// =============================================================================
// AVAILABILITY VS PRICE
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

/// Joins availability % (v_availability_by_sku) with avg observed price
/// (v_price_observations) per SKU, matched on normalized product name.
/// Unmatched SKUs are kept with a null price rather than dropped.
final availabilityVsPriceProvider =
    FutureProvider.family<List<AvailabilityPriceRow>, PriceFilterParams>(
        (ref, params) async {
  final availability = await ref.watch(skuAvailabilityForWidgetProvider(
    WidgetFilterParams(missionId: params.missionId),
  ).future);
  if (availability.isEmpty) return [];

  final observations = await ref.watch(rawPriceObservationsProvider(
    PriceFilterParams(missionId: params.missionId),
  ).future);

  final pricesByName = <String, List<double>>{};
  final countsByName = <String, int>{};
  for (final obs in observations) {
    final key = _normalizedProductName(obs.productName);
    pricesByName.putIfAbsent(key, () => []).add(obs.price);
    countsByName[key] = (countsByName[key] ?? 0) + 1;
  }

  final avgByName = pricesByName.map((key, prices) =>
      MapEntry(key, prices.reduce((a, b) => a + b) / prices.length));

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
