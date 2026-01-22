import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_shadows.dart';

/// Hero story banner for the Insights dashboard
/// 
/// Displays a dynamic, animated banner with weekly summary and key metrics
class InsightsHeroBanner extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? trendText;
  final bool? trendUp;
  final VoidCallback? onViewReport;
  final List<InsightsWeekTab>? weekTabs;
  final int selectedWeekIndex;
  final ValueChanged<int>? onWeekChanged;

  const InsightsHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.trendText,
    this.trendUp,
    this.onViewReport,
    this.weekTabs,
    this.selectedWeekIndex = 0,
    this.onWeekChanged,
  });

  @override
  State<InsightsHeroBanner> createState() => _InsightsHeroBannerState();
}

class _InsightsHeroBannerState extends State<InsightsHeroBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AdminSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Deep navy
            Color(0xFF1E293B), // Slate
            Color(0xFF1E3A5F), // Dark blue accent
          ],
        ),
        borderRadius: AdminRadius.lgAll,
        boxShadow: AdminShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content
          FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Week label
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AdminSpacing.md,
                            vertical: AdminSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AdminColors.primary.withOpacity(0.2),
                            borderRadius: AdminRadius.fullAll,
                          ),
                          child: Text(
                            'WEEKLY PERFORMANCE STORY',
                            style: AdminTextStyles.labelSmall.copyWith(
                              color: AdminColors.primaryLight,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: AdminSpacing.lg),
                        
                        // Title
                        Text(
                          widget.title,
                          style: AdminTextStyles.headlineLarge.copyWith(
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        
                        const SizedBox(height: AdminSpacing.sm),
                        
                        // Subtitle
                        Text(
                          widget.subtitle,
                          style: AdminTextStyles.bodyLarge.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        
                        const SizedBox(height: AdminSpacing.xl),
                        
                        // Action buttons
                        Row(
                          children: [
                            if (widget.trendText != null) ...[
                              _buildTrendBadge(),
                              const SizedBox(width: AdminSpacing.md),
                            ],
                            if (widget.onViewReport != null)
                              _buildViewReportButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Decorative element
                  _buildDecorativeElement(),
                ],
              ),
            ),
          ),
          
          // Week tabs
          if (widget.weekTabs != null && widget.weekTabs!.isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.xl),
            _buildWeekTabs(),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendBadge() {
    final isUp = widget.trendUp ?? true;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isUp
            ? AdminColors.success.withOpacity(0.15)
            : AdminColors.error.withOpacity(0.15),
        borderRadius: AdminRadius.smAll,
        border: Border.all(
          color: isUp
              ? AdminColors.success.withOpacity(0.3)
              : AdminColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 18,
            color: isUp ? AdminColors.success : AdminColors.error,
          ),
          const SizedBox(width: AdminSpacing.xs),
          Text(
            widget.trendText!,
            style: AdminTextStyles.labelMedium.copyWith(
              color: isUp ? AdminColors.success : AdminColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewReportButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onViewReport,
        borderRadius: AdminRadius.smAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.lg,
            vertical: AdminSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AdminColors.primary,
            borderRadius: AdminRadius.smAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bar_chart_rounded, size: 18, color: Colors.white),
              const SizedBox(width: AdminSpacing.sm),
              Text(
                'View Full Report',
                style: AdminTextStyles.buttonMedium.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeElement() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          // Outer ring
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AdminColors.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
          ),
          // Inner ring
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AdminColors.primaryLight.withOpacity(0.4),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          // Center icon
          Center(
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AdminColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: AdminColors.primaryLight,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekTabs() {
    return Row(
      children: List.generate(widget.weekTabs!.length, (index) {
        final tab = widget.weekTabs![index];
        final isSelected = index == widget.selectedWeekIndex;
        
        return Padding(
          padding: EdgeInsets.only(right: index < widget.weekTabs!.length - 1 ? AdminSpacing.sm : 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onWeekChanged?.call(index),
              borderRadius: AdminRadius.fullAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AdminSpacing.md,
                  vertical: AdminSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: AdminRadius.fullAll,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AdminSpacing.sm),
                    Text(
                      tab.label,
                      style: AdminTextStyles.labelMedium.copyWith(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Week tab data for the hero banner
class InsightsWeekTab {
  final String label;
  final String? summary;

  const InsightsWeekTab({
    required this.label,
    this.summary,
  });
}

