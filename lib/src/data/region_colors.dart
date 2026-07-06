import 'package:flutter/material.dart';

/// Region colors shared by dashboard widgets (region pie, breakdowns).
const Map<String, Color> kRegionColors = {
  'Cairo': Color(0xFF2962FF),
  'Alexandria': Color(0xFF00BCD4),
  'Delta': Color(0xFF00C853),
  'Suez Canal': Color(0xFF9C27B0),
  'Upper Egypt': Color(0xFFFF9800),
};

/// Color for a region name, with a neutral fallback for unmapped regions.
Color regionColorFor(String? region) =>
    kRegionColors[region] ?? const Color(0xFF78909C);
