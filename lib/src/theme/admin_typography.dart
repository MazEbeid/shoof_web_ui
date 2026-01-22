import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_colors.dart';

/// Font configuration for Shoof web applications.
/// 
/// Supports two font modes:
/// - `googleFonts`: Plus Jakarta Sans from Google Fonts (default, matches ShooofAdmin)
/// - `neoSans`: Custom NeoSans font (optimized for Arabic support)
class AdminFonts {
  AdminFonts._();

  /// Current font family (can be changed globally)
  static String fontFamily = 'GoogleFonts';

  /// Use Google Fonts (Plus Jakarta Sans) - default, matches ShooofAdmin
  static void useGoogleFonts() {
    fontFamily = 'GoogleFonts';
  }

  /// Use NeoSans font (with Arabic support)
  static void useNeoSans() {
    fontFamily = 'NeoSans';
  }

  /// Check if using Google Fonts (Plus Jakarta Sans)
  static bool get isGoogleFonts => fontFamily == 'GoogleFonts';

  /// Check if using NeoSans
  static bool get isNeoSans => fontFamily == 'NeoSans';
}

/// Typography styles for Shoof web applications.
/// 
/// Uses NeoSans by default for Arabic support.
/// Can be switched to Google Fonts via `AdminFonts.useGoogleFonts()`.
class AdminTextStyles {
  AdminTextStyles._();

  // Base font getter for consistency
  // Uses Plus Jakarta Sans by default (matches ShooofAdmin)
  static TextStyle _baseStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = AdminColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    if (AdminFonts.isGoogleFonts) {
      return GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
    // Fallback to NeoSans (for Arabic support if needed)
    return TextStyle(
      fontFamily: 'NeoSans',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // ============================================
  // DISPLAY STYLES (Large hero numbers/KPIs)
  // ============================================
  static TextStyle get displayLarge => _baseStyle(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -1.5,
      );

  static TextStyle get displayMedium => _baseStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get displaySmall => _baseStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  // ============================================
  // PAGE & SECTION HEADERS
  // ============================================
  static TextStyle get pageTitle => _baseStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AdminColors.textPrimary,
      );

  static TextStyle get sectionTitle => _baseStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AdminColors.textPrimary,
      );

  static TextStyle get cardTitle => _baseStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AdminColors.textPrimary,
      );

  static TextStyle get subtitle => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AdminColors.textSecondary,
      );

  // ============================================
  // HEADLINE STYLES (Page/Section titles)
  // ============================================
  static TextStyle get headlineLarge => _baseStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AdminColors.textPrimary,
      );

  static TextStyle get headlineMedium => _baseStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AdminColors.textPrimary,
      );

  static TextStyle get headlineSmall => _baseStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AdminColors.textPrimary,
      );

  // ============================================
  // TITLE STYLES (Cards, dialogs)
  // ============================================
  static TextStyle get titleLarge => _baseStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AdminColors.textPrimary,
      );

  static TextStyle get titleMedium => _baseStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AdminColors.textPrimary,
      );

  static TextStyle get titleSmall => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AdminColors.textPrimary,
      );

  // ============================================
  // BODY STYLES (Main content)
  // ============================================
  static TextStyle get bodyLarge => _baseStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AdminColors.textPrimary,
      );

  static TextStyle get bodyMedium => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AdminColors.textPrimary,
      );

  static TextStyle get bodySmall => _baseStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AdminColors.textSecondary,
      );

  // ============================================
  // LABEL STYLES (Buttons, form labels)
  // ============================================
  static TextStyle get labelLarge => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.1,
        color: AdminColors.textPrimary,
      );

  static TextStyle get labelMedium => _baseStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
        color: AdminColors.textSecondary,
      );

  static TextStyle get labelSmall => _baseStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.5,
        color: AdminColors.textMuted,
      );

  // ============================================
  // STAT/KPI STYLES
  // ============================================
  static TextStyle get statLarge => _baseStyle(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: AdminColors.textPrimary,
      );

  static TextStyle get statMedium => _baseStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: AdminColors.textPrimary,
      );

  static TextStyle get statSmall => _baseStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AdminColors.textPrimary,
      );

  // ============================================
  // TABLE STYLES
  // ============================================
  static TextStyle get tableHeader => _baseStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.5,
        color: AdminColors.textSecondary,
      );

  static TextStyle get tableCell => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AdminColors.textPrimary,
      );

  // ============================================
  // SIDEBAR STYLES
  // ============================================
  static TextStyle get sidebarItem => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AdminColors.sidebarText,
      );

  static TextStyle get sidebarItemActive => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AdminColors.sidebarTextActive,
      );

  static TextStyle get sidebarHeader => _baseStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 1.0,
        color: AdminColors.textMuted,
      );

  // ============================================
  // BUTTON STYLES
  // ============================================
  static TextStyle get buttonLarge => _baseStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.3,
      );

  static TextStyle get buttonMedium => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.3,
      );

  static TextStyle get buttonSmall => _baseStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.3,
      );

  // ============================================
  // INPUT STYLES
  // ============================================
  static TextStyle get inputText => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AdminColors.textPrimary,
      );

  static TextStyle get inputHint => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AdminColors.textMuted,
      );

  static TextStyle get inputLabel => _baseStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AdminColors.textSecondary,
      );

  static TextStyle get inputError => _baseStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AdminColors.error,
      );

  // ============================================
  // CHART STYLES
  // ============================================
  static TextStyle get chartLabel => _baseStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AdminColors.textMuted,
      );

  static TextStyle get chartTooltip => _baseStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AdminColors.textOnPrimary,
      );

  // ============================================
  // LINK STYLES
  // ============================================
  static TextStyle get link => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AdminColors.textLink,
      );

  static TextStyle get linkUnderlined => _baseStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AdminColors.textLink,
      ).copyWith(decoration: TextDecoration.underline);
}

/// Extension methods for TextStyle modifications
extension AdminTextStyleExtensions on TextStyle {
  /// Apply white color for dark backgrounds
  TextStyle get onDark => copyWith(color: AdminColors.textOnPrimary);
  
  /// Apply primary text color for light backgrounds
  TextStyle get onLight => copyWith(color: AdminColors.textPrimary);
  
  /// Apply muted text color
  TextStyle get muted => copyWith(color: AdminColors.textMuted);
  
  /// Apply secondary text color
  TextStyle get secondary => copyWith(color: AdminColors.textSecondary);
  
  /// Apply primary brand color
  TextStyle get primaryColor => copyWith(color: AdminColors.primary);
  
  /// Apply success color
  TextStyle get success => copyWith(color: AdminColors.success);
  
  /// Apply warning color
  TextStyle get warning => copyWith(color: AdminColors.warning);
  
  /// Apply error color
  TextStyle get error => copyWith(color: AdminColors.error);
  
  /// Apply info color
  TextStyle get info => copyWith(color: AdminColors.info);
  
  /// Apply bold weight
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
  
  /// Apply semi-bold weight
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  
  /// Apply medium weight
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  
  /// Apply regular weight
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);
  
  /// Apply light weight
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
}
