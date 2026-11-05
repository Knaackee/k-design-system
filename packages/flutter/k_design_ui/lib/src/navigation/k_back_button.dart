import 'package:flutter/widgets.dart';

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
    return KIconButton(
      label: label,
      icon: rtl ? KIconName.chevronRight : KIconName.chevronLeft,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}
