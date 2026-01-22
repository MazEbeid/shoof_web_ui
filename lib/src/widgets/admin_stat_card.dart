import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';

/// A stat card widget for displaying metrics on dashboard.
class AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final String? subtitle;
  final String? trend;
  final bool? trendUp;
  final VoidCallback? onTap;
  final bool isLoading;

  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.accentColor,
    this.subtitle,
    this.trend,
    this.trendUp,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AdminColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AdminRadius.mdAll,
        child: Container(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: AdminRadius.mdAll,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row with icon and title
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AdminSpacing.sm),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: AdminRadius.smAll,
                      ),
                      child: Icon(icon, size: 18, color: color),
                    ),
                    const SizedBox(width: AdminSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: AdminTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AdminSpacing.md),

              // Value with loading state
              if (isLoading)
                SizedBox(
                  width: 80,
                  height: 24,
                  child: LinearProgressIndicator(
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                )
              else
                Text(
                  value,
                  style: AdminTextStyles.statLarge.copyWith(
                    color: color,
                    fontSize: 20,
                  ),
                ),

              // Trend or Subtitle
              const SizedBox(height: AdminSpacing.xs),
              if (trend != null && trendUp != null)
                Row(
                  children: [
                    Icon(
                      trendUp! ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: trendUp! ? AdminColors.success : AdminColors.error,
                    ),
                    const SizedBox(width: AdminSpacing.xs),
                    Text(
                      trend!,
                      style: AdminTextStyles.bodySmall.copyWith(
                        color: trendUp! ? AdminColors.success : AdminColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              else if (subtitle != null)
                Text(
                  subtitle!,
                  style: AdminTextStyles.bodySmall.copyWith(
                    color: AdminColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              else
                const SizedBox(height: 16), // Reserve space for alignment
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of stat cards with responsive grid layout
class AdminStatCardRow extends StatelessWidget {
  final List<AdminStatCard> cards;

  const AdminStatCardRow({
    super.key,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards.asMap().entries.map((entry) {
          final index = entry.key;
          final card = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 0 : AdminSpacing.md / 2,
                right: index == cards.length - 1 ? 0 : AdminSpacing.md / 2,
              ),
              child: card,
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A compact stat card for inline use
class AdminStatCardCompact extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;
  final IconData? icon;

  const AdminStatCardCompact({
    super.key,
    required this.title,
    required this.value,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AdminColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: AdminRadius.smAll,
        border: Border.all(
          color: cardColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: cardColor),
            const SizedBox(width: AdminSpacing.sm),
          ],
          Text(
            value,
            style: AdminTextStyles.statSmall.copyWith(color: cardColor),
          ),
          const SizedBox(width: AdminSpacing.xs),
          Text(
            title,
            style: AdminTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// Balance card specifically for Fawry/Paymob style display
class AdminBalanceCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isLoading;
  final bool isError;
  final VoidCallback? onTap;

  const AdminBalanceCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    this.isLoading = false,
    this.isError = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AdminRadius.mdAll,
        child: Container(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: AdminRadius.mdAll,
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AdminSpacing.sm),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: AdminRadius.smAll,
                    ),
                    child: Icon(icon, size: 18, color: accentColor),
                  ),
                  const SizedBox(width: AdminSpacing.sm),
                  Text(
                    title,
                    style: AdminTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AdminSpacing.md),

              // Value
              if (isLoading)
                SizedBox(
                  width: 80,
                  height: 24,
                  child: LinearProgressIndicator(
                    backgroundColor: accentColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                )
              else
                Text(
                  value,
                  style: AdminTextStyles.statLarge.copyWith(
                    color: isError ? AdminColors.error : accentColor,
                    fontSize: 20,
                  ),
                ),

              if (subtitle != null) ...[
                const SizedBox(height: AdminSpacing.xs),
                Text(
                  subtitle!,
                  style: AdminTextStyles.bodySmall.copyWith(
                    color: AdminColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

