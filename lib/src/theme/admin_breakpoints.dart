import 'package:flutter/material.dart';

/// Responsive breakpoints for Shoof web applications.
class AdminBreakpoints {
  AdminBreakpoints._();

  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double widescreen = 1280;
  static const double ultrawide = 1536;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < tablet;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tablet &&
      MediaQuery.of(context).size.width < desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;

  static bool isWidescreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= widescreen;

  static bool isUltrawide(BuildContext context) =>
      MediaQuery.of(context).size.width >= ultrawide;

  /// Returns the number of grid columns based on screen width
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= ultrawide) return 4;
    if (width >= widescreen) return 3;
    if (width >= desktop) return 2;
    return 1;
  }

  /// Get responsive stat card count per row
  static int getStatCardCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= ultrawide) return 5;
    if (width >= widescreen) return 4;
    if (width >= desktop) return 3;
    if (width >= tablet) return 2;
    return 1;
  }
}

