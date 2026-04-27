import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Data point for animated line chart
class LineChartDataPoint {
  final String label;
  final double value;
  final double? minValue;
  final double? maxValue;
  final double? referenceValue;

  const LineChartDataPoint({
    required this.label,
    required this.value,
    this.minValue,
    this.maxValue,
    this.referenceValue,
  });
}

/// Animated line chart with time-lapse capability
/// 
/// Features:
/// - Progressive animation that draws the line over time
/// - Optional min/max range band
/// - Optional reference line (e.g., factory price)
/// - Optional overlay line for highlighted data
class AnimatedLineChart extends StatefulWidget {
  final List<LineChartDataPoint> data;
  final List<LineChartDataPoint>? overlayData;
  final Color lineColor;
  final Color? overlayColor;
  final Color? referenceColor;
  final Color? rangeColor;
  final double? referenceValue;
  final String? referenceLabel;
  final bool showRange;
  final bool animate;
  final Duration animationDuration;
  final VoidCallback? onAnimationComplete;
  final String? yAxisLabel;
  final String? xAxisLabel;
  final double height;

  const AnimatedLineChart({
    super.key,
    required this.data,
    this.overlayData,
    this.lineColor = const Color(0xFF2196F3),
    this.overlayColor,
    this.referenceColor,
    this.rangeColor,
    this.referenceValue,
    this.referenceLabel,
    this.showRange = true,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 2000),
    this.onAnimationComplete,
    this.yAxisLabel,
    this.xAxisLabel,
    this.height = 200,
  });

  @override
  State<AnimatedLineChart> createState() => AnimatedLineChartState();
}

class AnimatedLineChartState extends State<AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });
    
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if data changed significantly (category/date range change)
    if (oldWidget.data.length != widget.data.length ||
        (oldWidget.data.isNotEmpty && widget.data.isNotEmpty &&
         oldWidget.data.first.label != widget.data.first.label)) {
      if (widget.animate) {
        _controller.reset();
        _controller.forward();
      }
    }
  }

  /// Public method to replay animation
  void replay() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: _buildChart(),
        );
      },
    );
  }

  Widget _buildChart() {
    final visibleCount = (_animation.value * widget.data.length).ceil();
    final visibleData = widget.data.take(visibleCount).toList();
    
    if (visibleData.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate Y range
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    
    for (final point in widget.data) {
      final low = point.minValue ?? point.value;
      final high = point.maxValue ?? point.value;
      if (low < minY) minY = low;
      if (high > maxY) maxY = high;
    }
    
    if (widget.referenceValue != null) {
      if (widget.referenceValue! < minY) minY = widget.referenceValue!;
      if (widget.referenceValue! > maxY) maxY = widget.referenceValue!;
    }
    
    // Add padding
    final range = maxY - minY;
    minY -= range * 0.1;
    maxY += range * 0.1;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: widget.yAxisLabel != null
                ? Text(
                    widget.yAxisLabel!,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  )
                : null,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: widget.xAxisLabel != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.xAxisLabel!,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  )
                : null,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: widget.data.length > 8 ? 2 : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= widget.data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.data[index].label,
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: widget.referenceValue != null
            ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: widget.referenceValue!,
                    color: widget.referenceColor ?? Colors.orange,
                    strokeWidth: 2,
                    dashArray: [8, 4],
                    label: HorizontalLineLabel(
                      show: widget.referenceLabel != null,
                      alignment: Alignment.topRight,
                      labelResolver: (_) => widget.referenceLabel ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.referenceColor ?? Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
            : null,
        lineBarsData: _buildLineBars(visibleData),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final dataIndex = spot.x.toInt();
                final point = widget.data[dataIndex];
                String text = '${point.value.toStringAsFixed(2)}';
                if (point.minValue != null && point.maxValue != null) {
                  text += '\nRange: ${point.minValue!.toStringAsFixed(1)} - ${point.maxValue!.toStringAsFixed(1)}';
                }
                return LineTooltipItem(
                  text,
                  TextStyle(
                    color: spot.bar.color ?? widget.lineColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBars(List<LineChartDataPoint> visibleData) {
    final bars = <LineChartBarData>[];

    // Min/Max range area (if enabled)
    if (widget.showRange && visibleData.any((p) => p.minValue != null && p.maxValue != null)) {
      bars.add(LineChartBarData(
        spots: visibleData.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.maxValue ?? e.value.value);
        }).toList(),
        isCurved: true,
        color: Colors.transparent,
        barWidth: 0,
        belowBarData: BarAreaData(
          show: true,
          color: (widget.rangeColor ?? widget.lineColor).withOpacity(0.1),
          cutOffY: visibleData.map((p) => p.minValue ?? p.value).reduce((a, b) => a < b ? a : b),
          applyCutOffY: true,
        ),
        dotData: const FlDotData(show: false),
      ));
    }

    // Main line
    bars.add(LineChartBarData(
      spots: visibleData.asMap().entries.map((e) {
        return FlSpot(e.key.toDouble(), e.value.value);
      }).toList(),
      isCurved: true,
      curveSmoothness: 0.3,
      color: widget.lineColor,
      barWidth: 3,
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            widget.lineColor.withOpacity(0.3),
            widget.lineColor.withOpacity(0.0),
          ],
        ),
      ),
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) {
          // Only show dot on last point during animation
          if (index == visibleData.length - 1) {
            return FlDotCirclePainter(
              radius: 4,
              color: widget.lineColor,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          }
          return FlDotCirclePainter(
            radius: 0,
            color: Colors.transparent,
            strokeWidth: 0,
            strokeColor: Colors.transparent,
          );
        },
      ),
    ));

    // Overlay line (e.g., highlighted SKU)
    if (widget.overlayData != null && widget.overlayData!.isNotEmpty) {
      final visibleOverlay = widget.overlayData!.take(visibleData.length).toList();
      if (visibleOverlay.isNotEmpty) {
        bars.add(LineChartBarData(
          spots: visibleOverlay.asMap().entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value.value);
          }).toList(),
          isCurved: true,
          curveSmoothness: 0.3,
          color: widget.overlayColor ?? Colors.purple,
          barWidth: 2,
          dashArray: [4, 2],
          belowBarData: BarAreaData(show: false),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              if (index == visibleOverlay.length - 1) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: widget.overlayColor ?? Colors.purple,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              }
              return FlDotCirclePainter(
                radius: 0,
                color: Colors.transparent,
                strokeWidth: 0,
                strokeColor: Colors.transparent,
              );
            },
          ),
        ));
      }
    }

    return bars;
  }
}
