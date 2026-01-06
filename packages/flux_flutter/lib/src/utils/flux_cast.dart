import 'package:flutter/material.dart';

/// Utility class for safe type casting and conversion in Flux.
///
/// This handles cleaning up data coming from the Flux VM (which is untyped)
/// before passing it to Flutter widgets (which expect strict types).
class FluxCast {
  /// Converts a value to a string, or returns null if the value is null.
  static String? toStringNullable(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Convert to String, returning empty string if value is null.
  static String toStr(dynamic value) {
    return value?.toString() ?? '';
  }

  /// Convert to double, returning null on failure/null.
  static double? toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Convert to double, returning 0.0 on failure/null.
  static double toDoubleOrZero(dynamic value) {
    return toDouble(value) ?? 0.0;
  }

  /// Convert to int, returning null on failure/null.
  static int? toInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Convert to int, returning 0 on failure/null.
  static int toIntOrZero(dynamic value) {
    return toInt(value) ?? 0;
  }

  /// Alias for toDouble (explicit nullable return)
  static double? toDoubleNullable(dynamic value) => toDouble(value);

  /// Alias for toInt (explicit nullable return)
  static int? toIntNullable(dynamic value) => toInt(value);

  /// Convert to boolean.
  ///
  /// null -> false
  /// bool -> logic
  /// num -> != 0
  /// string -> 'true'
  static bool toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return true; // Any other non-null object is truthy
  }

  /// Convert to Color.
  ///
  /// Supports:
  /// - int (0xAARRGGBB)
  /// - String ('red', '#RRGGBB', '#AARRGGBB')
  static Color? toColor(dynamic value) {
    if (value == null) return null;
    if (value is Color) return value;
    if (value is int) return Color(value);

    if (value is String) {
      // 1. Handle Named Colors
      switch (value.toLowerCase()) {
        case 'red':
          return Colors.red;
        case 'blue':
          return Colors.blue;
        case 'green':
          return Colors.green;
        case 'yellow':
          return Colors.yellow;
        case 'orange':
          return Colors.orange;
        case 'purple':
          return Colors.purple;
        case 'pink':
          return Colors.pink;
        case 'black':
          return Colors.black;
        case 'white':
          return Colors.white;
        case 'grey':
        case 'gray':
          return Colors.grey;
        case 'transparent':
          return Colors.transparent;
      }

      // 2. Handle Hex Colors
      String hex = value;
      if (hex.startsWith('#')) {
        hex = hex.substring(1);
      }

      if (hex.length == 6) {
        // RRGGBB -> FF(RRGGBB)
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        // AARRGGBB
        return Color(int.parse(hex, radix: 16));
      }
    }
    return null;
  }

  /// Convert to [List<Widget>].
  ///
  /// Handles cleaning up mixed lists or nulls.
  static List<Widget> toWidgetList(dynamic value) {
    if (value is List) {
      return value.whereType<Widget>().toList();
    }
    return [];
  }
}
