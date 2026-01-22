import 'package:flutter/material.dart';

/// Animation durations for Shoof web applications.
class AdminDurations {
  AdminDurations._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration pageTransition = Duration(milliseconds: 300);
}

/// Animation curves for Shoof web applications.
class AdminCurves {
  AdminCurves._();

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve enterCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;
}

