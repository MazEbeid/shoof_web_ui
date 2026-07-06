import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'widget_filters_row.dart';
import '../../data/widget_data_providers.dart';
import '../../data/cities_constants.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// Region colors shared by the coverage map and region breakdown charts.
const Map<String, Color> kRegionColors = {
  'Cairo': Color(0xFF2962FF),
  'Alexandria': Color(0xFF00BCD4),
  'Delta': Color(0xFF00C853),
  'Suez Canal': Color(0xFF9C27B0),
  'Upper Egypt': Color(0xFFFF9800),
};

/// Color for a region name, with a neutral fallback for unmapped regions.
Color regionColorFor(String? region) =>
    kRegionColors[region] ?? const Color(0xFF78909C);

/// Coverage Map Widget - stylized Egypt map with per-city visit bubbles,
/// a top-cities side panel, and a region legend.
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
            child: locationsAsync.when(
              data: (locations) => _CoverageMapContent(locations: locations),
              loading: () => const _LoadingMap(),
              error: (e, _) => _ErrorMap(message: e.toString()),
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

class _CoverageMapContent extends StatelessWidget {
  final List<LocationPoint> locations;

  const _CoverageMapContent({required this.locations});

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return const _EmptyMap();
    }

    final groups = _groupByCity(locations)
      ..sort((a, b) => b.count.compareTo(a.count));

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidePanel = constraints.maxWidth >= 560;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _EgyptBubbleMap(groups: groups)),
            if (showSidePanel) ...[
              const SizedBox(width: AdminSpacing.lg),
              SizedBox(width: 200, child: _CitySidePanel(groups: groups)),
            ],
          ],
        );
      },
    );
  }
}

/// Stylized Egypt map (fixed 400x445 canvas scaled to fit) with one bubble
/// per city: size = visits, color = region.
class _EgyptBubbleMap extends StatelessWidget {
  final List<_CityGroup> groups; // sorted by count, descending

  const _EgyptBubbleMap({required this.groups});

  static const double _mapWidth = 400;
  static const double _mapHeight = 445;

  @override
  Widget build(BuildContext context) {
    final maxCount = groups.first.count;

    final children = <Widget>[
      const CustomPaint(
        size: Size(_mapWidth, _mapHeight),
        painter: _EgyptMapPainter(),
      ),
    ];

    for (var i = groups.length - 1; i >= 0; i--) {
      final group = groups[i];
      final position = _positionFor(group);
      final ratio = maxCount == 0 ? 0.0 : group.count / maxCount;
      final radius = 7.0 + 15.0 * math.sqrt(ratio);

      // Smaller bubbles are drawn last (on top) so dense areas stay clickable;
      // labels only for the busiest cities to avoid clutter.
      children.add(Positioned(
        left: position.dx - radius,
        top: position.dy - radius,
        child: Tooltip(
          message:
              '${group.name} — ${group.count} ${group.count == 1 ? 'visit' : 'visits'}',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _showCityInfo(context, group),
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  color: regionColorFor(group.region).withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ));

      if (i < 5) {
        children.add(Positioned(
          left: position.dx - 40,
          top: position.dy + radius + 2,
          width: 80,
          child: IgnorePointer(
            child: Text(
              group.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ));
      }
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: _mapWidth,
        height: _mapHeight,
        child: Stack(children: children),
      ),
    );
  }

  Offset _positionFor(_CityGroup group) {
    final fixed = group.key != null ? _cityPositions[group.key] : null;
    if (fixed != null) return fixed;

    // Cities missing from the position table are projected from their mean
    // coordinates with an affine fit anchored on Cairo/Alexandria/Aswan.
    return Offset(
      (40.73 * group.lng + 3.15 * group.lat - 1147.1).clamp(24.0, 376.0),
      (-4.45 * group.lng - 45.74 * group.lat + 1587.2).clamp(20.0, 424.0),
    );
  }

  void _showCityInfo(BuildContext context, _CityGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: Row(
          children: [
            Icon(Icons.location_city, color: regionColorFor(group.region)),
            const SizedBox(width: 8),
            Text(group.name, style: AdminTextStyles.sectionTitle),
          ],
        ),
        content: Text(
          '${group.count} accepted ${group.count == 1 ? 'visit' : 'visits'}'
          ' · ${group.region} region',
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

/// Hand-placed bubble positions on the stylized map, keyed by CITIES key.
const Map<String, Offset> _cityPositions = {
  'cairo': Offset(220, 74),
  'giza': Offset(200, 93),
  'qalyubia': Offset(232, 62),
  'alexandria': Offset(170, 27),
  'beheira': Offset(186, 42),
  'marsaMatruh': Offset(61, 32),
  'damietta': Offset(247, 26),
  'monufia': Offset(212, 58),
  'gharbia': Offset(206, 46),
  'kafrElSheikh': Offset(211, 30),
  'dakahlia': Offset(226, 32),
  'mit-ghamr': Offset(237, 43),
  'sharqia': Offset(245, 52),
  'portSaid': Offset(254, 25),
  'ismailia': Offset(252, 60),
  'suez': Offset(260, 84),
  'northSinai': Offset(305, 55),
  'southSinai': Offset(307, 110),
  'fayyum': Offset(196, 114),
  'beniSuef': Offset(213, 124),
  'minya': Offset(200, 163),
  'asyut': Offset(214, 205),
  'wadiElGedid': Offset(90, 330),
  'sohag': Offset(232, 233),
  'qena': Offset(263, 243),
  'luxor': Offset(261, 268),
  'aswan': Offset(269, 339),
  'bahrElAhmar': Offset(298, 200),
};

/// Paints the Egypt landmass (with Sinai and the Gulf of Suez notch) and the
/// Nile with its Delta branches on a 400x445 canvas.
class _EgyptMapPainter extends CustomPainter {
  const _EgyptMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final land = Path()
      ..moveTo(21, 10)
      ..lineTo(88, 20)
      ..lineTo(142, 36)
      ..lineTo(173, 26)
      ..cubicTo(179, 17, 186, 12, 194, 12)
      ..lineTo(215, 14)
      ..lineTo(234, 17)
      ..lineTo(250, 23)
      ..lineTo(298, 29)
      ..lineTo(312, 22)
      ..lineTo(333, 102)
      ..lineTo(325, 125)
      ..lineTo(320, 145)
      ..lineTo(312, 179)
      ..lineTo(292, 157)
      ..lineTo(263, 97)
      ..lineTo(258, 81)
      ..lineTo(251, 97)
      ..lineTo(261, 118)
      ..lineTo(275, 151)
      ..lineTo(298, 200)
      ..lineTo(302, 222)
      ..lineTo(313, 251)
      ..lineTo(333, 296)
      ..lineTo(351, 345)
      ..lineTo(397, 431)
      ..lineTo(16, 431)
      ..close();

    canvas.drawPath(land, Paint()..color = const Color(0xFFEAF0F7));
    canvas.drawPath(
      land,
      Paint()
        ..color = const Color(0xFFC3D0E0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final nilePaint = Paint()
      ..color = const Color(0xFFA8C6E8).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final nile = Path()
      ..moveTo(269, 339)
      ..cubicTo(264, 315, 258, 290, 261, 268)
      ..cubicTo(270, 255, 268, 235, 258, 225)
      ..cubicTo(230, 210, 216, 208, 214, 203)
      ..cubicTo(205, 190, 202, 175, 200, 163)
      ..cubicTo(204, 135, 212, 100, 216, 77)
      ..cubicTo(210, 55, 196, 30, 189, 16);
    canvas.drawPath(nile, nilePaint);

    final branchPaint = Paint()
      ..color = const Color(0xFFA8C6E8).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final rosettaBranch = Path()
      ..moveTo(216, 77)
      ..cubicTo(222, 58, 230, 35, 234, 20);
    canvas.drawPath(rosettaBranch, branchPaint);
  }

  @override
  bool shouldRepaint(covariant _EgyptMapPainter oldDelegate) => false;
}

/// Side panel: top cities ranked by visits plus the region legend.
class _CitySidePanel extends StatelessWidget {
  final List<_CityGroup> groups; // sorted by count, descending

  const _CitySidePanel({required this.groups});

  @override
  Widget build(BuildContext context) {
    final top = groups.take(6).toList();
    final topCount = top.first.count;
    final regions = <String>{for (final g in groups) g.region};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOP CITIES BY VISITS',
          style: AdminTextStyles.labelSmall.copyWith(
            color: AdminColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AdminSpacing.sm),
        for (final group in top)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 76,
                  child: Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminTextStyles.labelSmall,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 5,
                      color: AdminColors.backgroundHover,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor:
                            topCount == 0 ? 0 : group.count / topCount,
                        child: Container(
                          color: regionColorFor(group.region),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${group.count}',
                  style: AdminTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.xs,
          children: [
            for (final region in regions)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: regionColorFor(region),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    region,
                    style: AdminTextStyles.labelSmall.copyWith(
                      color: AdminColors.textSecondary,
                    ),
                  ),
                ],
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AdminColors.textMuted,
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'size = visits',
                  style: AdminTextStyles.labelSmall.copyWith(
                    color: AdminColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Groups visit points by city, resolving name/region/position key from the
/// CITIES constants and keeping mean coordinates as a fallback position.
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
        key: info?['value'] as String?,
        region: (info?['region'] as String?) ?? 'Other',
      ),
    );
    group.add(location);
  }

  return groups.values.toList();
}

class _CityGroup {
  final String name;
  final String? key;
  final String region;
  int count = 0;
  double _sumLat = 0;
  double _sumLng = 0;

  _CityGroup({required this.name, this.key, required this.region});

  void add(LocationPoint location) {
    count++;
    _sumLat += location.lat;
    _sumLng += location.lng;
  }

  double get lat => _sumLat / count;
  double get lng => _sumLng / count;
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
