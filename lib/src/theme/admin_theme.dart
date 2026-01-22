import 'package:flutter/material.dart';
import 'admin_colors.dart';
import 'admin_typography.dart';
import 'admin_spacing.dart';
import 'admin_radius.dart';

/// Complete Material theme for Shoof web applications.
class AdminTheme {
  AdminTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AdminFonts.fontFamily,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AdminColors.primary,
        onPrimary: AdminColors.textOnPrimary,
        primaryContainer: AdminColors.primarySurface,
        secondary: AdminColors.accent,
        onSecondary: AdminColors.textPrimary,
        error: AdminColors.error,
        onError: AdminColors.textOnPrimary,
        surface: AdminColors.surface,
        onSurface: AdminColors.textPrimary,
      ),

      // Scaffold
      scaffoldBackgroundColor: AdminColors.backgroundPage,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AdminColors.surface,
        foregroundColor: AdminColors.textPrimary,
        titleTextStyle: AdminTextStyles.headlineMedium,
        iconTheme: const IconThemeData(color: AdminColors.textPrimary),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: AdminColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.lgAll,
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AdminColors.primary,
          foregroundColor: AdminColors.textOnPrimary,
          minimumSize: const Size(0, AdminSpacing.buttonHeightMd),
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AdminRadius.smAll,
          ),
          textStyle: AdminTextStyles.buttonMedium,
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AdminColors.primary,
          minimumSize: const Size(0, AdminSpacing.buttonHeightMd),
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.lg,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AdminRadius.smAll,
          ),
          side: const BorderSide(color: AdminColors.border),
          textStyle: AdminTextStyles.buttonMedium,
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AdminColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.md,
            vertical: AdminSpacing.sm,
          ),
          textStyle: AdminTextStyles.buttonMedium,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.inputPadding,
          vertical: AdminSpacing.inputPadding,
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
        hintStyle: AdminTextStyles.inputHint,
        labelStyle: AdminTextStyles.inputLabel,
        errorStyle: AdminTextStyles.inputError,
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AdminColors.primary;
          }
          return AdminColors.surface;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminRadius.xs),
        ),
        side: const BorderSide(color: AdminColors.border),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AdminColors.surfaceVariant,
        selectedColor: AdminColors.primarySurface,
        labelStyle: AdminTextStyles.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.fullAll,
          side: const BorderSide(color: AdminColors.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.sm,
          vertical: AdminSpacing.xs,
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AdminColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.lgAll,
        ),
        titleTextStyle: AdminTextStyles.headlineSmall,
        contentTextStyle: AdminTextStyles.bodyMedium,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AdminColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: AdminColors.primary,
        unselectedLabelColor: AdminColors.textSecondary,
        labelStyle: AdminTextStyles.labelLarge,
        unselectedLabelStyle: AdminTextStyles.labelLarge,
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AdminColors.primary,
              width: 2,
            ),
          ),
        ),
      ),

      // Data Table
      dataTableTheme: DataTableThemeData(
        headingTextStyle: AdminTextStyles.tableHeader,
        dataTextStyle: AdminTextStyles.tableCell,
        headingRowColor: WidgetStateProperty.all(AdminColors.tableHeader),
        decoration: BoxDecoration(
          color: AdminColors.backgroundCard,
          borderRadius: AdminRadius.lgAll,
        ),
        dividerThickness: 1,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AdminColors.sidebarBackground,
        contentTextStyle: AdminTextStyles.bodyMedium.copyWith(
          color: AdminColors.textOnPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AdminRadius.smAll,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AdminColors.sidebarBackground,
          borderRadius: AdminRadius.smAll,
        ),
        textStyle: AdminTextStyles.bodySmall.copyWith(
          color: AdminColors.textOnPrimary,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AdminSpacing.sm,
          vertical: AdminSpacing.xs,
        ),
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: AdminColors.textSecondary,
        size: 24,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AdminColors.primary,
        linearTrackColor: AdminColors.borderLight,
        circularTrackColor: AdminColors.borderLight,
      ),
    );
  }
}

