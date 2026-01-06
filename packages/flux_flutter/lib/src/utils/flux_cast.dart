import 'package:flutter/material.dart';
import 'package:flux_flutter/src/modules/animation_module.dart';

/// Utility class for safe type casting and conversion in Flux.
///
/// This handles cleaning up data coming from the Flux VM (which is untyped)
/// before passing it to Flutter widgets (which expect strict types).
class FluxCast {
  /// Resolves the final value if it's an animation, otherwise returns the value
  static dynamic resolveValue(dynamic value) {
    if (value is FluxAnimationBase) {
      return value.value;
    }
    return value;
  }

  /// Converts a value to a string, or returns null if the value is null.
  static String? toStringNullable(dynamic value) {
    final resolved = resolveValue(value);
    if (resolved == null) return null;
    return resolved.toString();
  }

  /// Convert to String, returning empty string if value is null.
  static String toStr(dynamic value) {
    return resolveValue(value)?.toString() ?? '';
  }

  /// Convert to double, returning null on failure/null.
  static double? toDouble(dynamic value) {
    final resolved = resolveValue(value);
    if (resolved == null) return null;
    if (resolved is num) return resolved.toDouble();
    if (resolved is String) return double.tryParse(resolved);
    return null;
  }

  /// Convert to double, returning 0.0 on failure/null.
  static double toDoubleOrZero(dynamic value) {
    return toDouble(value) ?? 0.0;
  }

  /// Convert to int, returning null on failure/null.
  static int? toInt(dynamic value) {
    final resolved = resolveValue(value);
    if (resolved == null) return null;
    if (resolved is num) return resolved.toInt();
    if (resolved is String) return int.tryParse(resolved);
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
    final resolved = resolveValue(value);
    if (resolved == null) return false;
    if (resolved is bool) return resolved;
    if (resolved is String) return resolved.toLowerCase() == 'true';
    if (resolved is num) return resolved != 0;
    return true; // Any other non-null object is truthy
  }

  /// Convert to Color.
  ///
  /// Supports:
  /// - int (0xAARRGGBB)
  /// - String ('red', '#RRGGBB', '#AARRGGBB')
  static Color? toColor(dynamic value) {
    final resolved = resolveValue(value);
    if (resolved == null) return null;
    if (resolved is Color) return resolved;
    if (resolved is int) return Color(resolved);

    if (resolved is String) {
      // 1. Handle Named Colors
      switch (resolved.toLowerCase()) {
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
      String hex = resolved;
      if (hex.startsWith('#')) {
        hex = hex.substring(1);
      }

      try {
        if (hex.length == 6) {
          // RRGGBB -> FF(RRGGBB)
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          // AARRGGBB
          return Color(int.parse(hex, radix: 16));
        }
      } catch (_) {
        return null;
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

  /// Convert to [EdgeInsets].
  ///
  /// Supports:
  /// - num: EdgeInsets.all(value)
  /// - List: [all], [horiz, vert], [left, top, right, bottom]
  static EdgeInsets? toEdgeInsets(dynamic value) {
    final resolved = resolveValue(value);
    if (resolved == null) return null;
    if (resolved is EdgeInsets) return resolved;

    if (resolved is num) {
      return EdgeInsets.all(resolved.toDouble());
    }

    if (resolved is List) {
      if (resolved.length == 1 && resolved[0] is num) {
        return EdgeInsets.all((resolved[0] as num).toDouble());
      } else if (resolved.length == 2 &&
          resolved[0] is num &&
          resolved[1] is num) {
        return EdgeInsets.symmetric(
          horizontal: (resolved[0] as num).toDouble(),
          vertical: (resolved[1] as num).toDouble(),
        );
      } else if (resolved.length == 4 &&
          resolved[0] is num &&
          resolved[1] is num &&
          resolved[2] is num &&
          resolved[3] is num) {
        return EdgeInsets.fromLTRB(
          (resolved[0] as num).toDouble(),
          (resolved[1] as num).toDouble(),
          (resolved[2] as num).toDouble(),
          (resolved[3] as num).toDouble(),
        );
      }
    }
    return null;
  }

  /// Convert to [AlignmentGeometry].
  ///
  /// Supports:
  /// - String: 'center', 'bottomRight', etc.
  /// - List: [x, y]
  static AlignmentGeometry? toAlignment(dynamic value) {
    final resolved = resolveValue(value);
    if (resolved == null) return null;
    if (resolved is AlignmentGeometry) return resolved;

    if (resolved is String) {
      switch (resolved) {
        case 'topLeft':
          return Alignment.topLeft;
        case 'topCenter':
          return Alignment.topCenter;
        case 'topRight':
          return Alignment.topRight;
        case 'centerLeft':
          return Alignment.centerLeft;
        case 'center':
          return Alignment.center;
        case 'centerRight':
          return Alignment.centerRight;
        case 'bottomLeft':
          return Alignment.bottomLeft;
        case 'bottomCenter':
          return Alignment.bottomCenter;
        case 'bottomRight':
          return Alignment.bottomRight;
      }
    } else if (resolved is List &&
        resolved.length == 2 &&
        resolved[0] is num &&
        resolved[1] is num) {
      return Alignment(
        (resolved[0] as num).toDouble(),
        (resolved[1] as num).toDouble(),
      );
    }

    return null;
  }
}
