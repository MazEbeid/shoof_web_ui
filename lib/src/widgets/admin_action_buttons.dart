import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_button_styles.dart';

/// V2 Admin Action Button - Compact icon button for table actions
class AdminActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final bool isLoading;
  final double size;

  const AdminActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.isLoading = false,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: AdminRadius.smAll,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AdminRadius.smAll,
          hoverColor: (color ?? AdminColors.textSecondary).withOpacity(0.1),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: size * 0.5,
                    height: size * 0.5,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color ?? AdminColors.textSecondary,
                    ),
                  )
                : Icon(
                    icon,
                    size: size * 0.55,
                    color: onPressed == null
                        ? AdminColors.textMuted
                        : (color ?? AdminColors.textSecondary),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Edit Action Button
class AdminEditButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;

  const AdminEditButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Edit',
  });

  @override
  Widget build(BuildContext context) {
    return AdminActionButton(
      icon: Icons.edit_outlined,
      tooltip: tooltip,
      onPressed: onPressed,
      color: AdminColors.primary,
    );
  }
}

/// Delete Action Button
class AdminDeleteButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isLoading;

  const AdminDeleteButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Delete',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdminActionButton(
      icon: Icons.delete_outline,
      tooltip: tooltip,
      onPressed: onPressed,
      color: AdminColors.error,
      isLoading: isLoading,
    );
  }
}

/// View/Open Action Button
class AdminViewButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;

  const AdminViewButton({
    super.key,
    this.onPressed,
    this.tooltip = 'View',
  });

  @override
  Widget build(BuildContext context) {
    return AdminActionButton(
      icon: Icons.visibility_outlined,
      tooltip: tooltip,
      onPressed: onPressed,
      color: AdminColors.info,
    );
  }
}

/// Reset Action Button
class AdminResetButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isLoading;
  final bool isDisabled;

  const AdminResetButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Reset',
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdminActionButton(
      icon: Icons.refresh,
      tooltip: tooltip,
      onPressed: isDisabled ? null : onPressed,
      color: AdminColors.warning,
      isLoading: isLoading,
    );
  }
}

/// Copy Action Button
class AdminCopyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isLoading;

  const AdminCopyButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Copy',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdminActionButton(
      icon: Icons.content_copy,
      tooltip: tooltip,
      onPressed: onPressed,
      color: AdminColors.info,
      isLoading: isLoading,
    );
  }
}

/// Export Action Button  
class AdminExportButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isLoading;

  const AdminExportButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Export',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdminActionButton(
      icon: Icons.file_upload_outlined,
      tooltip: tooltip,
      onPressed: onPressed,
      color: AdminColors.success,
      isLoading: isLoading,
    );
  }
}

/// Action Button Row - Groups multiple action buttons
class AdminActionButtonRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment alignment;

  const AdminActionButtonRow({
    super.key,
    required this.children,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: children
          .map((child) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: child,
              ))
          .toList(),
    );
  }
}

/// Text Action Button with icon
class AdminTextActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isLoading;
  final bool compact;

  const AdminTextActionButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.isLoading = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AdminColors.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: AdminRadius.smAll,
        hoverColor: buttonColor.withOpacity(0.1),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AdminSpacing.sm : AdminSpacing.md,
            vertical: compact ? AdminSpacing.xs : AdminSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: buttonColor.withOpacity(0.5)),
            borderRadius: AdminRadius.smAll,
          ),
          child: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: buttonColor,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: compact ? 14 : 16, color: buttonColor),
                      SizedBox(width: compact ? 4 : 6),
                    ],
                    Text(
                      label,
                      style: (compact ? AdminTextStyles.labelSmall : AdminTextStyles.labelMedium)
                          .copyWith(color: buttonColor),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Primary filled action button
class AdminPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const AdminPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 36,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: AdminButtonStyles.primary,
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Secondary outlined action button
class AdminSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const AdminSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 36,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: AdminButtonStyles.secondary,
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AdminColors.primary,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Danger/Delete action button
class AdminDangerButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const AdminDangerButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 36,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.error,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: AdminRadius.smAll),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

