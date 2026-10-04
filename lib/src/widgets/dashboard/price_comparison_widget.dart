import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'price_sku_picker.dart';
import 'price_widget_shell.dart';
import '../../data/anchor_prices_provider.dart';
import 'export_button.dart';
import '../../data/price_monitor_provider.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_typography.dart';

/// Average price of selected SKUs compared across cities or channels.
class PriceComparisonWidget extends HookConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;

  const PriceComparisonWidget({
    super.key,
    required this.missionId,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSkuKeys = useState<Set<String>>({});
    final dimension = useState(PriceGroupDimension.city);

    final params = PriceComparisonParams(
      filters: PriceFilterParams(
        missionId: missionId,
        skuKeys: selectedSkuKeys.value,
      ),
      dimension: dimension.value,
    );
    final statsAsync = ref.watch(priceComparisonProvider(params));

    final selectedLabels = selectedSkuKeys.value.map(priceSkuLabel).toList()
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

    return PriceWidgetShell(
      title: title,
      subtitle: subtitle,
      trailing: ExportButton(
        baseName: 'price_comparison',
        buildData: () async {
          final stats = await ref.read(priceComparisonProvider(params).future);
          return CsvExportData(
            header: const ['Group', 'Avg Price (EGP)', 'Observations'],
            rows: stats
                .map((s) => <Object?>[
                      s.label,
                      s.avgPrice.toStringAsFixed(2),
                      s.observationCount,
                    ])
                .toList(),
          );
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: PriceGroupDimension.values.map((d) {
                    return Padding(
                      padding: const EdgeInsets.only(right: AdminSpacing.sm),
                      child: ChoiceChip(
                        label: Text(
                          d == PriceGroupDimension.city ? 'By City' : 'By Channel',
                        ),
                        selected: dimension.value == d,
                        onSelected: (_) => dimension.value = d,
                      ),
                    );
                  }).toList(),
                ),
              ),
              PriceSkuSelectButton(
                selectedCount: selectedSkuKeys.value.length,
                selectedLabels: selectedLabels,
                onPressed: openSkuPicker,
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          Expanded(
            child: PriceAsyncContent(
              value: statsAsync,
              builder: (stats) {
                if (selectedSkuKeys.value.isEmpty) {
                  return const PriceWidgetMessage(
                    message: 'Select SKUs to compare average prices',
                  );
                }
                if (stats.isEmpty) {
                  return const PriceWidgetMessage(
                    message: 'No price data for the selected SKUs',
                  );
                }
                return _ComparisonBarChart(stats: stats);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonBarChart extends StatelessWidget {
  final List<PriceGroupStat> stats;

  const _ComparisonBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final maxPrice =
        stats.map((s) => s.avgPrice).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxPrice * 1.15,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AdminColors.divider,
            strokeWidth: 1,
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AdminColors.textPrimary,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final stat = stats[group.x.toInt()];
              return BarTooltipItem(
                '${stat.label}\n'
                '${stat.avgPrice.toStringAsFixed(2)} EGP '
                '(${stat.observationCount} obs)',
                AdminTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= stats.length) return const SizedBox.shrink();
                final label = stats[i].label;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label.length > 10 ? '${label.substring(0, 9)}…' : label,
                    style: AdminTextStyles.labelSmall,
                  ),
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
        barGroups: [
          for (var i = 0; i < stats.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: stats[i].avgPrice,
                  color: AdminColors.primary,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
