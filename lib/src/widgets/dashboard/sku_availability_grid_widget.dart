import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'availability_analysis_widget.dart' show skuAvailabilityCsv;
import 'export_button.dart';
import 'sku_filter_bar.dart';
import '../../data/widget_data_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// SKU Availability Grid Widget
///
/// Shows a grid of mini donut charts, one per SKU.
/// Each donut shows stores stocking / stores checked for that SKU
/// (store-level, latest visit per store).
///
/// Filters (city, channel, date, company/brand/package/size) affect all
/// SKUs - percentages recalculate.
class SkuAvailabilityGridWidget extends HookConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;

  const SkuAvailabilityGridWidget({
    super.key,
    required this.missionId,
    this.title = 'SKU Availability Overview',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Local filter state
    final filters = useSkuFilters();
    final filterParams = filters.params(missionId);

    // Watch data
    final allSkus = ref.watch(skuAvailabilityForWidgetProvider(filterParams));

    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: AdminRadius.lgAll,
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.grid_view_rounded, color: AdminColors.primary, size: 24),
              const SizedBox(width: AdminSpacing.sm),
              Text(title, style: AdminTextStyles.sectionTitle),
              const Spacer(),
              ExportButton(
                baseName: 'sku_availability',
                buildData: () async => skuAvailabilityCsv(await ref.read(
                    skuAvailabilityForWidgetProvider(filterParams).future)),
              ),
              const SizedBox(width: AdminSpacing.sm),
              // SKU count badge
              allSkus.when(
                data: (skus) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withOpacity(0.1),
                    borderRadius: AdminRadius.smAll,
                  ),
                  child: Text(
                    '${skus.length} SKUs',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AdminColors.primary,
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.sm),
          Text(
            'Each chart shows availability rate for that specific SKU',
            style: AdminTextStyles.bodySmall.copyWith(
              color: AdminColors.textMuted,
            ),
          ),
          const SizedBox(height: AdminSpacing.md),

          // Filters row
          SkuFilterBar(missionId: missionId, filters: filters),
          const SizedBox(height: AdminSpacing.lg),

          // Grid of SKU donuts
          allSkus.when(
            data: (skus) {
              if (skus.isEmpty) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'No SKU data available',
                      style: AdminTextStyles.bodySmall.copyWith(
                        color: AdminColors.textMuted,
                      ),
                    ),
                  ),
                );
              }

              // Sort by availability rate (best first for grid view)
              final sorted = List<SkuAvailability>.from(skus)
                ..sort((a, b) => b.availabilityRate.compareTo(a.availabilityRate));

              return LayoutBuilder(
                builder: (context, constraints) {
                  const cardWidth = 140.0;
                  const cardSpacing = 12.0;

                  return Wrap(
                    spacing: cardSpacing,
                    runSpacing: cardSpacing,
                    children: sorted.map((sku) => _SkuDonutCard(
                      sku: sku,
                      width: cardWidth,
                    )).toList(),
                  );
                },
              );
            },
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Error loading data',
                  style: AdminTextStyles.bodySmall.copyWith(
                    color: AdminColors.error,
                  ),
                ),
              ),
            ),
          ),

          // Subtitle
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.lg),
            Text(
              subtitle!,
              style: AdminTextStyles.bodySmall.copyWith(
                color: AdminColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Individual SKU donut card
class _SkuDonutCard extends StatelessWidget {
  final SkuAvailability sku;
  final double width;

  const _SkuDonutCard({
    required this.sku,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final rate = sku.availabilityRate;
    final color = _getColorForRate(rate);

    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.backgroundHover,
        borderRadius: AdminRadius.mdAll,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Donut chart
          SizedBox(
            width: 70,
            height: 70,
            child: CustomPaint(
              painter: _DonutPainter(
                percentage: rate / 100,
                color: color,
                backgroundColor: color.withOpacity(0.15),
              ),
              child: Center(
                child: Text(
                  '${rate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // SKU name
          Text(
            sku.skuEnglish,
            style: AdminTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),

          // Package + Brand
          Text(
            '${sku.package} · ${sku.brand}',
            style: AdminTextStyles.bodySmall.copyWith(
              color: AdminColors.textMuted,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Check counts
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: AdminRadius.smAll,
            ),
            child: Text(
              '${sku.availableCount}/${sku.totalChecks} stores',
              style: TextStyle(
                fontSize: 9,
                color: AdminColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForRate(double rate) {
    if (rate >= 80) return AdminColors.success;
    if (rate >= 50) return AdminColors.warning;
    return AdminColors.error;
  }
}

/// Custom painter for donut chart
class _DonutPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _DonutPainter({
    required this.percentage,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Foreground arc
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
