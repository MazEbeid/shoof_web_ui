import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_shadows.dart';

/// Circular health score card with animated progress ring
/// 
/// Displays a score out of 100 with trend indicator
class InsightsHealthScore extends StatefulWidget {
  final String label;
  final int score;
  final int? previousScore;
  final Color? color;
  final VoidCallback? onTap;
  final bool animate;

  const InsightsHealthScore({
    super.key,
    required this.label,
    required this.score,
    this.previousScore,
    this.color,
    this.onTap,
    this.animate = true,
  });

  @override
  State<InsightsHealthScore> createState() => _InsightsHealthScoreState();
}

class _InsightsHealthScoreState extends State<InsightsHealthScore>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<int> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _countAnimation = IntTween(
      begin: 0,
      end: widget.score,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(InsightsHealthScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.score / 100,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _countAnimation = IntTween(
        begin: _countAnimation.value,
        end: widget.score,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _scoreColor {
    if (widget.color != null) return widget.color!;
    if (widget.score >= 80) return AdminColors.success;
    if (widget.score >= 60) return AdminColors.warning;
    return AdminColors.error;
  }

  int? get _scoreDiff {
    if (widget.previousScore == null) return null;
    return widget.score - widget.previousScore!;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AdminRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          decoration: BoxDecoration(
            color: AdminColors.backgroundCard,
            borderRadius: AdminRadius.lgAll,
            boxShadow: AdminShadows.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Score ring
              SizedBox(
                width: 100,
                height: 100,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ScoreRingPainter(
                        progress: _progressAnimation.value,
                        color: _scoreColor,
                        backgroundColor: _scoreColor.withOpacity(0.15),
                        strokeWidth: 8,
                      ),
                      child: Center(
                        child: Text(
                          '${_countAnimation.value}',
                          style: AdminTextStyles.statMedium.copyWith(
                            color: _scoreColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AdminSpacing.md),

              // Progress bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: _scoreColor.withOpacity(0.15),
                  borderRadius: AdminRadius.fullAll,
                ),
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progressAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _scoreColor,
                          borderRadius: AdminRadius.fullAll,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: AdminSpacing.md),

              // Label
              Text(
                widget.label.toUpperCase(),
                style: AdminTextStyles.labelMedium.copyWith(
                  color: AdminColors.textSecondary,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AdminSpacing.xs),

              Text(
                'HEALTH',
                style: AdminTextStyles.labelSmall.copyWith(
                  color: AdminColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),

              // Trend indicator
              if (_scoreDiff != null) ...[
                const SizedBox(height: AdminSpacing.sm),
                _buildTrendIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator() {
    final diff = _scoreDiff!;
    final isUp = diff > 0;
    final isNeutral = diff == 0;

    Color trendColor;
    IconData trendIcon;
    String trendText;

    if (isNeutral) {
      trendColor = AdminColors.textMuted;
      trendIcon = Icons.remove;
      trendText = 'No change';
    } else if (isUp) {
      trendColor = AdminColors.success;
      trendIcon = Icons.arrow_upward_rounded;
      trendText = '+$diff vs last week';
    } else {
      trendColor = AdminColors.error;
      trendIcon = Icons.arrow_downward_rounded;
      trendText = '$diff vs last week';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.sm,
        vertical: AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: AdminRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trendIcon, size: 12, color: trendColor),
          const SizedBox(width: 2),
          Text(
            trendText,
            style: AdminTextStyles.labelSmall.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the score ring
class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _ScoreRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.strokeWidth = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Row of health score cards
class InsightsHealthScoreRow extends StatelessWidget {
  final List<InsightsHealthScore> scores;
  final int? overallScore;
  final int? previousOverallScore;

  const InsightsHealthScoreRow({
    super.key,
    required this.scores,
    this.overallScore,
    this.previousOverallScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: AdminColors.backgroundCard,
        borderRadius: AdminRadius.lgAll,
        boxShadow: AdminShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'YOUR BUSINESS HEALTH',
                style: AdminTextStyles.labelMedium.copyWith(
                  color: AdminColors.textSecondary,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AdminColors.textMuted,
              ),
            ],
          ),

          const SizedBox(height: AdminSpacing.xl),

          // Score cards
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - AdminSpacing.lg * 2) / 3;
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: scores.map((score) {
                  return SizedBox(
                    width: cardWidth.clamp(140.0, 200.0),
                    child: score,
                  );
                }).toList(),
              );
            },
          ),

          // Overall score
          if (overallScore != null) ...[
            const SizedBox(height: AdminSpacing.xl),
            const Divider(color: AdminColors.divider),
            const SizedBox(height: AdminSpacing.lg),
            _buildOverallScore(),
          ],
        ],
      ),
    );
  }

  Widget _buildOverallScore() {
    final diff = previousOverallScore != null
        ? overallScore! - previousOverallScore!
        : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'OVERALL HEALTH:',
          style: AdminTextStyles.labelMedium.copyWith(
            color: AdminColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: AdminSpacing.md),
        Text(
          '$overallScore/100',
          style: AdminTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AdminColors.textPrimary,
          ),
        ),
        if (diff != null) ...[
          const SizedBox(width: AdminSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.sm,
              vertical: AdminSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: diff >= 0
                  ? AdminColors.successLight
                  : AdminColors.errorLight,
              borderRadius: AdminRadius.fullAll,
            ),
            child: Text(
              diff >= 0 ? '+$diff vs last week' : '$diff vs last week',
              style: AdminTextStyles.labelSmall.copyWith(
                color: diff >= 0 ? AdminColors.success : AdminColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

