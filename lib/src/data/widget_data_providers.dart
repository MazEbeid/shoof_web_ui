import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'supabase_client_provider.dart';

/// Filter params for widget-specific queries.
/// Each dashboard widget manages its own filters and passes missionId directly.
class WidgetFilterParams {
  final String missionId;
  final String? company;
  final String? city;
  final String? channel;
  final DateTime? startDate;
  final DateTime? endDate;

  const WidgetFilterParams({
    required this.missionId,
    this.company,
    this.city,
    this.channel,
    this.startDate,
    this.endDate,
  });

  /// Check if any filters are active (besides missionId)
  bool get hasFilters =>
      company != null ||
      city != null ||
      channel != null ||
      startDate != null ||
      endDate != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetFilterParams &&
          missionId == other.missionId &&
          company == other.company &&
          city == other.city &&
          channel == other.channel &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      Object.hash(missionId, company, city, channel, startDate, endDate);
}

/// Location data point for the coverage map (one per accepted visit).
class LocationPoint {
  final String submissionId;
  final double lat;
  final double lng;
  final String? city;
  final String? district;
  final String? placeType;
  final String? locationName;

  LocationPoint({
    required this.submissionId,
    required this.lat,
    required this.lng,
    this.city,
    this.district,
    this.placeType,
    this.locationName,
  });
}

/// Map locations for a mission with widget-local filters.
/// Deduplicated by submission_id, so each point is one accepted visit.
final mapLocationsForWidgetProvider =
    FutureProvider.family<List<LocationPoint>, WidgetFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  try {
    var query = supabase
        .from('submission_answers')
        .select(
            'submission_id, lat, lng, city, district_name, channel, location_name')
        .eq('mission_id', params.missionId)
        .eq('qa_status', 'accepted')
        .not('lat', 'is', null)
        .not('lng', 'is', null);

    if (params.city != null) {
      query = query.eq('city', params.city!);
    }
    if (params.channel != null) {
      query = query.eq('channel', params.channel!);
    }
    if (params.startDate != null) {
      query = query.gte(
          'observed_date', params.startDate!.toIso8601String().split('T')[0]);
    }
    if (params.endDate != null) {
      query = query.lte(
          'observed_date', params.endDate!.toIso8601String().split('T')[0]);
    }

    final response = await query.limit(50000);
    final data = response as List;

    final seenSubmissions = <String>{};
    final locations = <LocationPoint>[];

    for (final row in data) {
      final submissionId = row['submission_id'] as String?;
      if (submissionId == null || seenSubmissions.contains(submissionId)) {
        continue;
      }

      final lat = row['lat'];
      final lng = row['lng'];
      if (lat == null || lng == null) continue;

      seenSubmissions.add(submissionId);
      locations.add(LocationPoint(
        submissionId: submissionId,
        lat: (lat as num).toDouble(),
        lng: (lng as num).toDouble(),
        city: row['city'] as String?,
        district: row['district_name'] as String?,
        placeType: row['channel'] as String?,
        locationName: row['location_name'] as String?,
      ));
    }

    return locations;
  } catch (e) {
    return [];
  }
});

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

/// SKU availability provider with widget-local filters
///
/// Strategy:
/// 1. If filters applied, try Postgres function fn_sku_availability_filtered (if deployed)
/// 2. Fall back to aggregate view v_availability_by_sku (no filter support)
final skuAvailabilityForWidgetProvider =
    FutureProvider.family<List<SkuAvailability>, WidgetFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  final hasCityChannelDateFilters = params.city != null ||
      params.channel != null ||
      params.startDate != null ||
      params.endDate != null;

  try {
    if (hasCityChannelDateFilters) {
      try {
        final rpcResponse =
            await supabase.rpc('fn_sku_availability_filtered', params: {
          'p_mission_id': params.missionId,
          'p_city': params.city,
          'p_channel': params.channel,
          'p_start_date': params.startDate?.toIso8601String().split('T')[0],
          'p_end_date': params.endDate?.toIso8601String().split('T')[0],
        });

        final data = rpcResponse as List;
        return data.map((e) => SkuAvailability.fromMap(e)).toList();
      } catch (rpcError) {
        // Function doesn't exist yet - fall back to aggregate view
      }
    }

    final query = supabase
        .from('v_availability_by_sku')
        .select()
        .eq('mission_id', params.missionId);

    final response = await query.order('availability_rate', ascending: false);

    return response.map((e) => SkuAvailability.fromMap(e)).toList();
  } catch (e) {
    return [];
  }
});
