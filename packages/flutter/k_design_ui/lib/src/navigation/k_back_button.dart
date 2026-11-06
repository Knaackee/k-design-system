import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_context_menu.dart';
import '../actions/k_icon_button.dart';
import '../actions/k_menu_button.dart';
import '../generated/k_icons.g.dart';

/// Standard back control (Decision 0012, Apple HIG Toolbars): the back
/// chevron alone, at the leading edge of the top bar. Never a text label
/// such as "Back"; [label] names the destination for assistive technology
/// ("Back to Portfolios"). The chevron mirrors in right-to-left layouts.
///
/// Without [onPressed] it pops the current route (`Navigator.maybePop`),
/// which respects `PopScope` like the system back gesture.
///
/// [history] lists the levels above (root first, with icons). A long press
/// or secondary click opens them as a menu, as the iOS back button does;
/// this replaces breadcrumbs on phones (Decision 0015).
class KBackButton extends StatelessWidget {
  const KBackButton({
    required this.label,
    this.onPressed,
    this.history = const [],
    super.key,
  });

  /// Accessible name including the destination, e.g. "Back to Portfolios".
  final String label;
  final VoidCallback? onPressed;

  /// Levels above the current screen, root first.
  final List<KMenuAction> history;

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
    final withHistory = history.isEmpty
        ? button
        : KContextMenu(label: label, actions: history, child: button);
    if (style != KStyle.apple) return withHistory;
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
        child: Center(child: withHistory),
      ),
    );
  }
}
