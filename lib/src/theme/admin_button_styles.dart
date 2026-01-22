import 'package:flutter/material.dart';
import 'admin_colors.dart';
import 'admin_radius.dart';
import 'admin_spacing.dart';
import 'admin_typography.dart';

/// Button styles for Shoof web applications.
class AdminButtonStyles {
  AdminButtonStyles._();

  // Primary Button
  static ButtonStyle get primary => ElevatedButton.styleFrom(
        backgroundColor: AdminColors.primary,
        foregroundColor: AdminColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.xl,
          vertical: AdminSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.smAll,
        ),
        textStyle: AdminTextStyles.buttonMedium,
        elevation: 0,
      );

  static ButtonStyle get primarySmall => ElevatedButton.styleFrom(
        backgroundColor: AdminColors.primary,
        foregroundColor: AdminColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.lg,
          vertical: AdminSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.smAll,
        ),
        textStyle: AdminTextStyles.buttonSmall,
        elevation: 0,
      );

  // Secondary Button
  static ButtonStyle get secondary => OutlinedButton.styleFrom(
        foregroundColor: AdminColors.textPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.xl,
          vertical: AdminSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.smAll,
        ),
        side: const BorderSide(color: AdminColors.border),
        textStyle: AdminTextStyles.buttonMedium,
      );

  static ButtonStyle get secondarySmall => OutlinedButton.styleFrom(
        foregroundColor: AdminColors.textPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.lg,
          vertical: AdminSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.smAll,
        ),
        side: const BorderSide(color: AdminColors.border),
        textStyle: AdminTextStyles.buttonSmall,
      );

  // Danger Button
  static ButtonStyle get danger => ElevatedButton.styleFrom(
        backgroundColor: AdminColors.error,
        foregroundColor: AdminColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.xl,
          vertical: AdminSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.smAll,
        ),
        textStyle: AdminTextStyles.buttonMedium,
        elevation: 0,
      );

  static ButtonStyle get dangerSmall => ElevatedButton.styleFrom(
        backgroundColor: AdminColors.error,
        foregroundColor: AdminColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.lg,
          vertical: AdminSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.smAll,
        ),
        textStyle: AdminTextStyles.buttonSmall,
        elevation: 0,
      );

  // Success Button
  static ButtonStyle get success => ElevatedButton.styleFrom(
        backgroundColor: AdminColors.success,
        foregroundColor: AdminColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.xl,
          vertical: AdminSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.smAll,
        ),
        textStyle: AdminTextStyles.buttonMedium,
        elevation: 0,
      );

  static ButtonStyle get successSmall => ElevatedButton.styleFrom(
        backgroundColor: AdminColors.success,
        foregroundColor: AdminColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.lg,
          vertical: AdminSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.smAll,
        ),
        textStyle: AdminTextStyles.buttonSmall,
        elevation: 0,
      );

  // Ghost Button (text-only appearance)
  static ButtonStyle get ghost => TextButton.styleFrom(
        foregroundColor: AdminColors.textPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.lg,
          vertical: AdminSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.smAll,
        ),
        textStyle: AdminTextStyles.buttonMedium,
      );

  // Icon Button
  static ButtonStyle get icon => IconButton.styleFrom(
        foregroundColor: AdminColors.textSecondary,
        padding: const EdgeInsets.all(AdminSpacing.sm),
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.smAll,
        ),
      );
}

