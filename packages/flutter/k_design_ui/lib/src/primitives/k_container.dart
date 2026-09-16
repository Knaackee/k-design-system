import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

class KContainer extends StatelessWidget {
  const KContainer({required this.child, this.maxWidth = 760, super.key});
  final Widget child;

  /// Maximum content width, excluding token-backed horizontal gutters.
  final double maxWidth;
  @override
  Widget build(BuildContext context) {
    if (!maxWidth.isFinite || maxWidth <= 0) {
      throw ArgumentError.value(
        maxWidth,
        'maxWidth',
        'Must be positive and finite',
      );
    }
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          throw FlutterError('KContainer requires a bounded width');
        }
        final gutter = math.min(
          tokens.spaceLayoutGutter,
          constraints.maxWidth / 2,
        );
        final width = math.min(
          maxWidth,
          math.max(0.0, constraints.maxWidth - 2 * gutter),
        );
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 1,
            child: SizedBox(width: width, child: child),
          ),
        );
      },
    );
  }
}
