import 'package:flutter/material.dart';
import '../theme/flux_theme.dart';

enum FluxBadgeVariant {
  dot,
  count,
  label,
}

/// A badge component for FluxUI.
///
/// Used to display notifications, counts, or status labels.
/// Features:
/// - Variants: dot (small circle), count (number), label (text)
/// - Auto-truncated counts (99+)
class FluxBadge extends StatelessWidget {
  final FluxBadgeVariant variant;
  final String? label;
  final int? count;
  final Color? color;
  final Color? textColor;
  final Widget? child;
  final Alignment alignment;
  final Offset offset;

  const FluxBadge({
    super.key,
    this.variant = FluxBadgeVariant.dot,
    this.label,
    this.count,
    this.color,
    this.textColor,
    this.child,
    this.alignment = Alignment.topRight,
    this.offset = const Offset(4, -4),
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluxTheme.of(context);
    final colors = theme.colorScheme;
    final typography = theme.typography;

    final badgeColor = color ?? colors.error;
    final onBadgeColor = textColor ?? colors.onError;

    Widget badgeContent;
    BoxConstraints constraints;
    BorderRadius borderRadius;
    EdgeInsets padding;

    switch (variant) {
      case FluxBadgeVariant.dot:
        badgeContent = const SizedBox();
        constraints = const BoxConstraints(minWidth: 8, minHeight: 8);
        borderRadius = BorderRadius.circular(4);
        padding = EdgeInsets.zero;
        break;
      case FluxBadgeVariant.count:
        final displayCount = count != null && count! > 99 ? '99+' : count.toString();
        badgeContent = Text(
          displayCount,
          style: typography.labelSmall.copyWith(
            color: onBadgeColor,
            fontSize: 10,
            height: 1,
          ),
          textAlign: TextAlign.center,
        );
        constraints = const BoxConstraints(minWidth: 16, minHeight: 16);
        borderRadius = BorderRadius.circular(8);
        padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 2);
        break;
      case FluxBadgeVariant.label:
        badgeContent = Text(
          label ?? '',
          style: typography.labelSmall.copyWith(
            color: onBadgeColor,
            fontSize: 10,
            height: 1,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        );
        constraints = const BoxConstraints(minWidth: 16, minHeight: 16);
        borderRadius = BorderRadius.circular(FluxRadius.sm);
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        break;
    }

    final badge = Container(
      constraints: constraints,
      padding: padding,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: borderRadius,
        border: Border.all(color: colors.background, width: 1.5), // white border for separation
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: badgeContent,
      ),
    );

    if (child != null) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: alignment,
        children: [
          child!,
          Positioned(
            // Logic to position based on alignment and offset
            // Simple offset application generally works with Stack alignment
            // but precise corner positioning might need calculation.
            // Here assuming standard corner usage.
            right: alignment.x > 0 ? -offset.dx : null,
            left: alignment.x < 0 ? -offset.dx : null,
            top: alignment.y < 0 ? offset.dy : null,
            bottom: alignment.y > 0 ? offset.dy : null,
            child: badge,
          ),
        ],
      );
    }

    return badge;
  }
}
