import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../widgets/dashboard/export_button.dart';
import 'postgrest_paging.dart';
import 'supabase_client_provider.dart';
import 'widget_data_providers.dart';

// =============================================================================
// MISSED OPPORTUNITIES — shared data layer
//
// Backs the Missed Opportunities / Cross-Sell / New Business widgets in BOTH
// ShooofAdmin (builder) and shoof_insights (client viewer). Everything here
// is RLS-scoped end-to-end (fn_missed_opps_by_sku_filtered + the
// security_invoker v_missed_opps_export view over the client-scoped caches),
// so a client token only ever sees its own rows.
// =============================================================================

/// Missed opportunity by SKU data model
class MissedOpportunitySku {
  final String sku;
  final String brand;
  final String company;
  final String size;
  final String package;
  final String category;
  final int missedCount;
  final int warmStoreCount;
  final int coldStoreCount;
  final int competitorsPresent;
  final String competitorBrands;
  final double avgCompanySkusWhenWarm;

  const MissedOpportunitySku({
    required this.sku,
    required this.brand,
    required this.company,
    required this.size,
    required this.package,
    required this.category,
    required this.missedCount,
    required this.warmStoreCount,
    required this.coldStoreCount,
    required this.competitorsPresent,
    required this.competitorBrands,
    required this.avgCompanySkusWhenWarm,
  });

  factory MissedOpportunitySku.fromMap(Map<String, dynamic> map) {
    return MissedOpportunitySku(
      sku: map['sku'] ?? 'Unknown',
      brand: map['brand'] ?? '',
      company: map['company'] ?? '',
      size: map['size'] ?? '',
      package: map['package'] ?? '',
      category: map['category'] ?? 'Unknown',
      missedCount: map['missed_count'] ?? 0,
      warmStoreCount: map['warm_store_count'] ?? 0,
      coldStoreCount: map['cold_store_count'] ?? 0,
      competitorsPresent: map['competitors_present'] ?? 0,
      competitorBrands: map['competitor_skus'] ?? '',
      avgCompanySkusWhenWarm:
          (map['avg_company_skus_when_warm'] ?? 0).toDouble(),
    );
  }
}

/// Export row for missed opportunities
class MissedOpportunityExport {
  final String submissionId;
  final String sku;
  final String brand;
  final String company;
  final String size;
  final String package;
  final String storeType;
  final int yourSkusAtStore;
  final String? city;
  final String? district;
  final String? channel;
  final String? locationName;
  final String? observedDate;
  final double? lat;
  final double? lng;
  final String? googleMapsLink;

  const MissedOpportunityExport({
    required this.submissionId,
    required this.sku,
    required this.brand,
    required this.company,
    required this.size,
    required this.package,
    required this.storeType,
    required this.yourSkusAtStore,
    this.city,
    this.district,
    this.channel,
    this.locationName,
    this.observedDate,
    this.lat,
    this.lng,
    this.googleMapsLink,
  });

  factory MissedOpportunityExport.fromMap(Map<String, dynamic> map) {
    return MissedOpportunityExport(
      submissionId: map['submission_id'] ?? '',
      sku: map['sku'] ?? '',
      brand: map['brand'] ?? '',
      company: map['company'] ?? '',
      size: map['size'] ?? '',
      package: map['package'] ?? '',
      storeType: map['store_type'] ?? 'Unknown',
      yourSkusAtStore: map['your_skus_at_store'] ?? 0,
      city: map['city'],
      district: map['district_name'],
      channel: map['channel'],
      locationName: map['location_name'],
      observedDate: map['observed_date'],
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
      googleMapsLink: map['google_maps_link'],
    );
  }
}

/// Missed SKUs provider with widget-local filters.
///
/// Always served by RPC fn_missed_opps_by_sku_filtered (nulls = unfiltered):
/// STORE-level semantics - a store counts as a missed opportunity only if the
/// SKU was absent on its MOST RECENT visit, and each store counts once no
/// matter how many times it was visited. Errors are rethrown so the widget
/// shows an error state instead of quietly-wrong numbers.
final missedSkusForWidgetProvider =
    FutureProvider.family<List<MissedOpportunitySku>, WidgetFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  final regionCities = await citiesForRegionFilter(ref, params);
  final rpcResponse =
      await supabase.rpc('fn_missed_opps_by_sku_filtered', params: {
    'p_mission_id': params.missionId,
    'p_company': params.company,
    'p_city': params.city,
    'p_channel': params.channel,
    'p_start_date': params.startDate?.toIso8601String().split('T')[0],
    'p_end_date': params.endDate?.toIso8601String().split('T')[0],
    'p_brand': params.brand,
    'p_package': params.package,
    'p_size': params.size,
    'p_cities': regionCities,
  });

  return (rpcResponse as List)
      .map((e) => MissedOpportunitySku(
            sku: e['sku'] ?? '',
            brand: e['brand'] ?? '',
            company: e['company'] ?? '',
            size: e['size'] ?? '',
            package: e['package'] ?? '',
            category: e['category'] ?? '',
            missedCount:
                (e['missed_count'] is num) ? (e['missed_count'] as num).toInt() : 0,
            warmStoreCount: (e['warm_store_count'] is num)
                ? (e['warm_store_count'] as num).toInt()
                : 0,
            coldStoreCount: (e['cold_store_count'] is num)
                ? (e['cold_store_count'] as num).toInt()
                : 0,
            competitorsPresent: (e['competitors_present'] is num)
                ? (e['competitors_present'] as num).toInt()
                : 0,
            competitorBrands: e['competitor_skus'] ?? e['competitor_brands'] ?? '',
            avgCompanySkusWhenWarm: (e['avg_company_skus_when_warm'] is num)
                ? (e['avg_company_skus_when_warm'] as num).toDouble()
                : 0.0,
          ))
      .toList();
});

/// Export data provider with widget-local filters
final missedOppsExportForWidgetProvider =
    FutureProvider.family<List<MissedOpportunityExport>, WidgetFilterParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);

  try {
    final regionCities = await citiesForRegionFilter(ref, params);

    // Paged fetch: PostgREST caps every response at 1,000 rows regardless
    // of .limit() — this view runs to ~93K rows per mission. Stable order
    // is required so pages never overlap.
    final response = await fetchAllPages((from, to) {
      var query = supabase
          .from('v_missed_opps_export')
          .select()
          .eq('mission_id', params.missionId);

      if (params.company != null) {
        query = query.eq('company', params.company!);
      }
      if (params.city != null) {
        query = query.eq('city', params.city!);
      }
      // Region resolves to the mission's city values (New Business region mode)
      if (regionCities != null) {
        query = query.inFilter('city', regionCities);
      }
      if (params.channel != null) {
        query = query.eq('channel', params.channel!);
      }
      // SKU-dimension filters: dropdown values are canonical UPPERCASE while
      // the view stores raw casing, so match case-insensitively.
      if (params.brand != null) {
        query = query.ilike('brand', params.brand!);
      }
      if (params.package != null) {
        query = query.ilike('package', params.package!);
      }
      if (params.size != null) {
        query = query.ilike('size', params.size!);
      }
      if (params.startDate != null) {
        query = query.gte('observed_date',
            params.startDate!.toIso8601String().split('T')[0]);
      }
      if (params.endDate != null) {
        query = query.lte('observed_date',
            params.endDate!.toIso8601String().split('T')[0]);
      }

      return query
          .order('submission_id', ascending: true)
          .order('sku', ascending: true)
          .order('size', ascending: true)
          .range(from, to);
    });

    return response.map((e) => MissedOpportunityExport.fromMap(e)).toList();
  } catch (e) {
    print('Error fetching export data: $e');
    return [];
  }
});

/// Store-level CSV for the opportunity widgets' Export buttons
/// (missed opps = all rows, cross-sell = Warm only, new business = Cold only).
CsvExportData missedOppsCsv(List<MissedOpportunityExport> rows,
    {String? storeType}) {
  final filtered = storeType == null
      ? rows
      : rows.where((r) => r.storeType == storeType).toList();
  return CsvExportData(
    header: const [
      'SKU', 'Brand', 'Company', 'Size', 'Package', 'Store Type',
      'Your SKUs at Store', 'City', 'District', 'Channel', 'Location Name',
      'Date', 'Lat', 'Lng', 'Google Maps Link',
    ],
    rows: filtered
        .map((r) => <Object?>[
              r.sku, r.brand, r.company, r.size, r.package, r.storeType,
              r.yourSkusAtStore, r.city, r.district, r.channel,
              r.locationName, r.observedDate, r.lat, r.lng, r.googleMapsLink,
            ])
        .toList(),
  );
}
