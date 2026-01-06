import 'package:flutter/material.dart';

/// FluxUI spacing tokens for consistent layout spacing.
class FluxSpacing {
  const FluxSpacing._();

  /// Extra small spacing (4.0)
  static const double xs = 4.0;

  /// Small spacing (8.0)
  static const double sm = 8.0;

  /// Medium spacing (16.0)
  static const double md = 16.0;

  /// Large spacing (24.0)
  static const double lg = 24.0;

  /// Extra large spacing (32.0)
  static const double xl = 32.0;

  /// Extra extra large spacing (48.0)
  static const double xxl = 48.0;

  /// Convenience EdgeInsets methods
  static EdgeInsets all(double value) => EdgeInsets.all(value);
  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) =>
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);
}

/// FluxUI border radius tokens for consistent corner styling.
class FluxRadius {
  const FluxRadius._();

  /// No radius (0.0)
  static const double none = 0.0;

  /// Extra small radius (4.0)
  static const double xs = 4.0;

  /// Small radius (8.0)
  static const double sm = 8.0;

  /// Medium radius (12.0)
  static const double md = 12.0;

  /// Large radius (16.0)
  static const double lg = 16.0;

  /// Extra large radius (24.0)
  static const double xl = 24.0;

  /// Full/pill radius (9999.0)
  static const double full = 9999.0;

  /// Convenience BorderRadius methods
  static BorderRadius circular(double radius) => BorderRadius.circular(radius);
  static BorderRadius only({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) =>
      BorderRadius.only(
        topLeft: Radius.circular(topLeft),
        topRight: Radius.circular(topRight),
        bottomLeft: Radius.circular(bottomLeft),
        bottomRight: Radius.circular(bottomRight),
      );
}
