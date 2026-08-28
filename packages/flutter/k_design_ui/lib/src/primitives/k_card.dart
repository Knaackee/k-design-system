import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_surface.dart';

class KCard extends StatelessWidget {
  const KCard({
    required this.child,
    this.tone = KSurfaceTone.raised,
    this.elevation = KSurfaceElevation.none,
    super.key,
  });

  final Widget child;
  final KSurfaceTone tone;
  final KSurfaceElevation elevation;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return KSurface(
      tone: tone,
      radius: KSurfaceRadius.card,
      elevation: elevation,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceCardPadding),
        child: child,
      ),
    );
  }
}
