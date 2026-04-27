import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Compliance breakdown data
class ComplianceData {
  final int aboveCount;
  final int withinCount;
  final int belowCount;
  
  int get total => aboveCount + withinCount + belowCount;
  double get abovePercent => total > 0 ? aboveCount / total * 100 : 0;
  double get withinPercent => total > 0 ? withinCount / total * 100 : 0;
  double get belowPercent => total > 0 ? belowCount / total * 100 : 0;

  const ComplianceData({
    required this.aboveCount,
    required this.withinCount,
    required this.belowCount,
  });
}

/// Donut chart showing compliance breakdown (above/within/below factory price)
class ComplianceDonut extends StatelessWidget {
  final ComplianceData data;
  final Color aboveColor;
  final Color withinColor;
  final Color belowColor;
  final double size;
  final bool showLegend;
  final bool showCenterLabel;
  final String? centerLabel;
  final double tolerancePercent;

  const ComplianceDonut({
    super.key,
    required this.data,
    this.aboveColor = const Color(0xFFE53935),
    this.withinColor = const Color(0xFF43A047),
    this.belowColor = const Color(0xFF1E88E5),
    this.size = 150,
    this.showLegend = true,
    this.showCenterLabel = true,
    this.centerLabel,
    this.tolerancePercent = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (data.total == 0) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Text(
            'No data',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Donut chart
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: size * 0.3,
                  sections: _buildSections(),
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      // Could add interaction here
                    },
                  ),
                ),
              ),
              if (showCenterLabel)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${data.withinPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: size * 0.15,
                        fontWeight: FontWeight.bold,
                        color: withinColor,
                      ),
                    ),
                    Text(
                      centerLabel ?? 'Compliant',
                      style: TextStyle(
                        fontSize: size * 0.08,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        
        // Legend
        if (showLegend) ...[
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(
                color: aboveColor,
                label: 'Above factory (>${tolerancePercent.toStringAsFixed(0)}%)',
                count: data.aboveCount,
                percent: data.abovePercent,
              ),
              const SizedBox(height: 8),
              _buildLegendItem(
                color: withinColor,
                label: 'Within tolerance (±${tolerancePercent.toStringAsFixed(0)}%)',
                count: data.withinCount,
                percent: data.withinPercent,
              ),
              const SizedBox(height: 8),
              _buildLegendItem(
                color: belowColor,
                label: 'Below factory (<-${tolerancePercent.toStringAsFixed(0)}%)',
                count: data.belowCount,
                percent: data.belowPercent,
              ),
            ],
          ),
        ],
      ],
    );
  }

  List<PieChartSectionData> _buildSections() {
    final sections = <PieChartSectionData>[];
    
    if (data.aboveCount > 0) {
      sections.add(PieChartSectionData(
        value: data.aboveCount.toDouble(),
        color: aboveColor,
        title: data.abovePercent > 10 ? '${data.abovePercent.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: size * 0.2,
      ));
    }
    
    if (data.withinCount > 0) {
      sections.add(PieChartSectionData(
        value: data.withinCount.toDouble(),
        color: withinColor,
        title: data.withinPercent > 10 ? '${data.withinPercent.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: size * 0.2,
      ));
    }
    
    if (data.belowCount > 0) {
      sections.add(PieChartSectionData(
        value: data.belowCount.toDouble(),
        color: belowColor,
        title: data.belowPercent > 10 ? '${data.belowPercent.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        radius: size * 0.2,
      ));
    }
    
    return sections;
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int count,
    required double percent,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
              ),
            ),
            Text(
              '$count locations (${percent.toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
