import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../primitives/k_icon.dart';
import 'form_style.dart';

/// A nullable value displays mixed state; user activation always toggles a bool.
class KCheckbox extends StatefulWidget {
  const KCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final String label;
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  @override
  State<KCheckbox> createState() => _KCheckboxState();
}

class _KCheckboxState extends State<KCheckbox> {
  final _focusNode = FocusNode();
  bool _focused = false;
  bool _showFocus = false;
  void _activate() {
    _focusNode.requestFocus();
    _toggle();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _toggle() => widget.onChanged?.call(widget.value != true);
  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    final enabled = widget.onChanged != null;
    return Semantics(
      label: widget.label,
      checked: widget.value == true,
      mixed: widget.value == null,
      enabled: enabled,
      focusable: enabled,
      focused: _focused,
      onTap: enabled ? _activate : null,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: _focusNode,
        onFocusChange: (value) => setState(() => _focused = value),
        onShowFocusHighlight: (value) => setState(() => _showFocus = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _toggle();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? _activate : null,
          child: Opacity(
            opacity: enabled ? 1 : .48,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(t.sizeControl, t.sizeHitTarget),
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: 1,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      // Decision 0010: the box sits on the first label line (Web: 1lh).
                      padding: EdgeInsets.only(
                        top: math.max(
                          0,
                          (MediaQuery.textScalerOf(
                                        context,
                                      ).scale(t.fontControlSize) *
                                      t.fontTightHeight -
                                  t.sizeContent) /
                              2,
                        ),
                      ),
                      child: Container(
                        width: t.sizeContent,
                        height: t.sizeContent,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(t.radiusSmall),
                          color: widget.value == false
                              ? t.componentSelectionBackground
                              : t.componentSelectionSelectedBackground,
                          border: Border.all(
                            color: _showFocus
                                ? t.componentSelectionFocusRing
                                : widget.value == false
                                ? t.componentSelectionBorder
                                : t.componentSelectionSelectedBorder,
                          ),
                        ),
                        child: widget.value == false
                            ? null
                            : Center(
                                child: KIcon(
                                  widget.value == null
                                      ? KIconName.minus
                                      : KIconName.check,
                                  size: 12,
                                  color: t.componentSelectionSelectedForeground,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: t.spaceControlGap),
                    Flexible(
                      child: Text(widget.label, style: formTextStyle(context)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
