import 'package:flutter/material.dart';

/// A wrapper around standard Stack for consistency in FluxUI.
class FluxStack extends StatelessWidget {
  final List<Widget> children;
  final AlignmentGeometry alignment;
  final StackFit fit;
  final Clip clipBehavior;

  const FluxStack({
    super.key,
    this.children = const <Widget>[],
    this.alignment = AlignmentDirectional.topStart,
    this.fit = StackFit.loose,
    this.clipBehavior = Clip.hardEdge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: alignment,
      fit: fit,
      clipBehavior: clipBehavior,
      children: children,
    );
  }
}
