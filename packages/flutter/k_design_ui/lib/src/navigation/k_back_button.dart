import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_icon_button.dart';
import '../generated/k_icons.g.dart';

/// Standard back control (Decision 0012, Apple HIG Toolbars): the back
/// chevron alone, at the leading edge of the top bar. Never a text label
/// such as "Back"; [label] names the destination for assistive technology
/// ("Back to Portfolios"). The chevron mirrors in right-to-left layouts.
///
/// Without [onPressed] it pops the current route (`Navigator.maybePop`),
/// which respects `PopScope` like the system back gesture.
class KBackButton extends StatelessWidget {
  const KBackButton({required this.label, this.onPressed, super.key});

  /// Accessible name including the destination, e.g. "Back to Portfolios".
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final style = KAdaptive.maybeOf(context)?.style ?? KStyle.linear;
    // Material navigates up with an arrow; Apple and linear with a chevron.
    final material = style == KStyle.material;
    final button = KIconButton(
      label: label,
      icon: material
          ? (rtl ? KIconName.arrowRight : KIconName.arrowLeft)
          : (rtl ? KIconName.chevronRight : KIconName.chevronLeft),
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
    if (style != KStyle.apple) return button;
    // iOS 26: a round 44 pt button on a raised surface over content.
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SizedBox.square(
      dimension: math.max(t.sizeHitTarget, t.componentListRowMinHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.colorSurfaceRaised,
          shape: BoxShape.circle,
          boxShadow: t.elevationLow,
        ),
        child: Center(child: button),
      ),
    );
  }
}
