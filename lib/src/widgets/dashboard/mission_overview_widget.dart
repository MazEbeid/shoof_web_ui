import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'coverage_map_widget.dart' show regionColorFor;
import 'widget_filters_row.dart';
import '../admin_stat_card.dart';
import '../../data/cities_constants.dart';
import '../../data/widget_data_providers.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// Full Mission Overview widget with counters, pie charts, and filters
///
/// Self-contained with local filter state - no global dependencies.
/// Rendered by both ShooofAdmin (builder/preview) and shoof_insights (client).
class MissionOverviewWidget extends HookConsumerWidget {
  final String missionId;
  final String title;
  final String? subtitle;

  const MissionOverviewWidget({
    super.key,
    required this.missionId,
    this.title = 'Mission Overview',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Local filter state
    final selectedCity = useState<String?>(null);
    final selectedChannel = useState<String?>(null);
    final startDate = useState<DateTime?>(null);
    final endDate = useState<DateTime?>(null);

    final hasFilters = selectedCity.value != null ||
        selectedChannel.value != null ||
        startDate.value != null ||
        endDate.value != null;

    // Build filter params
    final filterParams = WidgetFilterParams(
      missionId: missionId,
      city: selectedCity.value,
      channel: selectedChannel.value,
      startDate: startDate.value,
      endDate: endDate.value,
    );

    // Watch data with filter params
    final overviewAsync = ref.watch(missionOverviewForWidgetProvider(filterParams));
    final cityBreakdownAsync = ref.watch(cityBreakdownForWidgetProvider(filterParams));
    final channelBreakdownAsync = ref.watch(channelBreakdownForWidgetProvider(filterParams));

    // Roll city counts up into regions, reconciled against the visits total so
    // the pie always sums to the headline number.
    final regionBreakdownAsync = cityBreakdownAsync.whenData(
      (cities) => _toRegionBreakdown(
        cities,
        overviewAsync.valueOrNull?.totalSubmissions,
      ),
    );

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
              Icon(Icons.dashboard, color: AdminColors.primary, size: 24),
              const SizedBox(width: AdminSpacing.sm),
              Text(title, style: AdminTextStyles.sectionTitle),
            ],
          ),

          const SizedBox(height: AdminSpacing.md),

          // Filters row
          WidgetFiltersRow(
            missionId: missionId,
            selectedCity: selectedCity.value,
            selectedChannel: selectedChannel.value,
            startDate: startDate.value,
            endDate: endDate.value,
            hasFilters: hasFilters,
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

          const SizedBox(height: AdminSpacing.xl),

          // Counters Row
          overviewAsync.when(
            loading: () => _buildCountersRow(null, loading: true),
            error: (e, _) => _buildCountersRow(null, error: e.toString()),
            data: (data) => _buildCountersRow(data),
          ),

          const SizedBox(height: AdminSpacing.xl),

          // Pie Charts Row
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // Region Breakdown
                Expanded(
                  child: _buildPieChartSection(
                    title: 'By Region',
                    dataAsync: regionBreakdownAsync,
                    colorFor: _regionColor,
                  ),
                ),
                const SizedBox(width: AdminSpacing.lg),
                // Channel Breakdown
                Expanded(
                  child: _buildPieChartSection(
                    title: 'By Channel',
                    dataAsync: channelBreakdownAsync,
                    colorFor: (_, index) =>
                        _channelColors[index % _channelColors.length],
                  ),
                ),
              ],
            ),
          ),

          // Subtitle (if provided)
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

  Widget _buildCountersRow(MissionOverviewData? data,
      {bool loading = false, String? error}) {
    String formatValue(int? val) {
      if (val == null) return '---';
      if (val >= 1000000) return '${(val / 1000000).toStringAsFixed(1)}M';
      if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
      return val.toString();
    }

    return AdminStatCardRow(
      cards: [
        AdminStatCard(
          title: 'Total Visits',
          value: formatValue(data?.totalSubmissions),
          icon: Icons.location_on_outlined,
          accentColor: const Color(0xFF2196F3),
          isLoading: loading,
          subtitle: error,
        ),
        AdminStatCard(
          title: 'Cities Covered',
          value: formatValue(data?.citiesCount),
          icon: Icons.location_city_outlined,
          accentColor: const Color(0xFF4CAF50),
          isLoading: loading,
        ),
        AdminStatCard(
          title: 'Channel Types',
          value: formatValue(data?.locationTypesCount),
          icon: Icons.storefront_outlined,
          accentColor: const Color(0xFFFF9800),
          isLoading: loading,
        ),
      ],
    );
  }

  Widget _buildPieChartSection({
    required String title,
    required AsyncValue<List<ChartDataPoint>> dataAsync,
    required Color Function(String label, int index) colorFor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: BoxDecoration(
        color: AdminColors.backgroundHover,
        borderRadius: AdminRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AdminTextStyles.labelMedium),
          const SizedBox(height: AdminSpacing.sm),
          Expanded(
            child: dataAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Center(
                child: Icon(Icons.error_outline, color: AdminColors.error),
              ),
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Text('No data',
                        style: AdminTextStyles.bodySmall
                            .copyWith(color: AdminColors.textMuted)),
                  );
                }
                return Row(
                  children: [
                    // Pie Chart
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 20,
                          sections: _buildPieSections(data, colorFor),
                        ),
                      ),
                    ),
                    const SizedBox(width: AdminSpacing.sm),
                    // Legend
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: data.asMap().entries.map((entry) {
                            final index = entry.key;
                            final point = entry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colorFor(point.label, index),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      point.label,
                                      style: AdminTextStyles.labelSmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    point.value.toInt().toString(),
                                    style: AdminTextStyles.labelSmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
      List<ChartDataPoint> data, Color Function(String label, int index) colorFor) {
    final total = data.fold<double>(0, (sum, e) => sum + e.value);
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      final percentage = total > 0 ? (point.value / total * 100) : 0;
      return PieChartSectionData(
        color: colorFor(point.label, index),
        value: point.value,
        title: percentage > 10 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 35,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  static const _unspecifiedLabel = 'Unspecified';

  /// Rolls per-city counts up into regions (via CITIES constants). Visits with
  /// no recorded city still count toward the visits total, so the difference
  /// is surfaced as an "Unspecified" slice instead of silently under-summing.
  static List<ChartDataPoint> _toRegionBreakdown(
      List<ChartDataPoint> cities, int? totalVisits) {
    final regionCounts = <String, double>{};
    for (final city in cities) {
      final region = (cityInfoFor(city.label)?['region'] as String?) ?? 'Other';
      regionCounts[region] = (regionCounts[region] ?? 0) + city.value;
    }

    final points = regionCounts.entries
        .map((e) => ChartDataPoint(label: e.key, value: e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (totalVisits != null) {
      final counted = points.fold<double>(0, (sum, p) => sum + p.value);
      final unspecified = totalVisits - counted;
      if (unspecified > 0) {
        points.add(ChartDataPoint(label: _unspecifiedLabel, value: unspecified));
      }
    }
    return points;
  }

  static Color _regionColor(String label, int index) {
    if (label == _unspecifiedLabel) return const Color(0xFFBDBDBD);
    return regionColorFor(label);
  }

  static const _channelColors = [
    Color(0xFFFF9800),
    Color(0xFFFF5722),
    Color(0xFFF44336),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
  ];
}
