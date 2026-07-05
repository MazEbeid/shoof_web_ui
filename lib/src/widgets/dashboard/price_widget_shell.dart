import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// Shared container + header for price dashboard widgets.
class PriceWidgetShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double height;
  final Widget? trailing;
  final Widget child;

  const PriceWidgetShell({
    super.key,
    required this.title,
    this.subtitle,
    this.height = AdminSpacing.widgetLarge,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: AdminRadius.lgAll,
        border: Border.all(color: AdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: AdminTextStyles.sectionTitle)),
              if (trailing != null) trailing!,
            ],
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AdminSpacing.xs),
            Text(
              subtitle!,
              style: AdminTextStyles.bodySmall.copyWith(
                color: AdminColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: AdminSpacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Centered muted message for empty/hint states inside price widgets.
class PriceWidgetMessage extends StatelessWidget {
  final String message;

  const PriceWidgetMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: AdminTextStyles.bodySmall.copyWith(color: AdminColors.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Standard async wrapper: spinner / error text / data builder.
class PriceAsyncContent<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  const PriceAsyncContent({
    super.key,
    required this.value,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: AdminColors.error)),
      ),
      data: builder,
    );
  }
}
