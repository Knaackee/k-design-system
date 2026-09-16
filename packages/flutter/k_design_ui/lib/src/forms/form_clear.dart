import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../primitives/k_icon.dart';
import 'form_style.dart';

// A web semantics button can take DOM focus while Flutter still considers the
// editable focused. A real focus transition reopens its native input connection.
void restoreFormFocus(FocusNode focus, bool Function() isMounted) {
  focus.unfocus();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (isMounted()) focus.requestFocus();
  });
}

class KFormClear extends StatefulWidget {
  const KFormClear({required this.label, required this.onPressed, super.key});
  final String label;
  final VoidCallback onPressed;
  @override
  State<KFormClear> createState() => _KFormClearState();
}

class _KFormClearState extends State<KFormClear> {
  final _focus = FocusNode();
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  bool _hovered = false;
  bool _focused = false;
  bool _focusVisible = false;
  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    return TextFieldTapRegion(
      child: Semantics(
        container: true,
        button: true,
        focusable: true,
        onFocus: _focus.requestFocus,
        focused: _focused,
        label: widget.label,
        onTap: widget.onPressed,
        child: Tooltip(
          message: widget.label,
          excludeFromSemantics: true,
          child: FocusableActionDetector(
            includeFocusSemantics: false,
            focusNode: _focus,
            onFocusChange: (focused) => setState(() => _focused = focused),
            onShowFocusHighlight: (visible) =>
                setState(() => _focusVisible = visible),
            onShowHoverHighlight: (hovered) =>
                setState(() => _hovered = hovered),
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onPressed();
                  return null;
                },
              ),
            },
            child: GestureDetector(
              excludeFromSemantics: true,
              behavior: HitTestBehavior.opaque,
              onTap: widget.onPressed,
              child: Container(
                width: math.max(24, t.sizeHitTarget),
                height: math.max(t.sizeControl, t.sizeHitTarget),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(t.radiusControl),
                  border: _focusVisible
                      ? Border.all(color: t.colorBorderFocus, width: 2)
                      : null,
                ),
                child: KIcon(
                  KIconName.x,
                  color: _hovered ? t.colorTextPrimary : t.colorTextMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KFormClearOverlay extends StatelessWidget {
  const KFormClearOverlay({
    required this.child,
    required this.label,
    required this.onPressed,
    this.right = 1,
    super.key,
  });
  final Widget child;
  final String label;
  final VoidCallback? onPressed;
  final double right;
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      child,
      if (onPressed != null)
        Positioned(
          right: right,
          child: KFormClear(label: label, onPressed: onPressed!),
        ),
    ],
  );
}
