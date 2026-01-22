import 'package:flutter/material.dart';

/// Admin color palette for Shoof web applications.
class AdminColors {
  AdminColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF2962FF);
  static const Color primaryDark = Color(0xFF0039CB);
  static const Color primaryLight = Color(0xFF768FFF);
  static const Color primarySurface = Color(0xFFE8F0FE);

  // Accent Colors
  static const Color accent = Color(0xFFFFB800);
  static const Color accentLight = Color(0xFFFFD54F);

  // Mission Type Colors
  static const Color streetMission = Color(0xFF6C5CE7);
  static const Color consumerMission = Color(0xFF00B894);
  static const Color censusMission = Color(0xFFE17055);
  static const Color trainingMission = Color(0xFF0984E3);

  // Semantic Colors
  static const Color success = Color(0xFF00C853);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color successDark = Color(0xFF00A844);
  static const Color warning = Color(0xFFFFAB00);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color warningDark = Color(0xFFFF8F00);
  static const Color error = Color(0xFFFF1744);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFFD32F2F);
  static const Color info = Color(0xFF00B0FF);
  static const Color infoLight = Color(0xFFE1F5FE);
  static const Color infoDark = Color(0xFF0091EA);

  // Brand Colors (for competitor analysis)
  static const Color cocaCola = Color(0xFFE31837);
  static const Color pepsi = Color(0xFF004B93);
  static const Color schweppes = Color(0xFFFFD700);
  static const Color fayrouz = Color(0xFF00A650);

  // Neutral Palette
  static const Color backgroundPage = Color(0xFFF5F7FA);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundSidebar = Color(0xFF1E293B);
  static const Color backgroundHover = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFCBD5E1);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFF2962FF);

  // Sidebar Colors
  static const Color sidebarBackground = Color(0xFF1E293B);
  static const Color sidebarText = Color(0xFFCBD5E1);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);
  static const Color sidebarItemHover = Color(0xFF334155);
  static const Color sidebarItemActive = Color(0xFF2962FF);

  // Table Colors
  static const Color tableHeader = Color(0xFFF8FAFC);
  static const Color tableRowEven = Color(0xFFFFFFFF);
  static const Color tableRowOdd = Color(0xFFF8FAFC);
  static const Color tableRowHover = Color(0xFFEFF6FF);
  static const Color tableRowSelected = Color(0xFFDBEAFE);

  // Surface Variants
  static const Color surfaceVariant = Color(0xFFF8FAFC);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Chart Colors (for data visualization)
  static const List<Color> chartPalette = [
    Color(0xFF2962FF), // Primary blue
    Color(0xFF00C853), // Success green
    Color(0xFFFF5252), // Error red
    Color(0xFFFFAB00), // Warning amber
    Color(0xFF6C5CE7), // Purple
    Color(0xFF00B894), // Teal
    Color(0xFFE17055), // Coral
    Color(0xFF0984E3), // Blue
    Color(0xFF00B0FF), // Light blue
    Color(0xFFFFD54F), // Gold
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF6C5CE7)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF00E676)],
  );

  // Status Helper Methods
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'accepted':
      case 'completed':
      case 'paid':
      case 'available':
      case 'active':
        return success;
      case 'pending':
      case 'waiting':
      case 'in_review':
        return warning;
      case 'rejected':
      case 'expired':
      case 'failed':
      case 'unavailable':
        return error;
      case 'in_progress':
      case 'processing':
        return info;
      default:
        return textMuted;
    }
  }

  static Color getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'accepted':
      case 'completed':
      case 'paid':
      case 'available':
      case 'active':
        return successLight;
      case 'pending':
      case 'waiting':
      case 'in_review':
        return warningLight;
      case 'rejected':
      case 'expired':
      case 'failed':
      case 'unavailable':
        return errorLight;
      case 'in_progress':
      case 'processing':
        return infoLight;
      default:
        return backgroundHover;
    }
  }
}

