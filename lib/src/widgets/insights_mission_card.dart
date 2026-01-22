import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_shadows.dart';

/// Photo-first mission card for the highlights section
/// 
/// Displays a mission with hero photo and key metrics
class InsightsMissionCard extends StatefulWidget {
  final String? imageUrl;
  final String locationName;
  final String locationType;
  final int skuCount;
  final String status;
  final String timeAgo;
  final double? score;
  final VoidCallback? onTap;

  const InsightsMissionCard({
    super.key,
    this.imageUrl,
    required this.locationName,
    required this.locationType,
    required this.skuCount,
    required this.status,
    required this.timeAgo,
    this.score,
    this.onTap,
  });

  @override
  State<InsightsMissionCard> createState() => _InsightsMissionCardState();
}

class _InsightsMissionCardState extends State<InsightsMissionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 260,
          decoration: BoxDecoration(
            color: AdminColors.backgroundCard,
            borderRadius: AdminRadius.lgAll,
            boxShadow: _isHovered ? AdminShadows.md : AdminShadows.sm,
            border: Border.all(
              color: _isHovered
                  ? AdminColors.primary.withOpacity(0.3)
                  : AdminColors.divider,
            ),
          ),
          transform: _isHovered
              ? (Matrix4.identity()..translate(0.0, -4.0))
              : Matrix4.identity(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              _buildImageSection(),
              
              // Content section
              Padding(
                padding: const EdgeInsets.all(AdminSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location name
                    Text(
                      widget.locationName,
                      style: AdminTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: AdminSpacing.xxs),
                    
                    // Location type
                    Text(
                      widget.locationType,
                      style: AdminTextStyles.bodySmall.copyWith(
                        color: AdminColors.textSecondary,
                      ),
                    ),
                    
                    const SizedBox(height: AdminSpacing.md),
                    
                    // Metrics row
                    Row(
                      children: [
                        _buildMetric(
                          icon: Icons.inventory_2_outlined,
                          value: '${widget.skuCount} SKUs',
                        ),
                        const SizedBox(width: AdminSpacing.md),
                        _buildStatusBadge(),
                      ],
                    ),
                    
                    const SizedBox(height: AdminSpacing.sm),
                    
                    // Time and score row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.timeAgo,
                          style: AdminTextStyles.labelSmall.copyWith(
                            color: AdminColors.textMuted,
                          ),
                        ),
                        if (widget.score != null)
                          _buildScoreStars(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AdminRadius.lg),
      ),
      child: Stack(
        children: [
          // Image or placeholder
          Container(
            height: 140,
            width: double.infinity,
            color: AdminColors.backgroundHover,
            child: widget.imageUrl != null
                ? Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildPlaceholder(showLoading: true);
                    },
                  )
                : _buildPlaceholder(),
          ),
          
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          
          // View button on hover
          if (_isHovered)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AdminSpacing.lg,
                      vertical: AdminSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AdminRadius.fullAll,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: AdminColors.textPrimary,
                        ),
                        const SizedBox(width: AdminSpacing.xs),
                        Text(
                          'View Details',
                          style: AdminTextStyles.labelMedium.copyWith(
                            color: AdminColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder({bool showLoading = false}) {
    return Container(
      color: AdminColors.backgroundHover,
      child: Center(
        child: showLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AdminColors.textMuted,
                ),
              )
            : const Icon(
                Icons.image_outlined,
                size: 40,
                color: AdminColors.textMuted,
              ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AdminColors.textMuted),
        const SizedBox(width: AdminSpacing.xxs),
        Text(
          value,
          style: AdminTextStyles.labelSmall.copyWith(
            color: AdminColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    final isCompleted = widget.status.toLowerCase() == 'completed';
    final isInReview = widget.status.toLowerCase() == 'in_review';
    
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;
    
    if (isCompleted) {
      bgColor = AdminColors.successLight;
      textColor = AdminColors.success;
      icon = Icons.check_circle_outline;
      label = '✓';
    } else if (isInReview) {
      bgColor = AdminColors.warningLight;
      textColor = AdminColors.warning;
      icon = Icons.schedule;
      label = '⏳';
    } else {
      bgColor = AdminColors.errorLight;
      textColor = AdminColors.error;
      icon = Icons.cancel_outlined;
      label = '✗';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.sm,
        vertical: AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AdminRadius.fullAll,
      ),
      child: Text(
        label,
        style: AdminTextStyles.labelSmall.copyWith(
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildScoreStars() {
    final score = widget.score ?? 0;
    final fullStars = score.floor();
    final hasHalfStar = score - fullStars >= 0.5;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData icon;
        Color color;
        
        if (index < fullStars) {
          icon = Icons.star_rounded;
          color = AdminColors.accent;
        } else if (index == fullStars && hasHalfStar) {
          icon = Icons.star_half_rounded;
          color = AdminColors.accent;
        } else {
          icon = Icons.star_outline_rounded;
          color = AdminColors.textMuted;
        }
        
        return Icon(icon, size: 14, color: color);
      }),
    );
  }
}

/// Horizontal scrolling carousel of mission cards
class InsightsMissionCarousel extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<InsightsMissionCard> missions;
  final VoidCallback? onViewAll;

  const InsightsMissionCarousel({
    super.key,
    required this.title,
    this.subtitle,
    required this.missions,
    this.onViewAll,
  });

  @override
  State<InsightsMissionCarousel> createState() => _InsightsMissionCarouselState();
}

class _InsightsMissionCarouselState extends State<InsightsMissionCarousel> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    setState(() {
      _canScrollLeft = _scrollController.offset > 0;
      _canScrollRight = _scrollController.offset <
          _scrollController.position.maxScrollExtent;
    });
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      (_scrollController.offset - 300).clamp(0, double.infinity),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 300,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

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
              const Icon(
                Icons.photo_library_rounded,
                color: AdminColors.primary,
                size: 24,
              ),
              const SizedBox(width: AdminSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AdminTextStyles.sectionTitle),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: AdminTextStyles.bodySmall.copyWith(
                          color: AdminColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.onViewAll != null)
                TextButton.icon(
                  onPressed: widget.onViewAll,
                  icon: const Text('View All'),
                  label: const Icon(Icons.arrow_forward_rounded, size: 16),
                ),
            ],
          ),
          
          const SizedBox(height: AdminSpacing.lg),
          
          // Carousel
          Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.missions.map((mission) {
                    return Padding(
                      padding: const EdgeInsets.only(right: AdminSpacing.md),
                      child: mission,
                    );
                  }).toList(),
                ),
              ),
              
              // Left arrow
              if (_canScrollLeft)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: _buildScrollButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: _scrollLeft,
                    isLeft: true,
                  ),
                ),
              
              // Right arrow
              if (_canScrollRight)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: _buildScrollButton(
                    icon: Icons.chevron_right_rounded,
                    onPressed: _scrollRight,
                    isLeft: false,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: AdminSpacing.md),
          
          // Pagination dots
          _buildPaginationDots(),
        ],
      ),
    );
  }

  Widget _buildScrollButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isLeft,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: [
            AdminColors.backgroundCard,
            AdminColors.backgroundCard.withOpacity(0),
          ],
        ),
      ),
      padding: EdgeInsets.only(
        left: isLeft ? 0 : AdminSpacing.xl,
        right: isLeft ? AdminSpacing.xl : 0,
      ),
      child: Center(
        child: Material(
          color: AdminColors.backgroundCard,
          elevation: 2,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AdminColors.divider),
              ),
              child: Icon(icon, color: AdminColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationDots() {
    // Calculate approximate page count
    final pageCount = (widget.missions.length / 3).ceil();
    final currentPage = _scrollController.hasClients
        ? (_scrollController.offset / 300).floor().clamp(0, pageCount - 1)
        : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return Container(
          width: index == currentPage ? 20 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: index == currentPage
                ? AdminColors.primary
                : AdminColors.divider,
            borderRadius: AdminRadius.fullAll,
          ),
        );
      }),
    );
  }
}

