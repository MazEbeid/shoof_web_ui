import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'cities_constants.dart';
import 'supabase_client_provider.dart';

/// Filter params for widget-specific queries.
/// Each dashboard widget manages its own filters and passes missionId directly.
class WidgetFilterParams {
  final String missionId;
  final String? company;
  final String? brand;
  final String? package;
  final String? size;
  final String? city;

  /// Region display name (see cities_constants.dart). Resolved to the
  /// mission's DB city values at query time — only the mission-overview
  /// providers honor it currently.
  final String? region;
  final String? channel;
  final DateTime? startDate;
  final DateTime? endDate;

  const WidgetFilterParams({
    required this.missionId,
    this.company,
    this.brand,
    this.package,
    this.size,
    this.city,
    this.region,
    this.channel,
    this.startDate,
    this.endDate,
  });

  /// Check if any filters are active (besides missionId)
  bool get hasFilters =>
      company != null ||
      brand != null ||
      package != null ||
      size != null ||
      city != null ||
      region != null ||
      channel != null ||
      startDate != null ||
      endDate != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetFilterParams &&
          missionId == other.missionId &&
          company == other.company &&
          brand == other.brand &&
          package == other.package &&
          size == other.size &&
          city == other.city &&
          region == other.region &&
          channel == other.channel &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(missionId, company, brand, package, size,
      city, region, channel, startDate, endDate);
}

/// Cities for a mission (for filter dropdowns)
final missionCitiesProvider =
    FutureProvider.family<List<String>, String>((ref, missionId) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  try {
    final response = await supabase
        .from('v_mission_cities')
        .select('city')
        .eq('mission_id', missionId);

    return (response as List).map((e) => e['city'] as String).toList();
  } catch (e) {
    return [];
  }
});

/// Channels for a mission (for filter dropdowns)
final missionChannelsProvider =
    FutureProvider.family<List<String>, String>((ref, missionId) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  try {
    final response = await supabase
        .from('v_mission_channels')
        .select('channel')
        .eq('mission_id', missionId);

    return (response as List).map((e) => e['channel'] as String).toList();
  } catch (e) {
    return [];
  }
});

/// SKU availability data model (for table view)
class SkuAvailability {
  final String skuEnglish;
  final String brand;
  final String company;
  final String package;
  final String size;
  final int totalChecks;
  final int availableCount;
  final double availabilityRate;

  const SkuAvailability({
    required this.skuEnglish,
    required this.brand,
    required this.company,
    required this.package,
    required this.size,
    required this.totalChecks,
    required this.availableCount,
    required this.availabilityRate,
  });

  factory SkuAvailability.fromMap(Map<String, dynamic> map) {
    return SkuAvailability(
      skuEnglish: map['sku_english'] ?? 'Unknown',
      brand: map['brand'] ?? '',
      company: map['company'] ?? '',
      package: map['package'] ?? '',
      size: map['size'] ?? '',
      totalChecks: map['total_checks'] ?? 0,
      availableCount: map['available_count'] ?? 0,
      availabilityRate: (map['availability_rate'] ?? 0).toDouble(),
    );
  }
}

/// SKU availability with widget-local filters.
///
/// Always served by RPC fn_sku_availability_filtered (nulls = unfiltered):
/// one code path, all filters applied server-side, STORE-level semantics
/// (each store counted once, its latest visit decides). Errors are rethrown
/// so widgets show an error state instead of quietly-wrong numbers.
final skuAvailabilityForWidgetProvider =
    FutureProvider.family<List<SkuAvailability>, WidgetFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  final rpcResponse =
      await supabase.rpc('fn_sku_availability_filtered', params: {
    'p_mission_id': params.missionId,
    'p_city': params.city,
    'p_channel': params.channel,
    'p_start_date': params.startDate?.toIso8601String().split('T')[0],
    'p_end_date': params.endDate?.toIso8601String().split('T')[0],
    'p_company': params.company,
    'p_brand': params.brand,
    'p_package': params.package,
    'p_size': params.size,
  });

  return (rpcResponse as List)
      .map((e) => SkuAvailability.fromMap(e))
      .toList();
});

/// One cell of the SKU x Channel availability matrix.
class SkuChannelAvailability {
  final String skuEnglish;
  final String channel;
  final int totalChecks;
  final int availableCount;

  const SkuChannelAvailability({
    required this.skuEnglish,
    required this.channel,
    required this.totalChecks,
    required this.availableCount,
  });

  double get availabilityRate =>
      totalChecks == 0 ? 0 : availableCount / totalChecks * 100;
}

/// Availability broken out by SKU AND channel (both dimensions).
///
/// Always served by RPC fn_sku_channel_availability (nulls = unfiltered) with
/// STORE-level semantics (each store counted once, latest visit decides).
/// Errors are rethrown so widgets show an error state instead of
/// quietly-wrong numbers.
final skuChannelAvailabilityForWidgetProvider =
    FutureProvider.family<List<SkuChannelAvailability>, WidgetFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  final rpcResponse =
      await supabase.rpc('fn_sku_channel_availability', params: {
    'p_mission_id': params.missionId,
    'p_city': params.city,
    'p_channel': params.channel,
    'p_start_date': params.startDate?.toIso8601String().split('T')[0],
    'p_end_date': params.endDate?.toIso8601String().split('T')[0],
    'p_company': params.company,
    'p_brand': params.brand,
    'p_package': params.package,
    'p_size': params.size,
  });

  return (rpcResponse as List)
      .map((e) => SkuChannelAvailability(
            skuEnglish: e['sku_english'] ?? 'Unknown',
            channel: e['channel'] ?? 'Unknown',
            totalChecks: (e['total_checks'] as num?)?.toInt() ?? 0,
            availableCount: (e['available_count'] as num?)?.toInt() ?? 0,
          ))
      .toList();
});

/// Distinct SKU dimensions (company/brand/package/size) for filter dropdowns.
class SkuDimensions {
  final List<String> companies;
  final List<String> brands;
  final List<String> packages;
  final List<String> sizes;

  const SkuDimensions({
    this.companies = const [],
    this.brands = const [],
    this.packages = const [],
    this.sizes = const [],
  });
}

final skuDimensionsProvider =
    FutureProvider.family<SkuDimensions, String>((ref, missionId) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  try {
    final response = await supabase
        .rpc('fn_availability_dimensions', params: {'p_mission_id': missionId});

    final companies = <String>[];
    final brands = <String>[];
    final packages = <String>[];
    final sizes = <String>[];
    for (final row in (response as List)) {
      final value = row['value'] as String?;
      if (value == null || value.isEmpty) continue;
      switch (row['dimension'] as String?) {
        case 'company':
          companies.add(value);
        case 'brand':
          brands.add(value);
        case 'package':
          packages.add(value);
        case 'size':
          sizes.add(value);
      }
    }
    return SkuDimensions(
      companies: companies,
      brands: brands,
      packages: packages,
      sizes: sizes,
    );
  } catch (e) {
    // Dropdowns simply stay hidden when the RPC isn't deployed.
    return const SkuDimensions();
  }
});

/// Chart data point for pie/bar charts
class ChartDataPoint {
  final String label;
  final double value;

  const ChartDataPoint({required this.label, required this.value});
}

/// Mission overview data model
class MissionOverviewData {
  final String clientId;
  final String missionId;
  final int totalSubmissions;
  final int totalAnswers;
  final int citiesCount;
  final int locationTypesCount;
  final int collectorsCount;
  final DateTime? firstSubmission;
  final DateTime? lastSubmission;

  const MissionOverviewData({
    required this.clientId,
    required this.missionId,
    required this.totalSubmissions,
    required this.totalAnswers,
    required this.citiesCount,
    required this.locationTypesCount,
    required this.collectorsCount,
    this.firstSubmission,
    this.lastSubmission,
  });

  factory MissionOverviewData.fromMap(Map<String, dynamic> map) {
    return MissionOverviewData(
      clientId: map['client_id'] ?? '',
      missionId: map['mission_id'] ?? '',
      totalSubmissions: map['total_submissions'] ?? 0,
      totalAnswers: map['total_answers'] ?? 0,
      citiesCount: map['cities_count'] ?? 0,
      locationTypesCount: map['location_types_count'] ?? 0,
      collectorsCount: map['collectors_count'] ?? 0,
      firstSubmission: map['first_submission'] != null
          ? DateTime.tryParse(map['first_submission'])
          : null,
      lastSubmission: map['last_submission'] != null
          ? DateTime.tryParse(map['last_submission'])
          : null,
    );
  }
}

/// Mission overview provider - accepts WidgetFilterParams for filtering.
///
/// No filters -> live view v_mission_overview; filtered -> RPC
/// fn_mission_overview_filtered. Errors (e.g. statement timeouts) are
/// rethrown so the widget shows an error state instead of silent "no data".
/// Resolves [WidgetFilterParams.region] to the mission's DB city values
/// (null when no region filter is active).
Future<List<String>?> citiesForRegionFilter(
    Ref ref, WidgetFilterParams params) async {
  if (params.region == null) return null;
  final cities =
      await ref.watch(missionCitiesProvider(params.missionId).future);
  return citiesForRegion(params.region!, cities);
}

final missionOverviewForWidgetProvider =
    FutureProvider.family<MissionOverviewData?, WidgetFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  if (!params.hasFilters) {
    final response = await supabase
        .from('v_mission_overview')
        .select()
        .eq('mission_id', params.missionId)
        .maybeSingle();

    if (response == null) return null;
    return MissionOverviewData.fromMap(response);
  }

  final regionCities = await citiesForRegionFilter(ref, params);
  final rpcResponse =
      await supabase.rpc('fn_mission_overview_filtered', params: {
    'p_mission_id': params.missionId,
    'p_city': params.city,
    'p_channel': params.channel,
    'p_start_date': params.startDate?.toIso8601String().split('T')[0],
    'p_end_date': params.endDate?.toIso8601String().split('T')[0],
    'p_cities': regionCities,
  });

  if (rpcResponse == null || (rpcResponse as List).isEmpty) return null;
  final row = rpcResponse[0];
  return MissionOverviewData(
    clientId: '',
    missionId: params.missionId,
    totalSubmissions: row['total_submissions'] ?? 0,
    totalAnswers: row['total_answers'] ?? 0,
    citiesCount: row['cities_count'] ?? 0,
    locationTypesCount: row['location_types_count'] ?? 0,
    collectorsCount: row['collectors_count'] ?? 0,
  );
});

/// City breakdown for a mission - accepts WidgetFilterParams for filtering
final cityBreakdownForWidgetProvider =
    FutureProvider.family<List<ChartDataPoint>, WidgetFilterParams>(
        (ref, params) async {
final supabase = ref.watch(sharedSupabaseProvider);

  if (!params.hasFilters) {
    final response = await supabase
        .from('v_city_breakdown')
        .select('city, submission_count')
        .eq('mission_id', params.missionId);

    final data = response as List;
    return data
        .map((row) => ChartDataPoint(
              label: row['city'] as String,
              value: (row['submission_count'] as int).toDouble(),
            ))
        .toList();
  }

  // Server-side aggregation: PostgREST caps responses at 1,000 rows, so
  // client-side counting over raw answer rows silently undercounts.
  final regionCities = await citiesForRegionFilter(ref, params);
  final rpcResponse =
      await supabase.rpc('fn_city_breakdown_filtered', params: {
    'p_mission_id': params.missionId,
    'p_city': params.city,
    'p_cities': regionCities,
    'p_channel': params.channel,
    'p_start_date': params.startDate?.toIso8601String().split('T')[0],
    'p_end_date': params.endDate?.toIso8601String().split('T')[0],
  });

  return (rpcResponse as List)
      .map((row) => ChartDataPoint(
            label: row['city'] as String,
            value: ((row['submission_count'] ?? 0) as num).toDouble(),
          ))
      .toList();
});

/// Channel breakdown for a mission - accepts WidgetFilterParams for filtering
final channelBreakdownForWidgetProvider =
    FutureProvider.family<List<ChartDataPoint>, WidgetFilterParams>(
        (ref, params) async {
final supabase = ref.watch(sharedSupabaseProvider);

  if (!params.hasFilters) {
    final response = await supabase
        .from('v_channel_breakdown')
        .select('channel, submission_count')
        .eq('mission_id', params.missionId);

    final data = response as List;
    return data
        .map((row) => ChartDataPoint(
              label: row['channel'] as String,
              value: (row['submission_count'] as int).toDouble(),
            ))
        .toList();
  }

  // Server-side aggregation: PostgREST caps responses at 1,000 rows, so
  // client-side counting over raw answer rows silently undercounts.
  final regionCities = await citiesForRegionFilter(ref, params);
  final rpcResponse =
      await supabase.rpc('fn_channel_breakdown_filtered', params: {
    'p_mission_id': params.missionId,
    'p_city': params.city,
    'p_cities': regionCities,
    'p_channel': params.channel,
    'p_start_date': params.startDate?.toIso8601String().split('T')[0],
    'p_end_date': params.endDate?.toIso8601String().split('T')[0],
  });

  return (rpcResponse as List)
      .map((row) => ChartDataPoint(
            label: row['channel'] as String,
            value: ((row['submission_count'] ?? 0) as num).toDouble(),
          ))
      .toList();
});

/// City values that fail the CITIES region lookup, with their visit counts.
/// Feeds the "Unknown region" drill-in so unmapped data is diagnosed (which
/// spellings/districts need aliases in cities_constants) instead of hidden.
final unmappedCitiesProvider =
    FutureProvider.family<List<ChartDataPoint>, WidgetFilterParams>(
        (ref, params) async {
  final cities =
      await ref.watch(cityBreakdownForWidgetProvider(params).future);
  return cities.where((c) => cityInfoFor(c.label) == null).toList();
});
