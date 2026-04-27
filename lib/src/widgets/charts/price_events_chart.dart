import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Price change event data point
class PriceEventData {
  final String label;
  final int weekNumber;
  final int increaseCount;
  final int decreaseCount;

  const PriceEventData({
    required this.label,
    required this.weekNumber,
    required this.increaseCount,
    required this.decreaseCount,
  });

  int get total => increaseCount + decreaseCount;
}

/// Bar chart showing price change events over time
class PriceEventsChart extends StatelessWidget {
  final List<PriceEventData> data;
  final String title;
  final String? subtitle;
  final Color increaseColor;
  final Color decreaseColor;
  final double height;
  final double thresholdPercent;

  const PriceEventsChart({
    super.key,
    required this.data,
    this.title = '',
    this.subtitle,
    this.increaseColor = const Color(0xFFE53935),
    this.decreaseColor = const Color(0xFF43A047),
    this.height = 180,
    this.thresholdPercent = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'No price change events',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final maxCount = data.map((d) => d.increaseCount > d.decreaseCount 
        ? d.increaseCount 
        : d.decreaseCount).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              _buildLegend(),
            ],
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

        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxCount.toDouble() * 1.1,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final event = data[groupIndex];
                    final isIncrease = rodIndex == 0;
                    return BarTooltipItem(
                      '${event.label}\n${isIncrease ? '↑' : '↓'} ${isIncrease ? event.increaseCount : event.decreaseCount} SKUs',
                      TextStyle(
                        color: isIncrease ? increaseColor : decreaseColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          data[index].label,
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
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
                horizontalInterval: (maxCount / 4).ceilToDouble().clamp(1, double.infinity),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                final index = entry.key;
                final event = entry.value;
                final barWidth = 300 / data.length / 3;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    // Increase bar
                    BarChartRodData(
                      toY: event.increaseCount.toDouble(),
                      color: increaseColor,
                      width: barWidth.clamp(8, 20),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    // Decrease bar
                    BarChartRodData(
                      toY: event.decreaseCount.toDouble(),
                      color: decreaseColor,
                      width: barWidth.clamp(8, 20),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: increaseColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '↑ >${thresholdPercent.toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: decreaseColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '↓ <-${thresholdPercent.toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
