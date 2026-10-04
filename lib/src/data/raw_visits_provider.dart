import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'supabase_client_provider.dart';
import 'widget_data_providers.dart';

/// One SKU line of a visit's availability/price matrix.
class RawVisitSku {
  final String sku;
  final String? brand;
  final String? company;
  final String? package;
  final String? size;
  final bool? available;
  final double? price;

  const RawVisitSku({
    required this.sku,
    this.brand,
    this.company,
    this.package,
    this.size,
    this.available,
    this.price,
  });

  factory RawVisitSku.fromMap(Map<String, dynamic> map) => RawVisitSku(
        sku: map['sku'] as String? ?? 'Unknown',
        brand: map['brand'] as String?,
        company: map['company'] as String?,
        package: map['package'] as String?,
        size: map['size'] as String?,
        available: map['available'] as bool?,
        price: (map['price'] as num?)?.toDouble(),
      );
}

/// One accepted visit (fn_raw_visits row).
class RawVisitRow {
  final String submissionId;
  final DateTime? observedAt;
  final String? observedDate;
  final String? locationName;
  final String? googleMapsLink;
  final String? city;
  final String? districtName;
  final String? channel;
  final String? placeType;
  final String? crowdId;
  final List<RawVisitSku> skus;
  final List<String> photos;
  final String? recordingUrl;
  final int totalCount;

  const RawVisitRow({
    required this.submissionId,
    this.observedAt,
    this.observedDate,
    this.locationName,
    this.googleMapsLink,
    this.city,
    this.districtName,
    this.channel,
    this.placeType,
    this.crowdId,
    required this.skus,
    required this.photos,
    this.recordingUrl,
    required this.totalCount,
  });

  int get availableCount =>
      skus.where((s) => s.available == true).length;

  factory RawVisitRow.fromMap(Map<String, dynamic> map) => RawVisitRow(
        submissionId: map['submission_id'] as String? ?? '',
        observedAt: map['observed_at'] != null
            ? DateTime.tryParse(map['observed_at'].toString())
            : null,
        observedDate: map['observed_date']?.toString(),
        locationName: map['location_name'] as String?,
        googleMapsLink: map['google_maps_link'] as String?,
        city: map['city'] as String?,
        districtName: map['district_name'] as String?,
        channel: map['channel'] as String?,
        placeType: map['place_type'] as String?,
        crowdId: map['crowd_id'] as String?,
        skus: (map['skus'] as List? ?? const [])
            .map((e) => RawVisitSku.fromMap(e as Map<String, dynamic>))
            .toList(),
        photos: (map['photos'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        recordingUrl: map['recording_url'] as String?,
        totalCount: (map['total_count'] as num?)?.toInt() ?? 0,
      );
}

/// Params for one Raw Data page: the shared widget filters + the widget's
/// own availability/price-range filters + pagination.
class RawVisitsParams {
  final WidgetFilterParams filters;
  final bool? available;
  final double? priceMin;
  final double? priceMax;
  final int limit;
  final int offset;

  const RawVisitsParams({
    required this.filters,
    this.available,
    this.priceMin,
    this.priceMax,
    this.limit = 25,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RawVisitsParams &&
          filters == other.filters &&
          available == other.available &&
          priceMin == other.priceMin &&
          priceMax == other.priceMax &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode =>
      Object.hash(filters, available, priceMin, priceMax, limit, offset);
}

/// One page of accepted visits, RPC-always (errors rethrow by design).
final rawVisitsProvider =
    FutureProvider.family<List<RawVisitRow>, RawVisitsParams>(
        (ref, params) async {
  final supabase = ref.watch(sharedSupabaseProvider);
  final f = params.filters;
  final regionCities = await citiesForRegionFilter(ref, f);

  final rpcResponse = await supabase.rpc('fn_raw_visits', params: {
    'p_mission_id': f.missionId,
    'p_city': f.city,
    'p_cities': regionCities,
    'p_channel': f.channel,
    'p_company': f.company,
    'p_brand': f.brand,
    'p_package': f.package,
    'p_size': f.size,
    'p_start_date': f.startDate?.toIso8601String().split('T')[0],
    'p_end_date': f.endDate?.toIso8601String().split('T')[0],
    'p_available': params.available,
    'p_price_min': params.priceMin,
    'p_price_max': params.priceMax,
    'p_limit': params.limit,
    'p_offset': params.offset,
  });

  return (rpcResponse as List)
      .map((e) => RawVisitRow.fromMap(e as Map<String, dynamic>))
      .toList();
});
