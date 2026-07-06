import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'widget_filters_row.dart';
import '../../data/widget_data_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// Availability Analysis Widget
///
/// Two views:
/// - "By SKU": per-SKU availability ranking (worst first)
/// - "SKU x Channel": heatmap matrix of availability % per SKU per channel
///
/// Self-contained with local filter state - no global dependencies.
/// Rendered by both ShooofAdmin (builder/preview) and shoof_insights (client).
class AvailabilityAnalysisWidget extends HookConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;
  final String? subtitleAr;

  const AvailabilityAnalysisWidget({
    super.key,
    required this.missionId,
    this.title = 'SKU Availability',
    this.subtitle,
    this.subtitleAr,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showHeatmap = useState(false);

    // Local filter state
    final selectedCity = useState<String?>(null);
    final selectedChannel = useState<String?>(null);
    final startDate = useState<DateTime?>(null);
    final endDate = useState<DateTime?>(null);

    // Build filter params from local state
    final filterParams = WidgetFilterParams(
      missionId: missionId,
      city: selectedCity.value,
      channel: selectedChannel.value,
      startDate: startDate.value,
      endDate: endDate.value,
    );

    final allSkus = ref.watch(skuAvailabilityForWidgetProvider(filterParams));

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
          // Header
          Row(
            children: [
              Icon(Icons.inventory_2_outlined,
                  color: AdminColors.primary, size: 24),
              const SizedBox(width: AdminSpacing.sm),
              Text(title, style: AdminTextStyles.sectionTitle),
              const Spacer(),
              _ViewToggle(
                showHeatmap: showHeatmap.value,
                onListTap: () => showHeatmap.value = false,
                onHeatmapTap: () => showHeatmap.value = true,
              ),
              const SizedBox(width: AdminSpacing.md),
              // SKU count badge
              allSkus.when(
                data: (skus) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withValues(alpha: 0.1),
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
            showHeatmap.value
                ? '% of checks where the SKU was in stock, per channel'
                : 'Per-SKU availability based on individual store checks',
            style: AdminTextStyles.bodySmall.copyWith(
              color: AdminColors.textMuted,
            ),
          ),
          const SizedBox(height: AdminSpacing.md),

          // Filters row
          WidgetFiltersRow(
            missionId: missionId,
            selectedCity: selectedCity.value,
            selectedChannel: selectedChannel.value,
            startDate: startDate.value,
            endDate: endDate.value,
            hasFilters: filterParams.hasFilters,
            onCityChanged: (city) => selectedCity.value = city,
            onChannelChanged: (channel) => selectedChannel.value = channel,
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

          // Body
          Expanded(
            child: showHeatmap.value
                ? _SkuChannelHeatmap(filterParams: filterParams)
                : _SkuRankedList(allSkus: allSkus),
          ),

          // Subtitle
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.md),
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

class _ViewToggle extends StatelessWidget {
  final bool showHeatmap;
  final VoidCallback onListTap;
  final VoidCallback onHeatmapTap;

  const _ViewToggle({
    required this.showHeatmap,
    required this.onListTap,
    required this.onHeatmapTap,
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
            icon: Icons.format_list_numbered,
            label: 'By SKU',
            isSelected: !showHeatmap,
            onTap: onListTap,
          ),
          _ToggleButton(
            icon: Icons.grid_on,
            label: 'SKU × Channel',
            isSelected: showHeatmap,
            onTap: onHeatmapTap,
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

/// Ranked list view: worst-availability SKUs first.
class _SkuRankedList extends StatelessWidget {
  final AsyncValue<List<SkuAvailability>> allSkus;

  const _SkuRankedList({required this.allSkus});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column headers
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.sm, vertical: AdminSpacing.xs),
          decoration: BoxDecoration(
            color: AdminColors.backgroundPage,
            borderRadius: AdminRadius.smAll,
          ),
          child: Row(
            children: [
              const SizedBox(width: 32), // Rank column
              Expanded(
                flex: 3,
                child: Text(
                  'SKU',
                  style: AdminTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'Package',
                  textAlign: TextAlign.center,
                  style: AdminTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'Checks',
                  textAlign: TextAlign.center,
                  style: AdminTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  'Rate',
                  textAlign: TextAlign.right,
                  style: AdminTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AdminSpacing.xs),

        // SKU list
        Expanded(
          child: allSkus.when(
            data: (skus) {
              if (skus.isEmpty) {
                return Center(
                  child: Text(
                    'No SKU data available',
                    style: AdminTextStyles.bodySmall.copyWith(
                      color: AdminColors.textMuted,
                    ),
                  ),
                );
              }

              // Sort by availability rate (worst first)
              final sorted = List<SkuAvailability>.from(skus)
                ..sort(
                    (a, b) => a.availabilityRate.compareTo(b.availabilityRate));

              return ListView.builder(
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final sku = sorted[index];
                  final rate = sku.availabilityRate;
                  final color = _getColorForRate(rate);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AdminSpacing.sm,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.04),
                      borderRadius: AdminRadius.smAll,
                      border:
                          Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        // Rank
                        Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                        // SKU info
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sku.skuEnglish,
                                style: AdminTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${sku.brand} · ${sku.company}',
                                style: AdminTextStyles.bodySmall.copyWith(
                                  color: AdminColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Package
                        SizedBox(
                          width: 80,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getColorForPackage(sku.package)
                                  .withValues(alpha: 0.1),
                              borderRadius: AdminRadius.smAll,
                            ),
                            child: Text(
                              sku.package,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _getColorForPackage(sku.package),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Check counts
                        SizedBox(
                          width: 100,
                          child: Column(
                            children: [
                              Text(
                                '${sku.availableCount} / ${sku.totalChecks}',
                                textAlign: TextAlign.center,
                                style: AdminTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'found / checked',
                                textAlign: TextAlign.center,
                                style: AdminTextStyles.bodySmall.copyWith(
                                  color: AdminColors.textMuted,
                                  fontSize: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Rate badge
                        Container(
                          width: 70,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: AdminRadius.smAll,
                          ),
                          child: Text(
                            '${rate.toStringAsFixed(0)}%',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error loading data',
                style: AdminTextStyles.bodySmall.copyWith(
                  color: AdminColors.error,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorForRate(double rate) {
    if (rate >= 80) return AdminColors.success;
    if (rate >= 50) return AdminColors.warning;
    return AdminColors.error;
  }

  Color _getColorForPackage(String package) {
    final p = package.toUpperCase();
    if (p.contains('PET') || p.contains('PLASTIC')) {
      return AdminColors.primary;
    }
    if (p.contains('CAN')) {
      return AdminColors.info;
    }
    if (p.contains('GLASS') || p.contains('RGB') || p.contains('NRG')) {
      return const Color(0xFF8B4513); // Brown
    }
    if (p.contains('TETRA') || p.contains('CARTON')) {
      return AdminColors.warning;
    }
    return AdminColors.textMuted;
  }
}

/// Heatmap view: availability % per SKU per channel, worst SKUs first.
class _SkuChannelHeatmap extends ConsumerWidget {
  final WidgetFilterParams filterParams;

  const _SkuChannelHeatmap({required this.filterParams});

  static const double _skuColWidth = 180;
  static const double _channelColWidth = 88;
  static const double _avgColWidth = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cellsAsync =
        ref.watch(skuChannelAvailabilityForWidgetProvider(filterParams));

    return cellsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(
        child: Text(
          'Error loading data',
          style: AdminTextStyles.bodySmall.copyWith(color: AdminColors.error),
        ),
      ),
      data: (cells) {
        if (cells.isEmpty) {
          return Center(
            child: Text(
              'No SKU data available',
              style: AdminTextStyles.bodySmall.copyWith(
                color: AdminColors.textMuted,
              ),
            ),
          );
        }

        // sku -> channel -> cell
        final matrix = <String, Map<String, SkuChannelAvailability>>{};
        final channelTotals = <String, int>{};
        for (final cell in cells) {
          matrix.putIfAbsent(cell.skuEnglish, () => {})[cell.channel] = cell;
          channelTotals[cell.channel] =
              (channelTotals[cell.channel] ?? 0) + cell.totalChecks;
        }

        // Columns: busiest channels first. Rows: worst overall rate first.
        final channels = channelTotals.keys.toList()
          ..sort((a, b) => channelTotals[b]!.compareTo(channelTotals[a]!));
        double overallRate(Map<String, SkuChannelAvailability> row) {
          var total = 0, available = 0;
          for (final cell in row.values) {
            total += cell.totalChecks;
            available += cell.availableCount;
          }
          return total == 0 ? 0 : available / total * 100;
        }

        final skus = matrix.keys.toList()
          ..sort((a, b) =>
              overallRate(matrix[a]!).compareTo(overallRate(matrix[b]!)));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _skuColWidth +
                      channels.length * _channelColWidth +
                      _avgColWidth,
                  child: Column(
                    children: [
                      // Header row
                      Row(
                        children: [
                          _headerCell('SKU', _skuColWidth,
                              align: TextAlign.left),
                          for (final channel in channels)
                            _headerCell(channel, _channelColWidth),
                          _headerCell('Avg', _avgColWidth),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Expanded(
                        child: ListView.builder(
                          itemCount: skus.length,
                          itemBuilder: (context, index) {
                            final sku = skus[index];
                            final row = matrix[sku]!;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: _skuColWidth,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: Text(
                                        sku,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AdminTextStyles.bodySmall
                                            .copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  for (final channel in channels)
                                    _rateCell(sku, channel, row[channel]),
                                  _avgCell(overallRate(row)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AdminSpacing.sm),
            _buildLegend(),
          ],
        );
      },
    );
  }

  Widget _headerCell(String label, double width,
      {TextAlign align = TextAlign.center}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        child: Text(
          label,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AdminTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AdminColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _rateCell(String sku, String channel, SkuChannelAvailability? cell) {
    if (cell == null || cell.totalChecks == 0) {
      return SizedBox(
        width: _channelColWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AdminColors.backgroundHover,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '–',
              textAlign: TextAlign.center,
              style: AdminTextStyles.labelSmall.copyWith(
                color: AdminColors.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    final rate = cell.availabilityRate;
    return SizedBox(
      width: _channelColWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Tooltip(
          message:
              '$sku\n$channel · ${cell.availableCount}/${cell.totalChecks} in stock',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: _cellBackground(rate),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${rate.toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _cellInk(rate),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avgCell(double rate) {
    return SizedBox(
      width: _avgColWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AdminColors.backgroundPage,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${rate.toStringAsFixed(0)}%',
            textAlign: TextAlign.center,
            style: AdminTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AdminColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        Text(
          'Low',
          style: AdminTextStyles.labelSmall.copyWith(
            color: AdminColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 140,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFDACA8),
                Color(0xFFFFE1A3),
                Color(0xFFB7E9C0),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'High · cell = availability %',
          style: AdminTextStyles.labelSmall.copyWith(
            color: AdminColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Color ramp matching the Shoof Insights heatmap mockup.
  static Color _cellBackground(double rate) {
    if (rate >= 90) return const Color(0xFFDDF5E4);
    if (rate >= 80) return const Color(0xFFEAF6E3);
    if (rate >= 70) return const Color(0xFFFFF1D6);
    if (rate >= 60) return const Color(0xFFFFE3C2);
    return const Color(0xFFFDDCDA);
  }

  static Color _cellInk(double rate) {
    if (rate >= 80) return const Color(0xFF1C6B3C);
    if (rate >= 60) return const Color(0xFF8A5A00);
    return const Color(0xFFB3362B);
  }
}
