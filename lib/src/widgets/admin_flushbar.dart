import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import '../theme/admin_colors.dart';
import '../theme/admin_radius.dart';
import '../theme/admin_spacing.dart';
import '../theme/admin_typography.dart';

/// Toast/Flushbar notification helpers for admin applications.
class AdminFlushbar {
  AdminFlushbar._();

  /// Show a success notification
  static void success(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context: context,
      message: message,
      title: title ?? 'Success',
      icon: Icons.check_circle_rounded,
      backgroundColor: AdminColors.success,
      duration: duration,
    );
  }

  /// Show an error notification
  static void error(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 5),
  }) {
    _show(
      context: context,
      message: message,
      title: title ?? 'Error',
      icon: Icons.error_rounded,
      backgroundColor: AdminColors.error,
      duration: duration,
    );
  }

  /// Show a warning notification
  static void warning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context: context,
      message: message,
      title: title ?? 'Warning',
      icon: Icons.warning_rounded,
      backgroundColor: AdminColors.warning,
      textColor: AdminColors.textPrimary,
      duration: duration,
    );
  }

  /// Show an info notification
  static void info(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context: context,
      message: message,
      title: title ?? 'Info',
      icon: Icons.info_rounded,
      backgroundColor: AdminColors.info,
      duration: duration,
    );
  }

  /// Core flushbar implementation
  static void _show({
    required BuildContext context,
    required String message,
    required String title,
    required IconData icon,
    required Color backgroundColor,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 4),
  }) {
    Flushbar(
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.lg,
        vertical: AdminSpacing.md,
      ),
      borderRadius: AdminRadius.mdAll,
      duration: duration,
      backgroundColor: backgroundColor,
      boxShadows: [
        BoxShadow(
          color: backgroundColor.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      padding: const EdgeInsets.all(AdminSpacing.lg),
      icon: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: AdminRadius.smAll,
        ),
        child: Icon(icon, color: textColor, size: 24),
      ),
      titleText: Text(
        title,
        style: AdminTextStyles.labelLarge.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      messageText: Text(
        message,
        style: AdminTextStyles.bodyMedium.copyWith(
          color: textColor.withOpacity(0.9),
        ),
      ),
      mainButton: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Icon(
          Icons.close,
          color: textColor.withOpacity(0.7),
          size: 20,
        ),
      ),
    ).show(context);
  }
}

/// Loading overlay helper (shows/hides a loading dialog)
class AdminLoadingOverlay {
  AdminLoadingOverlay._();

  /// Show a loading overlay dialog
  static void show(BuildContext context, {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.xl,
              vertical: AdminSpacing.xxl,
            ),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: AdminRadius.lgAll,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AdminColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AdminSpacing.lg),
                Text(
                  message,
                  style: AdminTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AdminSpacing.xs),
                Text(
                  'Please wait...',
                  style: AdminTextStyles.labelSmall.copyWith(
                    color: AdminColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Hide the loading overlay
  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}

/// Alias for backward compatibility
typedef AdminLoadingDialogHelper = AdminLoadingOverlay;

