import 'package:flutter/material.dart';
import '../theme/flux_theme.dart';

enum FluxCardVariant {
  elevated,
  filled,
  outlined,
}

/// A card component for FluxUI.
///
/// Features:
/// - Variants: elevated (shadow), filled (flat color), outlined (border)
/// - Customizable padding and tap behavior
class FluxCard extends StatelessWidget {
  final Widget child;
  final FluxCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const FluxCard({
    super.key,
    required this.child,
    this.variant = FluxCardVariant.elevated,
    this.padding,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluxTheme.of(context);
    final colors = theme.colorScheme;
    
    final effectivePadding = padding ?? const EdgeInsets.all(FluxSpacing.md);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(FluxRadius.md),
      side: variant == FluxCardVariant.outlined
          ? BorderSide(color: colors.outlineVariant)
          : BorderSide.none,
    );

    Color? color;
    double? elevation;
    
    switch (variant) {
      case FluxCardVariant.elevated:
        color = backgroundColor ?? colors.surface;
        elevation = 1;
        break;
      case FluxCardVariant.filled:
        color = backgroundColor ?? colors.surfaceVariant.withValues(alpha: 0.4);
        elevation = 0;
        break;
      case FluxCardVariant.outlined:
        color = backgroundColor ?? Colors.transparent;
        elevation = 0;
        break;
    }

    Widget card = Card(
      color: color,
      elevation: elevation,
      shape: shape,
      margin: EdgeInsets.zero, // FluxCard manages its own spacing externally usually
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
    
    return card;
  }
}
