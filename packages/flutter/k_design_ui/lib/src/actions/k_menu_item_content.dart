import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_icon.dart';
import 'k_menu_button.dart';

// Material reserves this gap even when SubmenuButton's native arrow is empty.
// Reserve it in every row so labels and our trailing indicators share one grid.
double _nativeSubmenuGap(BuildContext context) =>
    math.max(4, 12 + Theme.of(context).visualDensity.horizontal * 2);

double menuContentWidth(
  BuildContext context,
  List<KMenuAction> actions,
  double available,
) {
  final t =
      Theme.of(context).extension<KDesignTokens>() ?? KDesignTokens.orbitLight;
  var labelWidth = 0.0;
  void measure(List<KMenuAction> items) {
    for (final item in items) {
      final painter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: TextStyle(
            fontFamily: t.fontFamily,
            fontSize: t.fontControlSize,
            fontWeight: t.fontControlWeight,
            letterSpacing: -.01 * t.fontControlSize,
          ),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      labelWidth = math.max(labelWidth, painter.width);
      painter.dispose();
      measure(item.children);
    }
  }

  measure(actions);
  final chrome =
      2 *
          (t.spaceControlGap +
              t.spaceControlInsetInline +
              t.borderWidthDefault) +
      2 * t.componentContextMenuIconSize +
      2 * t.spaceControlGap +
      _nativeSubmenuGap(context);
  return math.min(
    math.max(t.componentContextMenuWidth, (labelWidth + chrome).ceilToDouble()),
    math.max(0, available - t.componentContextMenuViewportInset),
  );
}

class KMenuItemContent extends StatelessWidget {
  const KMenuItemContent({
    required this.action,
    required this.width,
    super.key,
  });
  final KMenuAction action;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    Widget slot(Widget? child) => SizedBox.square(
      dimension: t.componentContextMenuIconSize,
      child: child == null
          ? null
          : FittedBox(
              fit: BoxFit.contain,
              child: KIconSizeScope(
                size: t.componentContextMenuIconSize,
                child: child,
              ),
            ),
    );
    return Opacity(
      opacity: action.disabled ? .48 : 1,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        child: SizedBox(
          width: math.max(
            0,
            width -
                2 *
                    (t.spaceControlGap +
                        t.spaceControlInsetInline +
                        t.borderWidthDefault) -
                _nativeSubmenuGap(context),
          ),
          child: Row(
            children: [
              slot(
                action.iconContent ??
                    (action.icon == null
                        ? null
                        : KIcon(
                            action.icon!,
                            color: action.destructive
                                ? t.colorStatusErrorForeground
                                : t.colorTextPrimary,
                          )),
              ),
              SizedBox(width: t.spaceControlGap),
              Expanded(
                child: Semantics(
                  selected: action.checked,
                  child: Text(action.label),
                ),
              ),
              SizedBox(width: t.spaceControlGap),
              slot(
                action.children.isNotEmpty
                    ? const KIcon(KIconName.chevronRight)
                    : action.checked == true
                    ? const KIcon(KIconName.check)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
