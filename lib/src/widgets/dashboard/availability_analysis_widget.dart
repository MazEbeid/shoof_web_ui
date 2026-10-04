import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'availability_vs_price_widget.dart';
import 'export_button.dart';
import 'sku_filter_bar.dart';
import '../../data/price_monitor_provider.dart';
import '../../data/widget_data_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// The three lenses of [AvailabilityAnalysisWidget].
enum AvailabilityAnalysisView { bySku, skuChannel, availabilityPrice }

/// CSV rows for a per-SKU availability list (analysis "By SKU" view and the
/// admin SKU availability grid).
CsvExportData skuAvailabilityCsv(List<SkuAvailability> skus) => CsvExportData(
      header: const [
        'SKU', 'Brand', 'Company', 'Package', 'Size',
        'Stores Checked', 'Stores Stocking', 'Availability %',
      ],
      rows: skus
          .map((s) => <Object?>[
                s.skuEnglish, s.brand, s.company, s.package, s.size,
                s.totalChecks, s.availableCount,
                s.availabilityRate.toStringAsFixed(1),
              ])
          .toList(),
    );

/// Availability Analysis Widget
///
/// Metric: STORES ("X of Y stores currently stock it") - each store counts
/// once and its most recent visit decides the state, no matter how many
/// times it was visited.
///
/// Three views:
/// - "By SKU": per-SKU store availability ranking (worst first)
/// - "SKU x Channel": heatmap matrix of store availability % per channel
/// - "Availability x Price": availability % joined with avg observed price
///
/// Self-contained with local filter state (city/channel/date + company/
/// brand/package/size). Self-sizing: long lists expand the widget so the
/// page scrolls instead of trapping an inner scrollbar.
class AvailabilityAnalysisWidget extends HookConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;
  final String? subtitleAr;
  final AvailabilityAnalysisView initialView;

  const AvailabilityAnalysisWidget({
    super.key,
    required this.missionId,
    this.title = 'SKU Availability',
    this.subtitle,
    this.subtitleAr,
    this.initialView = AvailabilityAnalysisView.bySku,
  });

  static const int _previewRowCount = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = useState(initialView);
    final showAll = useState(false);

    // Local filter state
    final filters = useSkuFilters();
    final filterParams = filters.params(missionId);

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
              Icon(Icons.inventory_2_outlined,
                  color: AdminColors.primary, size: 24),
              const SizedBox(width: AdminSpacing.sm),
              Text(title, style: AdminTextStyles.sectionTitle),
              const Spacer(),
              _ViewToggle(
                view: view.value,
                onChanged: (v) => view.value = v,
              ),
              const SizedBox(width: AdminSpacing.md),
              ExportButton(
                baseName: switch (view.value) {
                  AvailabilityAnalysisView.bySku => 'availability_by_sku',
                  AvailabilityAnalysisView.skuChannel =>
                    'availability_by_sku_channel',
                  AvailabilityAnalysisView.availabilityPrice =>
                    'availability_vs_price',
                },
                buildData: () async => switch (view.value) {
                  AvailabilityAnalysisView.bySku => skuAvailabilityCsv(
                      await ref.read(
                          skuAvailabilityForWidgetProvider(filterParams)
                              .future)),
                  AvailabilityAnalysisView.skuChannel => CsvExportData(
                      header: const [
                        'SKU', 'Channel', 'Stores Checked',
                        'Stores Stocking', 'Availability %',
                      ],
                      rows: (await ref.read(
                              skuChannelAvailabilityForWidgetProvider(
                                      filterParams)
                                  .future))
                          .map((c) => <Object?>[
                                c.skuEnglish, c.channel, c.totalChecks,
                                c.availableCount,
                                c.availabilityRate.toStringAsFixed(1),
                              ])
                          .toList(),
                    ),
                  AvailabilityAnalysisView.availabilityPrice => CsvExportData(
                      header: const [
                        'SKU', 'Availability %', 'Avg Price (EGP)',
                        'Stores', 'Price Observations', 'Flagged',
                      ],
                      rows: (await ref.read(availabilityVsPriceProvider(
                              AvailabilityPriceListView.priceParams(
                                  filterParams))
                          .future))
                          .map((r) => <Object?>[
                                r.skuLabel,
                                r.availabilityRate.toStringAsFixed(1),
                                r.avgPrice?.toStringAsFixed(2),
                                r.totalChecks, r.observationCount,
                                r.flagged ? 'YES' : '',
                              ])
                          .toList(),
                    ),
                },
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
            switch (view.value) {
              AvailabilityAnalysisView.bySku =>
                'Per-SKU availability across stores (latest visit per store)',
              AvailabilityAnalysisView.skuChannel =>
                '% of stores currently stocking the SKU, per channel '
                    '(latest visit per store)',
              AvailabilityAnalysisView.availabilityPrice =>
                'Availability % vs average observed price — flags SKUs both '
                    'scarce and priced above the median',
            },
            style: AdminTextStyles.bodySmall.copyWith(
              color: AdminColors.textMuted,
            ),
          ),
          const SizedBox(height: AdminSpacing.md),

          // Filters row
          SkuFilterBar(missionId: missionId, filters: filters),
          const SizedBox(height: AdminSpacing.md),

          // Body
          switch (view.value) {
            AvailabilityAnalysisView.skuChannel => _SkuChannelHeatmap(
                filterParams: filterParams,
                showAll: showAll.value,
                onToggleShowAll: () => showAll.value = !showAll.value,
              ),
            AvailabilityAnalysisView.availabilityPrice =>
              AvailabilityPriceListView(
                params: filterParams,
                showAll: showAll.value,
                onToggleShowAll: () => showAll.value = !showAll.value,
                previewRowCount: _previewRowCount,
              ),
            AvailabilityAnalysisView.bySku => _SkuRankedList(
                allSkus: allSkus,
                showAll: showAll.value,
                onToggleShowAll: () => showAll.value = !showAll.value,
              ),
          },

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

/// "Show all N" / "Show top N" toggle used by both views.
class _ShowAllToggle extends StatelessWidget {
  final int totalCount;
  final bool showAll;
  final VoidCallback onTap;

  const _ShowAllToggle({
    required this.totalCount,
    required this.showAll,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(
          showAll ? Icons.expand_less : Icons.expand_more,
          size: 18,
        ),
        label: Text(
          showAll
              ? 'Show top ${AvailabilityAnalysisWidget._previewRowCount}'
              : 'Show all $totalCount rows',
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final AvailabilityAnalysisView view;
  final ValueChanged<AvailabilityAnalysisView> onChanged;

  const _ViewToggle({
    required this.view,
    required this.onChanged,
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
            isSelected: view == AvailabilityAnalysisView.bySku,
            onTap: () => onChanged(AvailabilityAnalysisView.bySku),
          ),
          _ToggleButton(
            icon: Icons.grid_on,
            label: 'SKU × Channel',
            isSelected: view == AvailabilityAnalysisView.skuChannel,
            onTap: () => onChanged(AvailabilityAnalysisView.skuChannel),
          ),
          _ToggleButton(
            icon: Icons.price_check,
            label: 'Availability × Price',
            isSelected: view == AvailabilityAnalysisView.availabilityPrice,
            onTap: () =>
                onChanged(AvailabilityAnalysisView.availabilityPrice),
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

/// Ranked list view: worst-availability SKUs first (store-level).
class _SkuRankedList extends StatelessWidget {
  final AsyncValue<List<SkuAvailability>> allSkus;
  final bool showAll;
  final VoidCallback onToggleShowAll;

  const _SkuRankedList({
    required this.allSkus,
    required this.showAll,
    required this.onToggleShowAll,
  });

  @override
  Widget build(BuildContext context) {
    return allSkus.when(
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Error loading data: $e',
            style: AdminTextStyles.bodySmall.copyWith(color: AdminColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (skus) {
        if (skus.isEmpty) {
          return SizedBox(
            height: 120,
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

        // Sort by availability rate (worst first)
        final sorted = List<SkuAvailability>.from(skus)
          ..sort((a, b) => a.availabilityRate.compareTo(b.availabilityRate));
        final visible = showAll
            ? sorted
            : sorted.take(AvailabilityAnalysisWidget._previewRowCount).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
                      'Stores',
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

            for (var index = 0; index < visible.length; index++)
              _buildRow(index, visible[index]),

            if (sorted.length > AvailabilityAnalysisWidget._previewRowCount)
              _ShowAllToggle(
                totalCount: sorted.length,
                showAll: showAll,
                onTap: onToggleShowAll,
              ),
          ],
        );
      },
    );
  }

  Widget _buildRow(int index, SkuAvailability sku) {
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
        border: Border.all(color: color.withValues(alpha: 0.15)),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getColorForPackage(sku.package).withValues(alpha: 0.1),
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
          // Store counts (latest visit per store)
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
                  'stocking / stores',
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

/// Heatmap view: store availability % per SKU per channel, worst SKUs first.
/// Columns stretch to fill the parent; horizontal scroll only when the
/// natural width exceeds it.
class _SkuChannelHeatmap extends ConsumerWidget {
  final WidgetFilterParams filterParams;
  final bool showAll;
  final VoidCallback onToggleShowAll;

  const _SkuChannelHeatmap({
    required this.filterParams,
    required this.showAll,
    required this.onToggleShowAll,
  });

  static const double _skuColWidth = 180;
  static const double _minChannelColWidth = 88;
  static const double _avgColWidth = 64;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cellsAsync =
        ref.watch(skuChannelAvailabilityForWidgetProvider(filterParams));

    return cellsAsync.when(
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Error loading data: $e',
            style:
                AdminTextStyles.bodySmall.copyWith(color: AdminColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (cells) {
        if (cells.isEmpty) {
          return SizedBox(
            height: 120,
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
        final visibleSkus = showAll
            ? skus
            : skus.take(AvailabilityAnalysisWidget._previewRowCount).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            // Stretch channels to fill the parent; never below the minimum.
            final channelWidth = math.max(
              _minChannelColWidth,
              (constraints.maxWidth - _skuColWidth - _avgColWidth) /
                  channels.length,
            );
            final naturalWidth =
                _skuColWidth + channels.length * channelWidth + _avgColWidth;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: naturalWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header row
                        Row(
                          children: [
                            _headerCell('SKU', _skuColWidth,
                                align: TextAlign.left),
                            for (final channel in channels)
                              _headerCell(channel, channelWidth),
                            _headerCell('Avg', _avgColWidth),
                          ],
                        ),
                        const SizedBox(height: 3),
                        for (final sku in visibleSkus)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: _skuColWidth,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      sku,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AdminTextStyles.bodySmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                for (final channel in channels)
                                  _rateCell(sku, channel, matrix[sku]![channel],
                                      channelWidth),
                                _avgCell(overallRate(matrix[sku]!)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (skus.length >
                    AvailabilityAnalysisWidget._previewRowCount)
                  _ShowAllToggle(
                    totalCount: skus.length,
                    showAll: showAll,
                    onTap: onToggleShowAll,
                  ),
                const SizedBox(height: AdminSpacing.sm),
                _buildLegend(),
              ],
            );
          },
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

  Widget _rateCell(String sku, String channel, SkuChannelAvailability? cell,
      double width) {
    if (cell == null || cell.totalChecks == 0) {
      return SizedBox(
        width: width,
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
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Tooltip(
          message:
              '$sku\n$channel · ${cell.availableCount}/${cell.totalChecks} stores stocking',
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
          'High · cell = % of stores stocking',
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
