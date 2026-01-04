/// FluxUI - A design system and component library for Flux applications.
/// 
/// This library provides:
/// - Design tokens (colors, typography, spacing, radius)
/// - Theme system with light/dark mode support
/// - Reusable UI components
/// 
/// ## Getting Started
/// 
/// Wrap your app with [FluxThemeProvider]:
/// ```dart
/// FluxThemeProvider(
///   theme: FluxTheme.light(seedColor: Colors.blue),
///   child: MaterialApp(
///     theme: FluxThemeProvider.of(context).toThemeData(),
///     home: MyHomePage(),
///   ),
/// )
/// ```
library;

// Theme exports
export 'theme/flux_theme.dart';
export 'theme/flux_colors.dart';
export 'theme/flux_typography.dart';
export 'theme/flux_spacing.dart';

// Component exports
export 'components/flux_button.dart';
export 'components/flux_input.dart';
export 'components/flux_card.dart';
export 'components/flux_badge.dart';

// Layout exports
export 'layout/flux_row.dart';
export 'layout/flux_column.dart';
export 'layout/flux_grid.dart';
export 'layout/flux_stack.dart';
