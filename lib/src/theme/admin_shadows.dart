import 'package:flutter/material.dart';

/// Shadow definitions for Shoof web applications.
class AdminShadows {
  AdminShadows._();

  static List<BoxShadow> get xs => [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get xl => [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get sidebar => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 20,
          offset: const Offset(4, 0),
        ),
      ];

  /// Primary color glow effect
  static List<BoxShadow> primaryGlow({double opacity = 0.3}) => [
        BoxShadow(
          color: const Color(0xFF2962FF).withOpacity(opacity),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  /// Success color glow effect
  static List<BoxShadow> successGlow({double opacity = 0.3}) => [
        BoxShadow(
          color: const Color(0xFF00C853).withOpacity(opacity),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  /// Error color glow effect
  static List<BoxShadow> errorGlow({double opacity = 0.3}) => [
        BoxShadow(
          color: const Color(0xFFFF1744).withOpacity(opacity),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];
}

