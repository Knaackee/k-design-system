import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../forms/form_style.dart';
import '../primitives/k_icon.dart';

TextStyle pickerTextStyle(BuildContext context, {Color? color}) {
  final style = formTextStyle(context, color: color);
  final scaled = MediaQuery.textScalerOf(context).scale(style.fontSize!);
  return style.copyWith(height: scaled.round() / scaled);
}

class PickerAction extends StatelessWidget {
  const PickerAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
    this.focusNode,
    this.selected = false,
    this.muted = false,
    this.width,
    this.height,
    this.onKeyEvent,
    super.key,
  });
  final String label;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final KIconName? icon;
  final FocusNode? focusNode;
  final bool selected, muted;
  final double? width, height;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent;
  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    return Focus(
      onKeyEvent: onKeyEvent,
      child: SizedBox(
        width: width,
        height: height,
        child: TextButton(
          focusNode: focusNode,
          onPressed: onPressed,
          style: ButtonStyle(
            visualDensity: VisualDensity.standard,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: WidgetStatePropertyAll(
              Size(0, height ?? math.max(t.sizeControl, t.sizeHitTarget)),
            ),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(
                vertical: height == null ? 1 : 0,
                horizontal: icon != null || width != null
                    ? 0
                    : t.spaceControlInsetInline + 1,
              ),
            ),
            foregroundColor: WidgetStatePropertyAll(
              selected
                  ? t.colorActionPrimaryForeground
                  : muted
                  ? t.colorTextMuted
                  : height == null
                  ? t.colorActionGhostForeground
                  : t.colorTextPrimary,
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => selected
                  ? t.colorActionPrimaryBackground
                  : states.contains(WidgetState.hovered)
                  ? t.colorActionGhostHover
                  : Colors.transparent,
            ),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.focused)
                    ? t.colorBorderFocus
                    : Colors.transparent,
                width: states.contains(WidgetState.focused) ? 2 : 1,
              ),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radiusControl),
              ),
            ),
            textStyle: WidgetStatePropertyAll(
              height == null
                  ? formTextStyle(context)
                  : pickerTextStyle(context),
            ),
          ),
          child: Opacity(
            opacity: onPressed == null ? .48 : 1,
            child: Semantics(
              selected: selected,
              child: icon == null
                  ? Text(
                      label,
                      semanticsLabel: semanticLabel,
                      textAlign: TextAlign.center,
                    )
                  : KIcon(icon!, label: label),
            ),
          ),
        ),
      ),
    );
  }
}
