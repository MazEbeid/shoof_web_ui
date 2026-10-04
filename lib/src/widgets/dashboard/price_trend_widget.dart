import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'price_filter_controls.dart';
import 'price_observations_dialog.dart';
import 'price_sku_picker.dart';
import 'price_sku_summary_cards.dart';
import '../../data/anchor_prices_provider.dart';
import 'export_button.dart';
import '../../data/price_monitor_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

class PriceTrendWidget extends HookConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;

  const PriceTrendWidget({
    super.key,
    required this.missionId,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSkuKeys = useState<Set<String>>({});
    final timeMode = useState(PriceTimeMode.wow);

    final filterParams = PriceFilterParams(
      missionId: missionId,
      skuKeys: selectedSkuKeys.value,
      timeMode: timeMode.value,
    );

    final chartAsync = ref.watch(priceTrendProvider(filterParams));
    final summaryAsync = ref.watch(priceSkuSummaryProvider(filterParams));

    final selectedLabels = selectedSkuKeys.value
        .map(priceSkuLabel)
        .toList()
      ..sort();

    Future<void> openSkuPicker() async {
      final result = await showPriceSkuPickerDialog(
        context: context,
        ref: ref,
        missionId: missionId,
        initialSelection: selectedSkuKeys.value,
      );
      if (result != null) selectedSkuKeys.value = result;
    }

    return Container(
      height: AdminSpacing.widgetLarge,
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
              Expanded(
                child: Text(title, style: AdminTextStyles.sectionTitle),
              ),
              ExportButton(
                baseName: 'price_trend',
                buildData: () async {
                  final chart =
                      await ref.read(priceTrendProvider(filterParams).future);
                  return CsvExportData(
                    header: const ['Date', 'SKU', 'Avg Price', 'Observations'],
                    rows: [
                      for (final series in chart.series)
                        for (final point in series.points)
                          if (point.avgPrice != null)
                            <Object?>[
                              point.label,
                              series.skuLabel,
                              point.avgPrice!.toStringAsFixed(2),
                              point.count,
                            ],
                    ],
                  );
                },
              ),
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.xs),
            Text(
              subtitle!,
              style: AdminTextStyles.bodySmall.copyWith(
                color: AdminColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: AdminSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PriceTimeModeSelector(
                  value: timeMode.value,
                  onChanged: (m) => timeMode.value = m,
                ),
              ),
              PriceSkuSelectButton(
                selectedCount: selectedSkuKeys.value.length,
                selectedLabels: selectedLabels,
                onPressed: openSkuPicker,
              ),
            ],
          ),
          if (timeMode.value == PriceTimeMode.today) ...[
            const SizedBox(height: AdminSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: selectedSkuKeys.value.isEmpty
                    ? null
                    : () => showPriceObservationsDialog(
                          context: context,
                          ref: ref,
                          missionId: missionId,
                          skuKeys: selectedSkuKeys.value,
                        ),
                icon: const Icon(Icons.table_rows_outlined, size: 16),
                label: const Text('View observations'),
              ),
            ),
          ],
          if (selectedSkuKeys.value.isNotEmpty)
            PriceSkuSummaryCards(summaryAsync: summaryAsync),
          Expanded(
            child: chartAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: TextStyle(color: AdminColors.error),
                ),
              ),
              data: (chart) {
                if (selectedSkuKeys.value.isEmpty) {
                  return Center(
                    child: Text(
                      'Select SKUs to compare price trends',
                      style: AdminTextStyles.bodySmall.copyWith(
                        color: AdminColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (chart.isEmpty) {
                  return Center(
                    child: Text(
                      'No price data for selected SKUs',
                      style: AdminTextStyles.bodySmall.copyWith(
                        color: AdminColors.textMuted,
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PriceTrendLegend(series: chart.series),
                    if (chart.granularityNote != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        chart.granularityNote!,
                        style: AdminTextStyles.labelSmall.copyWith(
                          color: AdminColors.warning,
                        ),
                      ),
                    ],
                    const SizedBox(height: AdminSpacing.sm),
                    Expanded(child: _PriceTrendChart(chart: chart)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceTrendChart extends StatelessWidget {
  final PriceTrendChartData chart;

  const _PriceTrendChart({required this.chart});

  @override
  Widget build(BuildContext context) {
    final dateLabels = chart.dateLabels;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AdminColors.divider,
            strokeWidth: 1,
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: AdminRadius.sm,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.md,
              vertical: AdminSpacing.sm,
            ),
            tooltipMargin: 12,
            maxContentWidth: 240,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (_) => AdminColors.textPrimary,
            tooltipBorder: BorderSide(color: AdminColors.border, width: 1),
            getTooltipItems: (touchedSpots) {
              if (touchedSpots.isEmpty) return [];

              final xIndex = touchedSpots.first.spotIndex;
              if (xIndex < 0 || xIndex >= dateLabels.length) return [];

              final dateLabel = dateLabels[xIndex];
              final lines = <String>[];

              for (final series in chart.series) {
                if (xIndex >= series.points.length) continue;
                final point = series.points[xIndex];
                if (!point.hasData) continue;
                lines.add(
                  '${series.skuLabel}: ${point.avgPrice!.toStringAsFixed(2)} EGP '
                  '(${point.count} stores)',
                );
              }

              if (lines.isEmpty) return [];

              final text = '$dateLabel\n${lines.join('\n')}';
              return [
                LineTooltipItem(
                  text,
                  AdminTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ];
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= dateLabels.length) {
                  return const SizedBox.shrink();
                }
                final label = dateLabels[i];
                final short = label.length > 6 ? label.substring(5) : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(short, style: AdminTextStyles.labelSmall),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: AdminTextStyles.labelSmall,
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: chart.series.map((series) {
          final color = priceTrendColorForIndex(series.colorIndex);
          final spots = <FlSpot>[];
          for (var i = 0; i < series.points.length; i++) {
            final point = series.points[i];
            if (point.hasData) {
              spots.add(FlSpot(i.toDouble(), point.avgPrice!));
            }
          }
          return LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3,
                color: color,
                strokeWidth: 1,
                strokeColor: Colors.white,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
