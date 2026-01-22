import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_decorations.dart';
import '../theme/admin_button_styles.dart';

/// A standard card container using the V2 design system.
class AdminCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final bool elevated;
  final VoidCallback? onTap;

  const AdminCard({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.actions,
    this.padding,
    this.elevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || titleWidget != null || actions != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AdminRadius.mdAll,
        child: Container(
          decoration: elevated
              ? AdminDecorations.cardElevated
              : AdminDecorations.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              if (hasHeader)
                Container(
                  padding: const EdgeInsets.all(AdminSpacing.lg),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AdminColors.divider),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (titleWidget != null)
                        titleWidget!
                      else if (title != null)
                        Expanded(
                          child: Text(
                            title!,
                            style: AdminTextStyles.cardTitle,
                          ),
                        ),
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),

              // Content
              Padding(
                padding: padding ?? const EdgeInsets.all(AdminSpacing.lg),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A flat card variant (border instead of shadow)
class AdminCardFlat extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;

  const AdminCardFlat({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || actions != null;

    return Container(
      decoration: AdminDecorations.cardFlat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (hasHeader)
            Container(
              padding: const EdgeInsets.all(AdminSpacing.lg),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AdminColors.divider),
                ),
              ),
              child: Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: AdminTextStyles.cardTitle,
                      ),
                    ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),

          // Content
          Padding(
            padding: padding ?? const EdgeInsets.all(AdminSpacing.lg),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Empty state widget for cards and tables
class AdminEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;

  const AdminEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AdminColors.backgroundHover,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.inbox_outlined,
                size: 32,
                color: AdminColors.textMuted,
              ),
            ),
            const SizedBox(height: AdminSpacing.lg),
            Text(
              title,
              style: AdminTextStyles.cardTitle,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AdminSpacing.sm),
              Text(
                subtitle!,
                style: AdminTextStyles.bodyMedium.copyWith(
                  color: AdminColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AdminSpacing.xl),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state widget
class AdminErrorState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  const AdminErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AdminColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 32,
                color: AdminColors.error,
              ),
            ),
            const SizedBox(height: AdminSpacing.lg),
            Text(
              title,
              style: AdminTextStyles.cardTitle,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AdminSpacing.sm),
              Text(
                subtitle!,
                style: AdminTextStyles.bodyMedium.copyWith(
                  color: AdminColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AdminSpacing.xl),
              ElevatedButton.icon(
                style: AdminButtonStyles.primary,
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading state widget
class AdminLoadingState extends StatelessWidget {
  final String? message;

  const AdminLoadingState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AdminColors.primary,
            strokeWidth: 2,
          ),
          if (message != null) ...[
            const SizedBox(height: AdminSpacing.lg),
            Text(
              message!,
              style: AdminTextStyles.labelMedium,
            ),
          ],
        ],
      ),
    );
  }
}

