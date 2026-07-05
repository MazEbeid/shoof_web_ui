import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'widget_filters_row.dart';
import '../../data/widget_data_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';
import '../../data/cities_constants.dart';

/// Coverage Map Widget with a per-city visit bubble view and a marker detail view
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
    final showBubbles = useState(true);
    final mapController = useMemoized(MapController.new);

    final selectedCity = useState<String?>(null);
    final selectedChannel = useState<String?>(null);
    final startDate = useState<DateTime?>(null);
    final endDate = useState<DateTime?>(null);

    final hasFilters = selectedCity.value != null ||
        selectedChannel.value != null ||
        startDate.value != null ||
        endDate.value != null;

    final filterParams = WidgetFilterParams(
      missionId: missionId,
      city: selectedCity.value,
      channel: selectedChannel.value,
      startDate: startDate.value,
      endDate: endDate.value,
    );

    final locationsAsync = ref.watch(mapLocationsForWidgetProvider(filterParams));

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
              _ViewToggle(
                showBubbles: showBubbles.value,
                onBubblesTap: () => showBubbles.value = true,
                onMarkersTap: () => showBubbles.value = false,
              ),
              const SizedBox(width: AdminSpacing.md),
              locationsAsync.when(
                data: (locations) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withOpacity(0.1),
                    borderRadius: AdminRadius.smAll,
                  ),
                  child: Text(
                    '${locations.length} visits',
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
          WidgetFiltersRow(
            missionId: missionId,
            selectedCity: selectedCity.value,
            selectedChannel: selectedChannel.value,
            startDate: startDate.value,
            endDate: endDate.value,
            hasFilters: hasFilters,
            onCityChanged: (v) => selectedCity.value = v,
            onChannelChanged: (v) => selectedChannel.value = v,
            onDateRangeChanged: (range) {
              startDate.value = range?.start;
              endDate.value = range?.end;
            },
            onClearAll: () {
              selectedCity.value = null;
              selectedChannel.value = null;
              startDate.value = null;
              endDate.value = null;
            },
          ),
          const SizedBox(height: AdminSpacing.md),
          Expanded(
            child: ClipRRect(
              borderRadius: AdminRadius.mdAll,
              child: locationsAsync.when(
                data: (locations) => _MapContent(
                  locations: locations,
                  showBubbles: showBubbles.value,
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
}

class _ViewToggle extends StatelessWidget {
  final bool showBubbles;
  final VoidCallback onBubblesTap;
  final VoidCallback onMarkersTap;

  const _ViewToggle({
    required this.showBubbles,
    required this.onBubblesTap,
    required this.onMarkersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.backgroundHover,
        borderRadius: AdminRadius.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            icon: Icons.bubble_chart,
            label: 'Cities',
            isSelected: showBubbles,
            onTap: onBubblesTap,
          ),
          _ToggleButton(
            icon: Icons.location_on,
            label: 'Markers',
            isSelected: !showBubbles,
            onTap: onMarkersTap,
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AdminRadius.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AdminColors.primary : Colors.transparent,
          borderRadius: AdminRadius.smAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AdminColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AdminTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AdminColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapContent extends StatelessWidget {
  final List<LocationPoint> locations;
  final bool showBubbles;
  final MapController mapController;

  const _MapContent({
    required this.locations,
    required this.showBubbles,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return const _EmptyMap();
    }

    final lats = locations.map((l) => l.lat).toList();
    final lngs = locations.map((l) => l.lng).toList();
    final centerLat = lats.reduce((a, b) => a + b) / lats.length;
    final centerLng = lngs.reduce((a, b) => a + b) / lngs.length;

    return FlutterMap(
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
        if (showBubbles)
          _CityBubbleLayer(locations: locations)
        else
          _MarkerLayer(locations: locations),
      ],
    );
  }
}

class _MarkerLayer extends StatelessWidget {
  final List<LocationPoint> locations;

  const _MarkerLayer({required this.locations});

  @override
  Widget build(BuildContext context) {
    final clusters = _clusterLocations(locations);

    return MarkerLayer(
      markers: clusters.map((cluster) {
        final isCluster = cluster.count > 1;
        final size =
            isCluster ? 40.0 + (cluster.count.clamp(2, 50) * 0.5) : 30.0;

        return Marker(
          point: LatLng(cluster.lat, cluster.lng),
          width: size,
          height: size,
          child: GestureDetector(
            onTap: () => _showLocationInfo(context, cluster),
            child: Container(
              decoration: BoxDecoration(
                color:
                    isCluster ? AdminColors.primary : AdminColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: isCluster
                    ? Text(
                        cluster.count > 99 ? '99+' : '${cluster.count}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const Icon(Icons.store, color: Colors.white, size: 16),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showLocationInfo(BuildContext context, _Cluster cluster) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: Row(
          children: [
            Icon(Icons.location_on, color: AdminColors.primary),
            const SizedBox(width: 8),
            Text(
              cluster.count > 1 ? '${cluster.count} Visits' : 'Visit',
              style: AdminTextStyles.sectionTitle,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cluster.locations.first.locationName != null)
              _infoRow('Name', cluster.locations.first.locationName!),
            if (cluster.locations.first.city != null)
              _infoRow('City', cluster.locations.first.city!),
            if (cluster.locations.first.district != null)
              _infoRow('District', cluster.locations.first.district!),
            if (cluster.locations.first.placeType != null)
              _infoRow('Type', cluster.locations.first.placeType!),
            _infoRow(
              'Coordinates',
              '${cluster.lat.toStringAsFixed(4)}, ${cluster.lng.toStringAsFixed(4)}',
            ),
          ],
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AdminTextStyles.labelSmall
                  .copyWith(color: AdminColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(value, style: AdminTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _CityBubbleLayer extends StatelessWidget {
  final List<LocationPoint> locations;

  const _CityBubbleLayer({required this.locations});

  @override
  Widget build(BuildContext context) {
    final groups = _groupByCity(locations);
    if (groups.isEmpty) return const SizedBox.shrink();

    final maxCount = groups.map((g) => g.count).reduce((a, b) => a > b ? a : b);

    return MarkerLayer(
      markers: groups.map((group) {
        final ratio = maxCount == 0 ? 0.0 : group.count / maxCount;
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
          point: LatLng(group.lat, group.lng),
          width: diameter < 90 ? 90 : diameter,
          height: diameter + 18,
          child: GestureDetector(
            onTap: () => _showCityInfo(context, group),
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
                      '${group.count}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: diameter > 60 ? 16 : 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    group.name,
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

  void _showCityInfo(BuildContext context, _CityGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: Row(
          children: [
            Icon(Icons.location_city, color: AdminColors.primary),
            const SizedBox(width: 8),
            Text(group.name, style: AdminTextStyles.sectionTitle),
          ],
        ),
        content: Text(
          '${group.count} accepted ${group.count == 1 ? 'visit' : 'visits'} in this city',
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

/// Groups visit points by city; centroid comes from CITIES, falling back to the
/// mean of the city's own points (covers cities missing from the constant).
List<_CityGroup> _groupByCity(List<LocationPoint> locations) {
  final groups = <String, _CityGroup>{};

  for (final location in locations) {
    final info = cityInfoFor(location.city);
    final name = (info?['english'] as String?) ??
        ((location.city?.trim().isNotEmpty ?? false)
            ? location.city!.trim()
            : 'Unknown');

    final group = groups.putIfAbsent(
      name.toLowerCase(),
      () => _CityGroup(
        name: name,
        fixedLat: (info?['lat'] as num?)?.toDouble(),
        fixedLng: (info?['lng'] as num?)?.toDouble(),
      ),
    );
    group.add(location);
  }

  return groups.values.toList();
}

class _CityGroup {
  final String name;
  final double? fixedLat;
  final double? fixedLng;
  int count = 0;
  double _sumLat = 0;
  double _sumLng = 0;

  _CityGroup({required this.name, this.fixedLat, this.fixedLng});

  void add(LocationPoint location) {
    count++;
    _sumLat += location.lat;
    _sumLng += location.lng;
  }

  double get lat => fixedLat ?? _sumLat / count;
  double get lng => fixedLng ?? _sumLng / count;
}

List<_Cluster> _clusterLocations(List<LocationPoint> locations) {
  const gridSize = 0.05;
  final clusters = <String, _Cluster>{};

  for (final location in locations) {
    final gridKey =
        '${(location.lat / gridSize).floor()}_${(location.lng / gridSize).floor()}';

    if (clusters.containsKey(gridKey)) {
      clusters[gridKey]!.add(location);
    } else {
      clusters[gridKey] = _Cluster(location);
    }
  }

  return clusters.values.toList();
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
              'No location data available',
              style: AdminTextStyles.bodyMedium
                  .copyWith(color: AdminColors.textMuted),
            ),
            const SizedBox(height: AdminSpacing.xs),
            Text(
              'Locations will appear when submissions have coordinates',
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

class _Cluster {
  final List<LocationPoint> locations = [];
  double _sumLat = 0;
  double _sumLng = 0;

  _Cluster(LocationPoint first) {
    add(first);
  }

  void add(LocationPoint location) {
    locations.add(location);
    _sumLat += location.lat;
    _sumLng += location.lng;
  }

  int get count => locations.length;
  double get lat => _sumLat / count;
  double get lng => _sumLng / count;
}
