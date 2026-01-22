import 'package:flutter/material.dart';
import 'admin_colors.dart';
import 'admin_radius.dart';
import 'admin_shadows.dart';
import 'admin_spacing.dart';
import 'admin_typography.dart';

/// Box decorations for Shoof web applications.
class AdminDecorations {
  AdminDecorations._();

  // Card decorations
  static BoxDecoration get card => BoxDecoration(
        color: AdminColors.backgroundCard,
        borderRadius: AdminRadius.mdAll,
        boxShadow: AdminShadows.sm,
      );

  static BoxDecoration get cardElevated => BoxDecoration(
        color: AdminColors.backgroundCard,
        borderRadius: AdminRadius.mdAll,
        boxShadow: AdminShadows.md,
      );

  static BoxDecoration get cardFlat => BoxDecoration(
        color: AdminColors.backgroundCard,
        borderRadius: AdminRadius.mdAll,
        border: Border.all(color: AdminColors.border),
      );

  // Sidebar decoration
  static BoxDecoration get sidebar => BoxDecoration(
        color: AdminColors.sidebarBackground,
        boxShadow: AdminShadows.sidebar,
      );

  // Table container
  static BoxDecoration get tableContainer => BoxDecoration(
        color: AdminColors.backgroundCard,
        borderRadius: AdminRadius.mdAll,
        boxShadow: AdminShadows.sm,
      );

  // Input decoration
  static InputDecoration inputDecoration({
    String? hint,
    String? label,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: AdminTextStyles.bodyMedium.copyWith(
        color: AdminColors.textMuted,
      ),
      labelStyle: AdminTextStyles.labelMedium,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AdminColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.lg,
        vertical: AdminSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: AdminRadius.smAll,
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AdminRadius.smAll,
        borderSide: const BorderSide(color: AdminColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AdminRadius.smAll,
        borderSide: const BorderSide(color: AdminColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AdminRadius.smAll,
        borderSide: const BorderSide(color: AdminColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AdminRadius.smAll,
        borderSide: const BorderSide(color: AdminColors.error, width: 2),
      ),
    );
  }

  // Stat card with accent color
  static BoxDecoration statCardAccent(Color accentColor) => BoxDecoration(
        color: AdminColors.backgroundCard,
        borderRadius: AdminRadius.mdAll,
        boxShadow: AdminShadows.sm,
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
      );

  // Badge decoration
  static BoxDecoration badge(Color color) => BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AdminRadius.xsAll,
      );
}

