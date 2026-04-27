import 'package:flutter/material.dart';

/// Data point for heatmap
class HeatmapDataPoint {
  final String label;
  final double value;
  final int count;
  final double? secondaryValue;

  const HeatmapDataPoint({
    required this.label,
    required this.value,
    this.count = 0,
    this.secondaryValue,
  });
}

/// Horizontal bar heatmap for visualizing data by category (e.g., city, channel)
/// 
/// Colors are mapped from value to a gradient (green = good, red = bad)
class PriceHeatmap extends StatelessWidget {
  final List<HeatmapDataPoint> data;
  final String title;
  final String? subtitle;
  final String valueLabel;
  final String? countLabel;
  final bool showCount;
  final bool sortDescending;
  final double minValue;
  final double maxValue;
  final Color lowColor;
  final Color midColor;
  final Color highColor;
  final double height;
  final ValueChanged<HeatmapDataPoint>? onItemTap;

  const PriceHeatmap({
    super.key,
    required this.data,
    this.title = '',
    this.subtitle,
    this.valueLabel = 'Markup',
    this.countLabel,
    this.showCount = true,
    this.sortDescending = true,
    this.minValue = -10,
    this.maxValue = 20,
    this.lowColor = const Color(0xFF43A047),
    this.midColor = const Color(0xFFFDD835),
    this.highColor = const Color(0xFFE53935),
    this.height = 300,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final sortedData = List<HeatmapDataPoint>.from(data);
    if (sortDescending) {
      sortedData.sort((a, b) => b.value.compareTo(a.value));
    } else {
      sortedData.sort((a, b) => a.value.compareTo(b.value));
    }

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
        
        // Header row
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              const SizedBox(width: 100),
              const Spacer(),
              SizedBox(
                width: 60,
                child: Text(
                  valueLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              if (showCount && countLabel != null)
                SizedBox(
                  width: 50,
                  child: Text(
                    countLabel!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
            ],
          ),
        ),
        
        // Heatmap rows
        SizedBox(
          height: height,
          child: ListView.builder(
            itemCount: sortedData.length,
            itemBuilder: (context, index) {
              final point = sortedData[index];
              return _buildRow(point, index);
            },
          ),
        ),
        
        // Legend
        const SizedBox(height: 12),
        _buildLegend(),
      ],
    );
  }

  Widget _buildRow(HeatmapDataPoint point, int index) {
    final color = _getColorForValue(point.value);
    final barWidth = _getBarWidth(point.value);
    
    return InkWell(
      onTap: onItemTap != null ? () => onItemTap!(point) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: index.isEven ? Colors.grey.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            // Label
            SizedBox(
              width: 96,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Bar
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Stack(
                  children: [
                    // Background
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Center line (zero point)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 1,
                          color: Colors.grey.withOpacity(0.4),
                        ),
                      ),
                    ),
                    // Bar
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final center = constraints.maxWidth / 2;
                        final barMaxWidth = center;
                        final actualWidth = barMaxWidth * barWidth;
                        
                        return Positioned(
                          left: point.value >= 0 ? center : center - actualWidth,
                          width: actualWidth,
                          top: 2,
                          bottom: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Value
            SizedBox(
              width: 60,
              child: Text(
                '${point.value >= 0 ? '+' : ''}${point.value.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            
            // Count
            if (showCount)
              SizedBox(
                width: 50,
                child: Text(
                  '${point.count}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(lowColor, 'Below'),
        const SizedBox(width: 16),
        Container(
          width: 100,
          height: 8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [lowColor, midColor, highColor],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 16),
        _buildLegendItem(highColor, 'Above'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getColorForValue(double value) {
    // Normalize value to 0-1 range
    final normalized = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
    
    if (normalized < 0.5) {
      // Blend from low to mid
      final t = normalized * 2;
      return Color.lerp(lowColor, midColor, t)!;
    } else {
      // Blend from mid to high
      final t = (normalized - 0.5) * 2;
      return Color.lerp(midColor, highColor, t)!;
    }
  }

  double _getBarWidth(double value) {
    // Map value to bar width (0-1)
    final absValue = value.abs();
    final maxAbs = (maxValue - minValue).abs() / 2;
    return (absValue / maxAbs).clamp(0.0, 1.0);
  }
}
