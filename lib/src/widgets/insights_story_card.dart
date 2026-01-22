import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_shadows.dart';

/// Story card for displaying insights (wins, alerts, etc.)
/// 
/// Used in the "What Went Well" and "Needs Attention" sections
class InsightsStoryCard extends StatelessWidget {
  final InsightsStoryType type;
  final String title;
  final String description;
  final Widget? visualization;
  final List<String>? bulletPoints;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  const InsightsStoryCard({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    this.visualization,
    this.bulletPoints,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: AdminColors.backgroundCard,
        borderRadius: AdminRadius.lgAll,
        boxShadow: AdminShadows.sm,
        border: Border(
          left: BorderSide(
            color: _getTypeColor(),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.all(AdminSpacing.sm),
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.1),
                  borderRadius: AdminRadius.smAll,
                ),
                child: Icon(
                  icon ?? _getTypeIcon(),
                  color: _getTypeColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: AdminSpacing.md),
              
              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AdminTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AdminSpacing.xs),
                    Text(
                      description,
                      style: AdminTextStyles.bodyMedium.copyWith(
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Divider
          if (visualization != null || bulletPoints != null) ...[
            const SizedBox(height: AdminSpacing.md),
            Divider(color: AdminColors.divider.withOpacity(0.5)),
            const SizedBox(height: AdminSpacing.md),
          ],
          
          // Visualization
          if (visualization != null) ...[
            visualization!,
            const SizedBox(height: AdminSpacing.md),
          ],
          
          // Bullet points
          if (bulletPoints != null && bulletPoints!.isNotEmpty) ...[
            ...bulletPoints!.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: AdminSpacing.sm),
                    decoration: BoxDecoration(
                      color: _getTypeColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: AdminTextStyles.bodySmall.copyWith(
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          
          // Action button
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AdminSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: _getTypeColor(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AdminSpacing.md,
                    vertical: AdminSpacing.sm,
                  ),
                ),
                icon: Text(
                  actionLabel!,
                  style: AdminTextStyles.labelMedium.copyWith(
                    color: _getTypeColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                label: Icon(Icons.arrow_forward_rounded, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (type) {
      case InsightsStoryType.win:
        return AdminColors.success;
      case InsightsStoryType.critical:
        return AdminColors.error;
      case InsightsStoryType.warning:
        return AdminColors.warning;
      case InsightsStoryType.info:
        return AdminColors.info;
    }
  }

  IconData _getTypeIcon() {
    switch (type) {
      case InsightsStoryType.win:
        return Icons.check_circle_rounded;
      case InsightsStoryType.critical:
        return Icons.error_rounded;
      case InsightsStoryType.warning:
        return Icons.warning_rounded;
      case InsightsStoryType.info:
        return Icons.info_rounded;
    }
  }
}

/// Types of story cards
enum InsightsStoryType {
  win,
  critical,
  warning,
  info,
}

/// Section container for story cards (Wins / Needs Attention)
class InsightsStorySection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color? accentColor;
  final List<InsightsStoryCard> cards;
  final bool initiallyExpanded;
  final bool showHideButton;

  const InsightsStorySection({
    super.key,
    required this.title,
    required this.icon,
    this.accentColor,
    required this.cards,
    this.initiallyExpanded = true,
    this.showHideButton = true,
  });

  @override
  State<InsightsStorySection> createState() => _InsightsStorySectionState();
}

class _InsightsStorySectionState extends State<InsightsStorySection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? AdminColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(widget.icon, color: color, size: 24),
            const SizedBox(width: AdminSpacing.sm),
            Text(
              widget.title,
              style: AdminTextStyles.sectionTitle,
            ),
            const Spacer(),
            if (widget.showHideButton)
              TextButton.icon(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                style: TextButton.styleFrom(
                  foregroundColor: AdminColors.textMuted,
                ),
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(_isExpanded ? 'Hide' : 'Show'),
              ),
          ],
        ),
        
        const SizedBox(height: AdminSpacing.md),
        
        // Cards
        AnimatedCrossFade(
          firstChild: Column(
            children: widget.cards.map((card) => Padding(
              padding: const EdgeInsets.only(bottom: AdminSpacing.md),
              child: card,
            )).toList(),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

/// Mini visualization for story cards - Sparkline
class InsightsSparkline extends StatelessWidget {
  final List<double> data;
  final Color? color;
  final double height;
  final bool showDots;

  const InsightsSparkline({
    super.key,
    required this.data,
    this.color,
    this.height = 40,
    this.showDots = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _SparklinePainter(
          data: data,
          color: color ?? AdminColors.primary,
          showDots: showDots,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool showDots;

  _SparklinePainter({
    required this.data,
    required this.color,
    required this.showDots,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final normalizedY = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedY * size.height * 0.8 + size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw fill
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    canvas.drawPath(path, paint);

    // Draw dots
    if (showDots) {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (int i = 0; i < data.length; i++) {
        final x = i * size.width / (data.length - 1);
        final normalizedY = range > 0 ? (data[i] - minValue) / range : 0.5;
        final y = size.height - (normalizedY * size.height * 0.8 + size.height * 0.1);
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

/// Mini bar chart for story cards
class InsightsMiniBarChart extends StatelessWidget {
  final Map<String, double> data;
  final Color? color;
  final double height;
  final double barWidth;

  const InsightsMiniBarChart({
    super.key,
    required this.data,
    this.color,
    this.height = 60,
    this.barWidth = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    final barColor = color ?? AdminColors.primary;

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.entries.map((entry) {
          final heightFraction = maxValue > 0 ? entry.value / maxValue : 0;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: barWidth,
                height: (height - 20) * heightFraction,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.key,
                style: AdminTextStyles.labelSmall.copyWith(
                  color: AdminColors.textMuted,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// Progress indicator for story cards
class InsightsProgressIndicator extends StatelessWidget {
  final double value;
  final double target;
  final String label;
  final Color? color;

  const InsightsProgressIndicator({
    super.key,
    required this.value,
    required this.target,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    final barColor = color ?? AdminColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AdminTextStyles.labelMedium,
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              style: AdminTextStyles.labelMedium.copyWith(
                color: barColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.xs),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: barColor.withOpacity(0.15),
            borderRadius: AdminRadius.fullAll,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: AdminRadius.fullAll,
              ),
            ),
          ),
        ),
        const SizedBox(height: AdminSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Actual: ${value.toStringAsFixed(0)}%',
              style: AdminTextStyles.labelSmall.copyWith(
                color: AdminColors.textMuted,
              ),
            ),
            Text(
              'Target: ${target.toStringAsFixed(0)}%',
              style: AdminTextStyles.labelSmall.copyWith(
                color: AdminColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

