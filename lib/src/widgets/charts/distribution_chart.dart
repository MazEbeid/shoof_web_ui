import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Box plot statistics
class BoxPlotStats {
  final double min;
  final double q1;
  final double median;
  final double q3;
  final double max;
  final double mean;
  final List<double> outliers;

  const BoxPlotStats({
    required this.min,
    required this.q1,
    required this.median,
    required this.q3,
    required this.max,
    required this.mean,
    this.outliers = const [],
  });

  factory BoxPlotStats.fromData(List<double> data) {
    if (data.isEmpty) {
      return const BoxPlotStats(
        min: 0,
        q1: 0,
        median: 0,
        q3: 0,
        max: 0,
        mean: 0,
      );
    }

    final sorted = List<double>.from(data)..sort();
    final n = sorted.length;

    double percentile(double p) {
      final index = p * (n - 1);
      final lower = sorted[index.floor()];
      final upper = sorted[index.ceil()];
      return lower + (upper - lower) * (index - index.floor());
    }

    final q1 = percentile(0.25);
    final median = percentile(0.5);
    final q3 = percentile(0.75);
    final iqr = q3 - q1;
    final lowerFence = q1 - 1.5 * iqr;
    final upperFence = q3 + 1.5 * iqr;

    final outliers = sorted.where((v) => v < lowerFence || v > upperFence).toList();
    final nonOutliers = sorted.where((v) => v >= lowerFence && v <= upperFence).toList();

    return BoxPlotStats(
      min: nonOutliers.isNotEmpty ? nonOutliers.first : sorted.first,
      q1: q1,
      median: median,
      q3: q3,
      max: nonOutliers.isNotEmpty ? nonOutliers.last : sorted.last,
      mean: data.reduce((a, b) => a + b) / n,
      outliers: outliers,
    );
  }
}

/// Distribution chart showing histogram or box plot visualization
class DistributionChart extends StatelessWidget {
  final List<double> data;
  final String title;
  final String? subtitle;
  final String xAxisLabel;
  final Color color;
  final double? referenceValue;
  final String? referenceLabel;
  final Color referenceColor;
  final double height;
  final int binCount;
  final bool showBoxPlot;
  final bool showHistogram;

  const DistributionChart({
    super.key,
    required this.data,
    this.title = '',
    this.subtitle,
    this.xAxisLabel = 'Value',
    this.color = const Color(0xFF2196F3),
    this.referenceValue,
    this.referenceLabel,
    this.referenceColor = const Color(0xFFFF9800),
    this.height = 180,
    this.binCount = 15,
    this.showBoxPlot = true,
    this.showHistogram = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final stats = BoxPlotStats.fromData(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 12),
        ],

        // Box plot (if enabled)
        if (showBoxPlot) ...[
          _buildBoxPlot(stats),
          const SizedBox(height: 16),
        ],

        // Histogram
        if (showHistogram)
          SizedBox(
            height: height,
            child: _buildHistogram(stats),
          ),

        // Stats summary
        const SizedBox(height: 12),
        _buildStatsSummary(stats),
      ],
    );
  }

  Widget _buildBoxPlot(BoxPlotStats stats) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final minVal = stats.min - (stats.max - stats.min) * 0.1;
          final maxVal = stats.max + (stats.max - stats.min) * 0.1;
          final range = maxVal - minVal;

          double xForValue(double v) {
            return ((v - minVal) / range) * width;
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              // Whisker line
              Positioned(
                left: xForValue(stats.min),
                right: width - xForValue(stats.max),
                child: Container(
                  height: 2,
                  color: color.withOpacity(0.5),
                ),
              ),

              // Min whisker cap
              Positioned(
                left: xForValue(stats.min) - 0.5,
                child: Container(
                  width: 1,
                  height: 16,
                  color: color.withOpacity(0.5),
                ),
              ),

              // Max whisker cap
              Positioned(
                left: xForValue(stats.max) - 0.5,
                child: Container(
                  width: 1,
                  height: 16,
                  color: color.withOpacity(0.5),
                ),
              ),

              // IQR box
              Positioned(
                left: xForValue(stats.q1),
                width: xForValue(stats.q3) - xForValue(stats.q1),
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.3),
                    border: Border.all(color: color, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Median line
              Positioned(
                left: xForValue(stats.median) - 1,
                child: Container(
                  width: 2,
                  height: 28,
                  color: color,
                ),
              ),

              // Mean marker
              Positioned(
                left: xForValue(stats.mean) - 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: color, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Reference line
              if (referenceValue != null)
                Positioned(
                  left: xForValue(referenceValue!) - 1,
                  child: Container(
                    width: 2,
                    height: 40,
                    color: referenceColor,
                  ),
                ),

              // Outliers
              ...stats.outliers.map((o) {
                return Positioned(
                  left: xForValue(o) - 3,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistogram(BoxPlotStats stats) {
    // Create bins
    final minVal = data.reduce(math.min);
    final maxVal = data.reduce(math.max);
    final binWidth = (maxVal - minVal) / binCount;

    final bins = List<int>.filled(binCount, 0);
    for (final value in data) {
      final binIndex = ((value - minVal) / binWidth).floor().clamp(0, binCount - 1);
      bins[binIndex]++;
    }

    final maxBinCount = bins.reduce(math.max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxBinCount.toDouble() * 1.1,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final binStart = minVal + groupIndex * binWidth;
              final binEnd = binStart + binWidth;
              return BarTooltipItem(
                '${binStart.toStringAsFixed(1)} - ${binEnd.toStringAsFixed(1)}\n${bins[groupIndex]} observations',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value == meta.max) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                xAxisLabel,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (binCount / 5).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final binIndex = value.toInt();
                if (binIndex < 0 || binIndex >= binCount) {
                  return const SizedBox.shrink();
                }
                final binCenter = minVal + (binIndex + 0.5) * binWidth;
                return Text(
                  binCenter.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxBinCount / 4).ceilToDouble(),
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: referenceValue != null
            ? ExtraLinesData(
                verticalLines: [
                  VerticalLine(
                    x: ((referenceValue! - minVal) / binWidth).clamp(0, binCount - 1).toDouble(),
                    color: referenceColor,
                    strokeWidth: 2,
                    dashArray: [6, 3],
                    label: VerticalLineLabel(
                      show: referenceLabel != null,
                      alignment: Alignment.topCenter,
                      labelResolver: (_) => referenceLabel ?? '',
                      style: TextStyle(
                        fontSize: 9,
                        color: referenceColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
            : null,
        barGroups: bins.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: color.withOpacity(0.8),
                width: 800 / binCount - 2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsSummary(BoxPlotStats stats) {
    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: [
        _buildStatItem('Min', stats.min),
        _buildStatItem('Q1', stats.q1),
        _buildStatItem('Median', stats.median),
        _buildStatItem('Q3', stats.q3),
        _buildStatItem('Max', stats.max),
        _buildStatItem('Mean', stats.mean),
        if (stats.outliers.isNotEmpty)
          _buildStatItem('Outliers', stats.outliers.length.toDouble(), isCount: true),
      ],
    );
  }

  Widget _buildStatItem(String label, double value, {bool isCount = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        Text(
          isCount ? value.toInt().toString() : value.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
