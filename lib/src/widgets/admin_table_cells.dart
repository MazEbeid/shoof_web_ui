import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';

/// V2 styled table cell for editable content with a popover trigger
class AdminEditableCell extends StatelessWidget {
  final String text;
  final String? tooltip;
  final VoidCallback onEdit;
  final int maxLines;
  final double? maxWidth;

  const AdminEditableCell({
    super.key,
    required this.text,
    this.tooltip,
    required this.onEdit,
    this.maxLines = 2,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      borderRadius: AdminRadius.xsAll,
      child: Container(
        constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
        padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xs, vertical: AdminSpacing.xxs),
        decoration: BoxDecoration(
          border: Border.all(color: AdminColors.border.withOpacity(0.5)),
          borderRadius: AdminRadius.xsAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Tooltip(
                message: tooltip ?? text,
                child: Text(
                  text.isEmpty ? 'N/A' : text,
                  style: AdminTextStyles.bodySmall.copyWith(
                    color: text.isEmpty ? AdminColors.textMuted : AdminColors.textPrimary,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: AdminSpacing.xxs),
            Icon(Icons.edit, size: 12, color: AdminColors.primary.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}

/// V2 styled status badge cell with edit capability (for tables)
class AdminTableStatusCell extends StatelessWidget {
  final String status;
  final VoidCallback onEdit;

  const AdminTableStatusCell({
    super.key,
    required this.status,
    required this.onEdit,
  });

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'active':
        return AdminColors.success;
      case 'completed':
        return AdminColors.info;
      case 'paused':
        return AdminColors.warning;
      case 'draft':
      case 'pending':
        return AdminColors.textMuted;
      default:
        return AdminColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    return InkWell(
      onTap: onEdit,
      borderRadius: AdminRadius.fullAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm, vertical: AdminSpacing.xxs),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AdminRadius.fullAll,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AdminSpacing.xs),
            Text(
              status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : 'N/A',
              style: AdminTextStyles.labelSmall.copyWith(color: color),
            ),
            const SizedBox(width: AdminSpacing.xxs),
            Icon(Icons.keyboard_arrow_down, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}

/// V2 styled count badge cell
class AdminCountCell extends StatelessWidget {
  final int count;
  final Color? color;
  final VoidCallback? onTap;

  const AdminCountCell({
    super.key,
    required this.count,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? AdminColors.textSecondary;
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: AdminRadius.xsAll,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm, vertical: AdminSpacing.xs),
          decoration: BoxDecoration(
            color: displayColor.withOpacity(0.1),
            borderRadius: AdminRadius.xsAll,
          ),
          child: Text(
            count.toString(),
            style: AdminTextStyles.labelSmall.copyWith(
              color: displayColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// V2 styled action button cell
class AdminActionCell extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isLoading;

  const AdminActionCell({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AdminRadius.smAll,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color ?? AdminColors.textSecondary,
                    ),
                  )
                : Icon(
                    icon,
                    size: 18,
                    color: onPressed == null
                        ? AdminColors.textMuted.withOpacity(0.5)
                        : (color ?? AdminColors.textSecondary),
                  ),
          ),
        ),
      ),
    );
  }
}

/// V2 styled URL/Link cell
class AdminLinkCell extends StatelessWidget {
  final String? url;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const AdminLinkCell({
    super.key,
    this.url,
    this.label = 'Open',
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    final buttonColor = color ?? AdminColors.primary;

    return InkWell(
      onTap: hasUrl ? onTap : null,
      borderRadius: AdminRadius.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm, vertical: AdminSpacing.xs),
        decoration: BoxDecoration(
          color: hasUrl ? buttonColor : AdminColors.textMuted.withOpacity(0.1),
          borderRadius: AdminRadius.smAll,
        ),
        child: Text(
          label,
          style: AdminTextStyles.labelSmall.copyWith(
            color: hasUrl ? Colors.white : AdminColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// V2 styled compact button cell
class AdminCompactButtonCell extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isLoading;
  final bool isDisabled;

  const AdminCompactButtonCell({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AdminColors.textSecondary;
    final isActive = !isDisabled && onPressed != null;

    return InkWell(
      onTap: isLoading || isDisabled ? null : onPressed,
      borderRadius: AdminRadius.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm, vertical: AdminSpacing.xs),
        decoration: BoxDecoration(
          color: isActive ? buttonColor.withOpacity(0.1) : AdminColors.backgroundHover,
          borderRadius: AdminRadius.smAll,
          border: Border.all(
            color: isActive ? buttonColor.withOpacity(0.3) : AdminColors.border,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: buttonColor,
                ),
              )
            : Text(
                label,
                style: AdminTextStyles.labelSmall.copyWith(
                  color: isActive ? buttonColor : AdminColors.textMuted,
                ),
              ),
      ),
    );
  }
}

/// V2 styled chips display cell (for tags/lists)
class AdminChipsCell extends StatelessWidget {
  final List<String> items;
  final int maxVisible;
  final VoidCallback? onEdit;

  const AdminChipsCell({
    super.key,
    required this.items,
    this.maxVisible = 2,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.take(maxVisible).toList();
    final remaining = items.length - maxVisible;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: AdminRadius.smAll,
        hoverColor: AdminColors.backgroundHover,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
          padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm, vertical: AdminSpacing.xs),
          decoration: BoxDecoration(
            border: onEdit != null ? Border.all(color: AdminColors.border.withOpacity(0.5)) : null,
            borderRadius: AdminRadius.smAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    ...visibleItems.map((item) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminColors.backgroundHover,
                            borderRadius: AdminRadius.xsAll,
                          ),
                          child: Text(
                            item,
                            style: AdminTextStyles.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                    if (remaining > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AdminColors.primary.withOpacity(0.1),
                          borderRadius: AdminRadius.xsAll,
                        ),
                        child: Text(
                          '+$remaining',
                          style: AdminTextStyles.labelSmall.copyWith(color: AdminColors.primary),
                        ),
                      ),
                  ],
                ),
              ),
              if (onEdit != null) ...[
                const SizedBox(width: AdminSpacing.xs),
                Icon(Icons.edit, size: 14, color: AdminColors.primary.withOpacity(0.7)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

