import 'package:flutter/material.dart';

import 'flux_colors.dart';
import 'flux_typography.dart';
import 'flux_spacing.dart';

export 'flux_colors.dart';
export 'flux_typography.dart';
export 'flux_spacing.dart';

/// FluxUI Theme - A complete design system for Flux applications.
/// 
/// [FluxTheme] provides a centralized way to define and access design tokens
/// including colors, typography, spacing, and more.
/// 
/// Example usage:
/// ```dart
/// FluxThemeProvider(
///   theme: FluxTheme.light(),
///   child: MyApp(),
/// )
/// ```
class FluxTheme {
  /// Color scheme for the theme
  final FluxColorScheme colorScheme;

  /// Typography styles
  final FluxTypography typography;

  /// Whether this is a dark theme
  bool get isDark => colorScheme.isDark;

  const FluxTheme({
    required this.colorScheme,
    required this.typography,
  });

  /// Access the FluxTheme from the nearest context
  static FluxTheme of(BuildContext context) {
    return FluxThemeProvider.of(context);
  }

  /// Create a light theme with optional seed color
  factory FluxTheme.light({Color? seedColor}) {
    final colors = seedColor != null
        ? FluxColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light)
        : FluxColorScheme.light;
    
    return FluxTheme(
      colorScheme: colors,
      typography: FluxTypography.defaults(color: colors.onBackground),
    );
  }

  /// Create a dark theme with optional seed color
  factory FluxTheme.dark({Color? seedColor}) {
    final colors = seedColor != null
        ? FluxColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark)
        : FluxColorScheme.dark;
    
    return FluxTheme(
      colorScheme: colors,
      typography: FluxTypography.defaults(color: colors.onBackground),
    );
  }

  /// Create a FluxTheme from a seed color
  factory FluxTheme.fromSeed({
    required Color seedColor,
    Brightness brightness = Brightness.light,
  }) {
    final colors = FluxColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    
    return FluxTheme(
      colorScheme: colors,
      typography: FluxTypography.defaults(color: colors.onBackground),
    );
  }

  /// Convert to Flutter's ThemeData
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.toColorScheme(),
      textTheme: typography.toTextTheme(),
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FluxRadius.md),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: FluxSpacing.lg,
            vertical: FluxSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FluxRadius.sm),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: FluxSpacing.lg,
            vertical: FluxSpacing.md,
          ),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FluxRadius.sm),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: FluxSpacing.md,
            vertical: FluxSpacing.sm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluxRadius.sm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluxRadius.sm),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluxRadius.sm),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FluxRadius.sm),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FluxSpacing.md,
          vertical: FluxSpacing.md,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }

  /// Copy with modifications
  FluxTheme copyWith({
    FluxColorScheme? colorScheme,
    FluxTypography? typography,
  }) {
    return FluxTheme(
      colorScheme: colorScheme ?? this.colorScheme,
      typography: typography ?? this.typography,
    );
  }
}

/// InheritedWidget to provide FluxTheme to descendants
class FluxThemeProvider extends InheritedWidget {
  final FluxTheme theme;

  const FluxThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  static FluxTheme of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<FluxThemeProvider>();
    return provider?.theme ?? FluxTheme.light();
  }

  static FluxTheme? maybeOf(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<FluxThemeProvider>();
    return provider?.theme;
  }

  @override
  bool updateShouldNotify(FluxThemeProvider oldWidget) {
    return theme != oldWidget.theme;
  }
}

/// Extension to easily access FluxTheme from BuildContext
extension FluxThemeExtension on BuildContext {
  FluxTheme get fluxTheme => FluxThemeProvider.of(this);
  FluxColorScheme get fluxColors => fluxTheme.colorScheme;
  FluxTypography get fluxTypography => fluxTheme.typography;
}
