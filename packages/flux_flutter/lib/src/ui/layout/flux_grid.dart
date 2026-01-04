import 'package:flutter/material.dart';
import '../theme/flux_spacing.dart';

/// A responsive grid that adjusts columns based on screen width.
class FluxGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? crossAxisCount;
  final double? maxCrossAxisExtent;
  final EdgeInsetsGeometry? padding;

  const FluxGrid({
    super.key,
    required this.children,
    this.spacing = FluxSpacing.md,
    this.runSpacing = FluxSpacing.md,
    this.crossAxisCount,
    this.maxCrossAxisExtent,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (crossAxisCount != null) {
      return GridView.count(
        crossAxisCount: crossAxisCount!,
        mainAxisSpacing: runSpacing,
        crossAxisSpacing: spacing,
        padding: padding,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(), // Provide predictable behavior if nested
        children: children,
      );
    }

    if (maxCrossAxisExtent != null) {
      return GridView.extent(
        maxCrossAxisExtent: maxCrossAxisExtent!,
        mainAxisSpacing: runSpacing,
        crossAxisSpacing: spacing,
        padding: padding,
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: children,
      );
    }

    // Default to responsive wrap-like grid behavior or auto-calculated
    // For simplicity, defaulting to max extent of 200 if nothing provided
    return GridView.extent(
      maxCrossAxisExtent: 200,
      mainAxisSpacing: runSpacing,
      crossAxisSpacing: spacing,
      padding: padding,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: children,
    );
  }
}
