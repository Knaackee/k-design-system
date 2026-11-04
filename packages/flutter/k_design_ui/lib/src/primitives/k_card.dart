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

  /// Whether [context] is inside a [KCard].
  static bool isInside(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_KCardScope>() != null;

  @override
  Widget build(BuildContext context) {
    assert(
      !isInside(context),
      'Nested KCard (Decision 0010): a card must not contain another card. '
      'Inside a card use separators, a grouped list or a KStack section; '
      'move independent content into a sibling card.',
    );
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return _KCardScope(
      child: KSurface(
        tone: tone,
        radius: KSurfaceRadius.card,
        elevation: elevation,
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceCardPadding),
          child: child,
        ),
      ),
    );
  }
}

class _KCardScope extends InheritedWidget {
  const _KCardScope({required super.child});

  @override
  bool updateShouldNotify(_KCardScope oldWidget) => false;
}
