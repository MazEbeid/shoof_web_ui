import 'package:flutter/material.dart';

import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// Section Widget - Title and subtitle for visual organization
///
/// A simple, lightweight widget for separating dashboard sections.
/// No data source required - purely visual.
/// Rendered by both ShooofAdmin (builder/preview) and shoof_insights (client).
class SectionWidget extends StatelessWidget {
  final String title;
  final String? titleAr;
  final String? subtitle;
  final String? subtitleAr;

  const SectionWidget({
    super.key,
    required this.title,
    this.titleAr,
    this.subtitle,
    this.subtitleAr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AdminSpacing.widgetSmall, // Standardized small height (125px)
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: AdminRadius.lgAll,
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            title,
            style: AdminTextStyles.sectionTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Subtitle
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.xs),
            Text(
              subtitle!,
              style: AdminTextStyles.bodyMedium.copyWith(
                color: AdminColors.textSecondary,
              ),
            ),
          ],

          // Divider line at bottom
          const Spacer(),
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AdminColors.primary,
                  AdminColors.primary.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
