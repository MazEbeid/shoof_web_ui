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
/// Strategy:
/// 1. Try RPC fn_sku_channel_availability (see supabase_dashboard_views.sql)
/// 2. Fall back to client-side aggregation over the sku_availability table -
///    the same source v_availability_by_sku (the "By SKU" list) is built from.
///    SKU names are upper/trimmed to match that matview's normalization.
final skuChannelAvailabilityForWidgetProvider =
    FutureProvider.family<List<SkuChannelAvailability>, WidgetFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  try {
    try {
      final rpcResponse =
          await supabase.rpc('fn_sku_channel_availability', params: {
        'p_mission_id': params.missionId,
        'p_city': params.city,
        'p_channel': params.channel,
        'p_start_date': params.startDate?.toIso8601String().split('T')[0],
        'p_end_date': params.endDate?.toIso8601String().split('T')[0],
      });

      final rows = (rpcResponse as List)
          .map((e) => SkuChannelAvailability(
                skuEnglish: e['sku_english'] ?? 'Unknown',
                channel: e['channel'] ?? 'Unknown',
                totalChecks: (e['total_checks'] as num?)?.toInt() ?? 0,
                availableCount: (e['available_count'] as num?)?.toInt() ?? 0,
              ))
          .toList();
      if (rows.isNotEmpty) return rows;
      // Empty could mean the deployed function predates the sku_availability
      // rewrite - let the fallback decide.
    } catch (rpcError) {
      // Function not deployed yet - fall back to client-side aggregation
    }

    var query = supabase
        .from('sku_availability')
        .select('sku_english, channel, available')
        .eq('mission_id', params.missionId)
        .not('sku_english', 'is', null)
        .not('channel', 'is', null);

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

    final response = await query.limit(100000);
    final data = response as List;

    // sku -> channel -> [totalChecks, availableCount]
    final matrix = <String, Map<String, List<int>>>{};
    for (final row in data) {
      final sku = (row['sku_english'] as String?)?.trim().toUpperCase();
      final channel = (row['channel'] as String?)?.trim();
      if (sku == null || sku.isEmpty || channel == null || channel.isEmpty) {
        continue;
      }
      final cell = matrix
          .putIfAbsent(sku, () => {})
          .putIfAbsent(channel, () => [0, 0]);
      cell[0]++;
      if (row['available'] == true) cell[1]++;
    }

    return [
      for (final skuEntry in matrix.entries)
        for (final channelEntry in skuEntry.value.entries)
          SkuChannelAvailability(
            skuEnglish: skuEntry.key,
            channel: channelEntry.key,
            totalChecks: channelEntry.value[0],
            availableCount: channelEntry.value[1],
          ),
    ];
  } catch (e) {
    return [];
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

/// Mission overview provider - accepts WidgetFilterParams for filtering
///
/// Strategy:
/// 1. No filters: use fast aggregate view v_mission_overview
/// 2. With filters: try RPC fn_mission_overview_filtered, fall back to
///    client-side aggregation
final missionOverviewForWidgetProvider =
    FutureProvider.family<MissionOverviewData?, WidgetFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  try {
    if (!params.hasFilters) {
      final response = await supabase
          .from('v_mission_overview')
          .select()
          .eq('mission_id', params.missionId)
          .maybeSingle();

      if (response == null) return null;
      return MissionOverviewData.fromMap(response);
    }

    try {
      final rpcResponse =
          await supabase.rpc('fn_mission_overview_filtered', params: {
        'p_mission_id': params.missionId,
        'p_city': params.city,
        'p_channel': params.channel,
        'p_start_date': params.startDate?.toIso8601String().split('T')[0],
        'p_end_date': params.endDate?.toIso8601String().split('T')[0],
      });

      if (rpcResponse != null && (rpcResponse as List).isNotEmpty) {
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
      }
    } catch (rpcError) {
      // Function not deployed - fall back to client-side aggregation
    }

    var query = supabase
        .from('submission_answers')
        .select('submission_id, city, channel, crowd_id')
        .eq('mission_id', params.missionId)
        .eq('qa_status', 'accepted');

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

    final response = await query;
    final data = response as List;

    final submissions = data.map((e) => e['submission_id']).toSet();
    final cities = data.map((e) => e['city']).whereType<String>().toSet();
    final channels = data.map((e) => e['channel']).whereType<String>().toSet();
    final collectors = data.map((e) => e['crowd_id']).whereType<String>().toSet();

    return MissionOverviewData(
      clientId: '',
      missionId: params.missionId,
      totalSubmissions: submissions.length,
      totalAnswers: data.length,
      citiesCount: cities.length,
      locationTypesCount: channels.length,
      collectorsCount: collectors.length,
    );
  } catch (e) {
    return null;
  }
});

/// City breakdown for a mission - accepts WidgetFilterParams for filtering
final cityBreakdownForWidgetProvider =
    FutureProvider.family<List<ChartDataPoint>, WidgetFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  try {
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

    var query = supabase
        .from('submission_answers')
        .select('submission_id, city')
        .eq('mission_id', params.missionId)
        .eq('qa_status', 'accepted')
        .not('city', 'is', null);

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

    final response = await query;
    final data = response as List;

    // Group by city and count unique submissions
    final cityMap = <String, Set<String>>{};
    for (final row in data) {
      final city = row['city'] as String?;
      final submissionId = row['submission_id'] as String?;
      if (city != null && submissionId != null) {
        cityMap.putIfAbsent(city, () => {}).add(submissionId);
      }
    }

    return cityMap.entries
        .map((e) =>
            ChartDataPoint(label: e.key, value: e.value.length.toDouble()))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  } catch (e) {
    return [];
  }
});

/// Channel breakdown for a mission - accepts WidgetFilterParams for filtering
final channelBreakdownForWidgetProvider =
    FutureProvider.family<List<ChartDataPoint>, WidgetFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  try {
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

    var query = supabase
        .from('submission_answers')
        .select('submission_id, channel')
        .eq('mission_id', params.missionId)
        .eq('qa_status', 'accepted')
        .not('channel', 'is', null);

    if (params.city != null) {
      query = query.eq('city', params.city!);
    }
    if (params.startDate != null) {
      query = query.gte(
          'observed_date', params.startDate!.toIso8601String().split('T')[0]);
    }
    if (params.endDate != null) {
      query = query.lte(
          'observed_date', params.endDate!.toIso8601String().split('T')[0]);
    }

    final response = await query;
    final data = response as List;

    // Group by channel and count unique submissions
    final channelMap = <String, Set<String>>{};
    for (final row in data) {
      final channel = row['channel'] as String?;
      final submissionId = row['submission_id'] as String?;
      if (channel != null && submissionId != null) {
        channelMap.putIfAbsent(channel, () => {}).add(submissionId);
      }
    }

    return channelMap.entries
        .map((e) =>
            ChartDataPoint(label: e.key, value: e.value.length.toDouble()))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  } catch (e) {
    return [];
  }
});
