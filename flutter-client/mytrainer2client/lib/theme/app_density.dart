import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppDensity {
  static const double scale = 0.74;
  static const double textScale = 0.86;

  static double space(double value) => value * scale;

  static double radius(double value) => math.max(8, value * scale);

  static double icon(double value) => math.max(14, value * 0.84);

  static EdgeInsets all(double value) => EdgeInsets.all(space(value));

  static EdgeInsets symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: space(horizontal),
      vertical: space(vertical),
    );
  }

  static BorderRadius circular(double value) =>
      BorderRadius.circular(radius(value));
}
