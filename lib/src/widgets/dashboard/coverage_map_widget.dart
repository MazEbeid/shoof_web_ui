import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'export_button.dart';
import 'sku_filter_bar.dart';
import '../../data/cities_constants.dart';
import '../../data/widget_data_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// Coverage Map Widget - per-city visit bubbles on an OpenStreetMap base.
///
/// Metric: VISITS (one per accepted submission) - every visit counts,
/// revisited stores are not collapsed. Counts come from the city breakdown
/// (ALL visits, including ones without GPS coordinates); the header badge is
/// the same visits total the Mission Overview shows. Bubbles sit on fixed
/// city centroids; cities missing from the CITIES lookup are summed into an
/// "unmapped" chip instead of being dropped.
class CoverageMapWidget extends HookConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;

  const CoverageMapWidget({
    super.key,
    required this.missionId,
    this.title = 'Coverage Map',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapController = useMemoized(MapController.new);

    final filters = useSkuFilters();
    final filterParams = filters.params(missionId);

    final citiesAsync = ref.watch(cityBreakdownForWidgetProvider(filterParams));
    final overviewAsync = ref.watch(missionOverviewForWidgetProvider(filterParams));

    return Container(
      height: AdminSpacing.widgetMedium,
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: AdminRadius.lgAll,
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map, color: AdminColors.primary, size: 24),
              const SizedBox(width: AdminSpacing.sm),
              Text(title, style: AdminTextStyles.sectionTitle),
              const Spacer(),
              ExportButton(
                baseName: 'coverage_by_city',
                buildData: () async {
                  final cities = await ref.read(
                      cityBreakdownForWidgetProvider(filterParams).future);
                  return CsvExportData(
                    header: const ['City', 'Region', 'Visits'],
                    rows: cities
                        .map((c) => <Object?>[
                              c.label,
                              regionForCity(c.label),
                              c.value.toInt(),
                            ])
                        .toList(),
                  );
                },
              ),
              const SizedBox(width: AdminSpacing.sm),
              // Total visits badge - same number the Mission Overview shows.
              overviewAsync.when(
                data: (overview) => overview == null
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AdminColors.primary.withValues(alpha: 0.1),
                          borderRadius: AdminRadius.smAll,
                        ),
                        child: Text(
                          '${_formatCount(overview.totalSubmissions)} visits',
                          style: AdminTextStyles.labelMedium.copyWith(
                            color: AdminColors.primary,
                          ),
                        ),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          SkuFilterBar(
            missionId: missionId,
            filters: filters,
            showSkuDims: false,
          ),
          const SizedBox(height: AdminSpacing.md),
          Expanded(
            child: ClipRRect(
              borderRadius: AdminRadius.mdAll,
              child: citiesAsync.when(
                data: (cities) => _MapContent(
                  cities: cities,
                  mapController: mapController,
                ),
                loading: () => const _LoadingMap(),
                error: (e, _) => _ErrorMap(message: e.toString()),
              ),
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.lg),
            Text(
              subtitle!,
              style: AdminTextStyles.labelSmall.copyWith(
                color: AdminColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toString();
  }
}

/// A city bubble: name, visit count, fixed centroid position.
class _CityBubble {
  final String name;
  final int count;
  final double lat;
  final double lng;

  const _CityBubble({
    required this.name,
    required this.count,
    required this.lat,
    required this.lng,
  });
}

class _MapContent extends StatelessWidget {
  final List<ChartDataPoint> cities;
  final MapController mapController;

  const _MapContent({
    required this.cities,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) {
      return const _EmptyMap();
    }

    // Map known cities to centroids; sum unmappable ones into a chip.
    final bubbles = <_CityBubble>[];
    var unmappedVisits = 0;
    final unmappedNames = <String>[];
    for (final city in cities) {
      final info = cityInfoFor(city.label);
      final lat = (info?['lat'] as num?)?.toDouble();
      final lng = (info?['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) {
        unmappedVisits += city.value.toInt();
        unmappedNames.add(city.label);
        continue;
      }
      bubbles.add(_CityBubble(
        name: (info?['english'] as String?) ?? city.label,
        count: city.value.toInt(),
        lat: lat,
        lng: lng,
      ));
    }

    if (bubbles.isEmpty) {
      return const _EmptyMap();
    }

    final centerLat =
        bubbles.map((b) => b.lat).reduce((a, b) => a + b) / bubbles.length;
    final centerLng =
        bubbles.map((b) => b.lng).reduce((a, b) => a + b) / bubbles.length;

    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: LatLng(centerLat, centerLng),
            initialZoom: 6,
            minZoom: 4,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.shoof.admin',
              tileProvider: CancellableNetworkTileProvider(),
            ),
            _CityBubbleLayer(bubbles: bubbles),
          ],
        ),
        if (unmappedVisits > 0)
          Positioned(
            left: AdminSpacing.sm,
            bottom: AdminSpacing.sm,
            child: Tooltip(
              message:
                  'City values without a map position: ${unmappedNames.join(', ')}',
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: AdminRadius.smAll,
                  border: Border.all(color: AdminColors.divider),
                ),
                child: Text(
                  'Unmapped cities: $unmappedVisits visits',
                  style: AdminTextStyles.labelSmall.copyWith(
                    color: AdminColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CityBubbleLayer extends StatelessWidget {
  final List<_CityBubble> bubbles;

  const _CityBubbleLayer({required this.bubbles});

  @override
  Widget build(BuildContext context) {
    final maxCount =
        bubbles.map((b) => b.count).reduce((a, b) => a > b ? a : b);

    return MarkerLayer(
      markers: bubbles.map((bubble) {
        final ratio = maxCount == 0 ? 0.0 : bubble.count / maxCount;
        final diameter = 44.0 + 52.0 * math.sqrt(ratio);
        // 4-step intensity: busier cities get a deeper fill
        final opacity = ratio > 0.75
            ? 0.95
            : ratio > 0.5
                ? 0.8
                : ratio > 0.25
                    ? 0.65
                    : 0.5;

        return Marker(
          point: LatLng(bubble.lat, bubble.lng),
          width: diameter < 90 ? 90 : diameter,
          height: diameter + 18,
          child: GestureDetector(
            onTap: () => _showCityInfo(context, bubble),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${bubble.count}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: diameter > 60 ? 16 : 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    bubble.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCityInfo(BuildContext context, _CityBubble bubble) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: Row(
          children: [
            Icon(Icons.location_city, color: AdminColors.primary),
            const SizedBox(width: 8),
            Text(bubble.name, style: AdminTextStyles.sectionTitle),
          ],
        ),
        content: Text(
          '${bubble.count} accepted ${bubble.count == 1 ? 'visit' : 'visits'} in this city',
          style: AdminTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _LoadingMap extends StatelessWidget {
  const _LoadingMap();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminColors.backgroundHover,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AdminColors.primary),
            const SizedBox(height: AdminSpacing.md),
            Text('Loading map...', style: AdminTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _EmptyMap extends StatelessWidget {
  const _EmptyMap();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminColors.backgroundHover,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 48, color: AdminColors.textMuted),
            const SizedBox(height: AdminSpacing.md),
            Text(
              'No visit data available',
              style: AdminTextStyles.bodyMedium
                  .copyWith(color: AdminColors.textMuted),
            ),
            const SizedBox(height: AdminSpacing.xs),
            Text(
              'Cities will appear when accepted visits are recorded',
              style: AdminTextStyles.bodySmall
                  .copyWith(color: AdminColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorMap extends StatelessWidget {
  final String message;

  const _ErrorMap({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminColors.backgroundHover,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AdminColors.error),
            const SizedBox(height: AdminSpacing.md),
            Text(
              'Error loading map',
              style: AdminTextStyles.bodyMedium
                  .copyWith(color: AdminColors.error),
            ),
            const SizedBox(height: AdminSpacing.xs),
            Text(
              message,
              style: AdminTextStyles.bodySmall
                  .copyWith(color: AdminColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
