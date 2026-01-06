import 'package:flutter/material.dart';

/// FluxUI typography system based on Material 3 type scale.
///
/// Follows the 5-group, 3-scale pattern:
/// - Display (Large, Medium, Small)
/// - Headline (Large, Medium, Small)
/// - Title (Large, Medium, Small)
/// - Body (Large, Medium, Small)
/// - Label (Large, Medium, Small)
class FluxTypography {
  /// Display Large - Hero text, biggest headlines
  final TextStyle displayLarge;

  /// Display Medium - Large section headers
  final TextStyle displayMedium;

  /// Display Small - Prominent headers
  final TextStyle displaySmall;

  /// Headline Large - Screen titles
  final TextStyle headlineLarge;

  /// Headline Medium - Section headers
  final TextStyle headlineMedium;

  /// Headline Small - Subsection headers
  final TextStyle headlineSmall;

  /// Title Large - Card titles, dialog titles
  final TextStyle titleLarge;

  /// Title Medium - List item titles
  final TextStyle titleMedium;

  /// Title Small - Small titles
  final TextStyle titleSmall;

  /// Body Large - Primary paragraph text
  final TextStyle bodyLarge;

  /// Body Medium - Secondary paragraph text
  final TextStyle bodyMedium;

  /// Body Small - Caption, helper text
  final TextStyle bodySmall;

  /// Label Large - Button text, tabs
  final TextStyle labelLarge;

  /// Label Medium - Chips, badges
  final TextStyle labelMedium;

  /// Label Small - Footnotes, timestamps
  final TextStyle labelSmall;

  const FluxTypography({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
  });

  /// Default typography using system fonts
  factory FluxTypography.defaults({Color? color}) {
    final textColor = color ?? Colors.black87;

    return FluxTypography(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.25,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.29,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.33,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.27,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.5,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: textColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: textColor,
      ),
    );
  }

  /// Convert to Flutter's TextTheme
  TextTheme toTextTheme() {
    return TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }

  /// Create typography with a custom font family
  FluxTypography withFontFamily(String fontFamily) {
    return FluxTypography(
      displayLarge: displayLarge.copyWith(fontFamily: fontFamily),
      displayMedium: displayMedium.copyWith(fontFamily: fontFamily),
      displaySmall: displaySmall.copyWith(fontFamily: fontFamily),
      headlineLarge: headlineLarge.copyWith(fontFamily: fontFamily),
      headlineMedium: headlineMedium.copyWith(fontFamily: fontFamily),
      headlineSmall: headlineSmall.copyWith(fontFamily: fontFamily),
      titleLarge: titleLarge.copyWith(fontFamily: fontFamily),
      titleMedium: titleMedium.copyWith(fontFamily: fontFamily),
      titleSmall: titleSmall.copyWith(fontFamily: fontFamily),
      bodyLarge: bodyLarge.copyWith(fontFamily: fontFamily),
      bodyMedium: bodyMedium.copyWith(fontFamily: fontFamily),
      bodySmall: bodySmall.copyWith(fontFamily: fontFamily),
      labelLarge: labelLarge.copyWith(fontFamily: fontFamily),
      labelMedium: labelMedium.copyWith(fontFamily: fontFamily),
      labelSmall: labelSmall.copyWith(fontFamily: fontFamily),
    );
  }
}
