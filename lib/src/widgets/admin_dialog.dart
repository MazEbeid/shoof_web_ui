import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';
import '../theme/admin_shadows.dart';
import '../theme/admin_decorations.dart';
import 'admin_action_buttons.dart';

/// V2 Admin Dialog - Consistent dialog styling
class AdminDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final List<Widget>? actions;
  final double? width;
  final double? maxHeight;
  final bool showCloseButton;
  final IconData? titleIcon;
  final Color? titleIconColor;

  const AdminDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.actions,
    this.width = 500,
    this.maxHeight,
    this.showCloseButton = true,
    this.titleIcon,
    this.titleIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AdminSpacing.xl),
      child: Container(
        width: width,
        constraints: BoxConstraints(
          maxWidth: width ?? 500,
          maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: AdminRadius.lgAll,
          boxShadow: AdminShadows.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AdminSpacing.lg),
              decoration: BoxDecoration(
                color: AdminColors.backgroundHover,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AdminRadius.lg),
                  topRight: Radius.circular(AdminRadius.lg),
                ),
                border: const Border(
                  bottom: BorderSide(color: AdminColors.divider),
                ),
              ),
              child: Row(
                children: [
                  if (titleIcon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (titleIconColor ?? AdminColors.primary).withOpacity(0.1),
                        borderRadius: AdminRadius.smAll,
                      ),
                      child: Icon(
                        titleIcon,
                        color: titleIconColor ?? AdminColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AdminSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AdminTextStyles.sectionTitle),
                        if (subtitle != null) ...[
                          const SizedBox(height: AdminSpacing.xs),
                          Text(subtitle!, style: AdminTextStyles.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  if (showCloseButton)
                    AdminActionButton(
                      icon: Icons.close,
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      color: AdminColors.textMuted,
                    ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AdminSpacing.lg),
                child: content,
              ),
            ),

            // Actions
            if (actions != null && actions!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AdminSpacing.lg),
                decoration: BoxDecoration(
                  color: AdminColors.backgroundHover,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AdminRadius.lg),
                    bottomRight: Radius.circular(AdminRadius.lg),
                  ),
                  border: const Border(
                    top: BorderSide(color: AdminColors.divider),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!
                      .map((action) => Padding(
                            padding: const EdgeInsets.only(left: AdminSpacing.sm),
                            child: action,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show the dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget content,
    List<Widget>? actions,
    double? width,
    double? maxHeight,
    bool showCloseButton = true,
    IconData? titleIcon,
    Color? titleIconColor,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black54,
      builder: (context) => AdminDialog(
        title: title,
        subtitle: subtitle,
        content: content,
        actions: actions,
        width: width,
        maxHeight: maxHeight,
        showCloseButton: showCloseButton,
        titleIcon: titleIcon,
        titleIconColor: titleIconColor,
      ),
    );
  }
}

/// V2 Confirmation Dialog
class AdminConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final bool isDanger;
  final IconData? icon;

  const AdminConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.isDanger = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AdminDialog(
      title: title,
      titleIcon: icon ?? (isDanger ? Icons.warning_amber_rounded : Icons.help_outline),
      titleIconColor: isDanger ? AdminColors.error : AdminColors.warning,
      width: 400,
      showCloseButton: false,
      content: Text(message, style: AdminTextStyles.bodyMedium),
      actions: [
        AdminSecondaryButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        if (isDanger)
          AdminDangerButton(
            label: confirmLabel,
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm?.call();
            },
          )
        else
          AdminPrimaryButton(
            label: confirmLabel,
            onPressed: () {
              Navigator.of(context).pop(true);
              onConfirm?.call();
            },
          ),
      ],
    );
  }

  /// Show confirmation dialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    VoidCallback? onConfirm,
    bool isDanger = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => AdminConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        isDanger: isDanger,
        icon: icon,
      ),
    );
  }
}

/// V2 Loading Dialog
class AdminLoadingDialog extends StatelessWidget {
  final String message;

  const AdminLoadingDialog({
    super.key,
    this.message = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AdminSpacing.xl),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: AdminRadius.lgAll,
          boxShadow: AdminShadows.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AdminColors.primary),
            const SizedBox(height: AdminSpacing.lg),
            Text(message, style: AdminTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }

  /// Show loading dialog
  static void show(BuildContext context, {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => AdminLoadingDialog(message: message),
    );
  }

  /// Hide loading dialog
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// V2 Form Dialog for input forms
class AdminFormDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final String submitLabel;
  final String cancelLabel;
  final VoidCallback? onSubmit;
  final bool isSubmitting;
  final double? width;
  final IconData? titleIcon;

  const AdminFormDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.submitLabel = 'Save',
    this.cancelLabel = 'Cancel',
    this.onSubmit,
    this.isSubmitting = false,
    this.width = 500,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AdminDialog(
      title: title,
      subtitle: subtitle,
      titleIcon: titleIcon,
      width: width,
      content: content,
      actions: [
        AdminSecondaryButton(
          label: cancelLabel,
          onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
        ),
        AdminPrimaryButton(
          label: submitLabel,
          onPressed: isSubmitting ? null : onSubmit,
          isLoading: isSubmitting,
        ),
      ],
    );
  }
}

/// V2 Input Field for dialogs
class AdminDialogField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? helperText;
  final bool isRequired;
  final TextDirection? textDirection;
  final ValueChanged<String>? onChanged;

  const AdminDialogField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.helperText,
    this.isRequired = false,
    this.textDirection,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AdminTextStyles.labelMedium),
            if (isRequired)
              Text(' *', style: AdminTextStyles.labelMedium.copyWith(color: AdminColors.error)),
          ],
        ),
        const SizedBox(height: AdminSpacing.xs),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textDirection: textDirection,
          onChanged: onChanged,
          style: AdminTextStyles.bodyMedium,
          decoration: AdminDecorations.inputDecoration(
            hint: hint,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: AdminSpacing.xs),
          Text(helperText!, style: AdminTextStyles.bodySmall.copyWith(color: AdminColors.textMuted)),
        ],
      ],
    );
  }
}

/// V2 Dropdown Field for dialogs
class AdminDialogDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isRequired;
  final String? helperText;

  const AdminDialogDropdown({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.isRequired = false,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AdminTextStyles.labelMedium),
            if (isRequired)
              Text(' *', style: AdminTextStyles.labelMedium.copyWith(color: AdminColors.error)),
          ],
        ),
        const SizedBox(height: AdminSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AdminColors.border),
            borderRadius: AdminRadius.smAll,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              style: AdminTextStyles.bodyMedium,
              icon: const Icon(Icons.keyboard_arrow_down, color: AdminColors.textSecondary),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: AdminSpacing.xs),
          Text(helperText!, style: AdminTextStyles.bodySmall.copyWith(color: AdminColors.textMuted)),
        ],
      ],
    );
  }
}

