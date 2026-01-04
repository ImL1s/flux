import 'package:flutter/material.dart';

/// FluxUI color scheme based on Material 3 color system.
///
/// Use [FluxColorScheme.fromSeed] to generate a harmonious color palette
/// from a single seed color.
class FluxColorScheme {
  /// Primary brand color
  final Color primary;

  /// Color for content on primary
  final Color onPrimary;

  /// Primary container color
  final Color primaryContainer;

  /// Color for content on primary container
  final Color onPrimaryContainer;

  /// Secondary accent color
  final Color secondary;

  /// Color for content on secondary
  final Color onSecondary;

  /// Secondary container color
  final Color secondaryContainer;

  /// Color for content on secondary container
  final Color onSecondaryContainer;

  /// Tertiary accent color
  final Color tertiary;

  /// Color for content on tertiary
  final Color onTertiary;

  /// Surface color for cards, sheets, dialogs
  final Color surface;

  /// Color for content on surface
  final Color onSurface;

  /// Variant surface color
  final Color surfaceVariant;

  /// Color for content on surface variant
  final Color onSurfaceVariant;

  /// Background color
  final Color background;

  /// Color for content on background
  final Color onBackground;

  /// Error color
  final Color error;

  /// Color for content on error
  final Color onError;

  /// Outline color for borders
  final Color outline;

  /// Variant outline color
  final Color outlineVariant;

  /// Shadow color
  final Color shadow;

  /// Whether this is a dark color scheme
  final bool isDark;

  const FluxColorScheme({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.onError,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    this.isDark = false,
  });

  /// Create a FluxColorScheme from a seed color using Material 3 color generation.
  factory FluxColorScheme.fromSeed({
    required Color seedColor,
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return FluxColorScheme(
      primary: colorScheme.primary,
      onPrimary: colorScheme.onPrimary,
      primaryContainer: colorScheme.primaryContainer,
      onPrimaryContainer: colorScheme.onPrimaryContainer,
      secondary: colorScheme.secondary,
      onSecondary: colorScheme.onSecondary,
      secondaryContainer: colorScheme.secondaryContainer,
      onSecondaryContainer: colorScheme.onSecondaryContainer,
      tertiary: colorScheme.tertiary,
      onTertiary: colorScheme.onTertiary,
      surface: colorScheme.surface,
      onSurface: colorScheme.onSurface,
      surfaceVariant: colorScheme.surfaceContainerHighest,
      onSurfaceVariant: colorScheme.onSurfaceVariant,
      background: colorScheme.surface,
      onBackground: colorScheme.onSurface,
      error: colorScheme.error,
      onError: colorScheme.onError,
      outline: colorScheme.outline,
      outlineVariant: colorScheme.outlineVariant,
      shadow: colorScheme.shadow,
      isDark: brightness == Brightness.dark,
    );
  }

  /// Default light color scheme with blue primary
  static FluxColorScheme get light => FluxColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.light,
      );

  /// Default dark color scheme with blue primary
  static FluxColorScheme get dark => FluxColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.dark,
      );

  /// Convert to Flutter's ColorScheme
  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: onError,
      outline: outline,
      shadow: shadow,
    );
  }
}
