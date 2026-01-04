import 'package:flutter/material.dart';
import '../theme/flux_theme.dart';

enum FluxButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  ghost,
}

enum FluxButtonSize {
  sm,
  md,
  lg,
}

/// A flexible button component for FluxUI.
///
/// Supports multiple variants (primary, secondary, outlined, text, ghost)
/// and sizes (sm, md, lg). Handles loading state and disabled state.
class FluxButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final FluxButtonVariant variant;
  final FluxButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final bool isFullWidth;

  const FluxButton({
    super.key,
    this.label,
    this.icon,
    this.onTap,
    this.variant = FluxButtonVariant.primary,
    this.size = FluxButtonSize.md,
    this.isLoading = false,
    this.isDisabled = false,
    this.isFullWidth = false,
  }) : assert(label != null || icon != null, 'Label or icon must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = FluxTheme.of(context);
    final colors = theme.colorScheme;

    // Determine effective callback
    final effectiveOnTap = (isDisabled || isLoading) ? null : onTap;

    Widget buttonContent = _buildContent(theme);

    if (isLoading) {
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: _getSpinnerSize(),
            height: _getSpinnerSize(),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _getContentColor(colors),
            ),
          ),
          if (label != null) ...[
            SizedBox(width: FluxSpacing.sm),
            Text(label!),
          ],
        ],
      );
    }

    ButtonStyle style = _getButtonStyle(theme);

    Widget button;
    switch (variant) {
      case FluxButtonVariant.primary:
      case FluxButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: effectiveOnTap,
          style: style,
          child: buttonContent,
        );
        break;
      case FluxButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: effectiveOnTap,
          style: style,
          child: buttonContent,
        );
        break;
      case FluxButtonVariant.text:
      case FluxButtonVariant.ghost:
        button = TextButton(
          onPressed: effectiveOnTap,
          style: style,
          child: buttonContent,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }

  Widget _buildContent(FluxTheme theme) {
    if (icon != null && label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          SizedBox(width: FluxSpacing.sm),
          Text(label!),
        ],
      );
    } else if (icon != null) {
      return Icon(icon, size: _getIconSize());
    } else {
      return Text(label!);
    }
  }

  double _getIconSize() {
    switch (size) {
      case FluxButtonSize.sm:
        return 16.0;
      case FluxButtonSize.md:
        return 20.0;
      case FluxButtonSize.lg:
        return 24.0;
    }
  }

  double _getSpinnerSize() {
    switch (size) {
      case FluxButtonSize.sm:
        return 12.0;
      case FluxButtonSize.md:
        return 16.0;
      case FluxButtonSize.lg:
        return 20.0;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case FluxButtonSize.sm:
        return const EdgeInsets.symmetric(
            horizontal: FluxSpacing.md, vertical: FluxSpacing.xs);
      case FluxButtonSize.md:
        return const EdgeInsets.symmetric(
            horizontal: FluxSpacing.lg, vertical: FluxSpacing.sm);
      case FluxButtonSize.lg:
        return const EdgeInsets.symmetric(
            horizontal: FluxSpacing.xl, vertical: FluxSpacing.md);
    }
  }

  TextStyle _getTextStyle(FluxTheme theme) {
    switch (size) {
      case FluxButtonSize.sm:
        return theme.typography.labelSmall;
      case FluxButtonSize.md:
        return theme.typography.labelMedium;
      case FluxButtonSize.lg:
        return theme.typography.labelLarge;
    }
  }

  Color _getContentColor(FluxColorScheme colors) {
    if (isDisabled) return colors.onSurface.withValues(alpha: 0.38);

    switch (variant) {
      case FluxButtonVariant.primary:
        return colors.onPrimary;
      case FluxButtonVariant.secondary:
        return colors.onSecondary;
      case FluxButtonVariant.outlined:
        return colors.primary;
      case FluxButtonVariant.text:
        return colors.primary;
      case FluxButtonVariant.ghost:
        return colors.onSurface;
    }
  }

  Color? _getBackgroundColor(FluxColorScheme colors) {
    if (isDisabled) return colors.onSurface.withValues(alpha: 0.12);

    switch (variant) {
      case FluxButtonVariant.primary:
        return colors.primary;
      case FluxButtonVariant.secondary:
        return colors.secondary;
      case FluxButtonVariant.outlined:
        return null;
      case FluxButtonVariant.text:
        return null;
      case FluxButtonVariant.ghost:
        return null; // Transparent initially
    }
  }

  ButtonStyle _getButtonStyle(FluxTheme theme) {
    final colors = theme.colorScheme;
    final contentColor = _getContentColor(colors);
    final backgroundColor = _getBackgroundColor(colors);

    return ButtonStyle(
      padding: WidgetStateProperty.all(_getPadding()),
      textStyle: WidgetStateProperty.all(_getTextStyle(theme)),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.onSurface.withValues(alpha: 0.12);
        }
        if (variant == FluxButtonVariant.ghost &&
            states.contains(WidgetState.hovered)) {
          return colors.surfaceVariant.withValues(alpha: 0.5);
        }
        return backgroundColor;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.onSurface.withValues(alpha: 0.38);
        }
        return contentColor;
      }),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FluxRadius.full)),
      ),
      side: variant == FluxButtonVariant.outlined
          ? WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return BorderSide(
                    color: colors.onSurface.withValues(alpha: 0.12));
              }
              return BorderSide(color: colors.outline);
            })
          : null,
      elevation: WidgetStateProperty.all(0),
    );
  }
}
