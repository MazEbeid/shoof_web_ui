import 'package:flutter/material.dart';

import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../../theme/admin_radius.dart';
import '../../theme/admin_typography.dart';

/// Wraps any dashboard widget with collapse/expand behavior so tall widgets
/// don't hijack page scrolling. Expanded: renders the child with a small
/// chevron floating in the top-right corner. Collapsed: a compact bar with
/// the widget title and an expand chevron.
///
/// Purely presentational - the child keeps fetching/managing its own state
/// only while expanded (collapsed children are not built).
class CollapsibleWidgetShell extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyCollapsed;

  const CollapsibleWidgetShell({
    super.key,
    required this.title,
    required this.child,
    this.initiallyCollapsed = false,
  });

  @override
  State<CollapsibleWidgetShell> createState() => _CollapsibleWidgetShellState();
}

class _CollapsibleWidgetShellState extends State<CollapsibleWidgetShell> {
  late bool _collapsed = widget.initiallyCollapsed;

  @override
  Widget build(BuildContext context) {
    if (_collapsed) {
      return Container(
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: AdminRadius.lgAll,
          border: Border.all(color: AdminColors.divider),
        ),
        child: InkWell(
          borderRadius: AdminRadius.lgAll,
          onTap: () => setState(() => _collapsed = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.lg,
              vertical: AdminSpacing.md,
            ),
            child: Row(
              children: [
                Icon(Icons.unfold_more, size: 18, color: AdminColors.textMuted),
                const SizedBox(width: AdminSpacing.sm),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AdminTextStyles.sectionTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Collapsed — tap to expand',
                  style: AdminTextStyles.labelSmall.copyWith(
                    color: AdminColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 2,
          right: 2,
          child: Tooltip(
            message: 'Collapse widget',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _collapsed = true),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.unfold_less,
                  size: 16,
                  color: AdminColors.textMuted.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
