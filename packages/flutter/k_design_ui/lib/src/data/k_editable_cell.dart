import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

/// Consumer-controlled inline editing; the supplied editor owns draft/commit.
class KEditableCell extends StatefulWidget {
  const KEditableCell({
    required this.label,
    required this.display,
    required this.editor,
    this.editing = false,
    this.paddingInline,
    this.onEdit,
    super.key,
  });
  final String label;
  final Widget display;
  final Widget editor;
  final bool editing;
  final double? paddingInline;
  final VoidCallback? onEdit;
  @override
  State<KEditableCell> createState() => _KEditableCellState();
}

class _KEditableCellState extends State<KEditableCell> {
  final _triggerFocus = FocusNode();
  final _editorFocus = FocusNode(skipTraversal: true, canRequestFocus: false);
  bool _suppressRestore = false;

  void _outsideEditor(PointerDownEvent event) {
    _suppressRestore = true;
    if (_editorFocus.hasFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  void didUpdateWidget(covariant KEditableCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.editing && widget.editing) _suppressRestore = false;
    if (oldWidget.editing && !widget.editing && widget.onEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            widget.editing ||
            widget.onEdit == null ||
            _suppressRestore) {
          return;
        }
        FocusManager.instance.applyFocusChangesIfNeeded();
        final current = FocusManager.instance.primaryFocus;
        if (current == null || current is FocusScopeNode) {
          _triggerFocus.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _editorFocus.dispose();
    _triggerFocus.dispose();
    super.dispose();
  }

  bool _focused = false;
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    if (widget.label.trim().isEmpty) {
      throw ArgumentError('KEditableCell requires a nonempty label');
    }
    if (widget.editing) {
      return TapRegion(
        onTapOutside: _outsideEditor,
        child: Focus(focusNode: _editorFocus, child: widget.editor),
      );
    }
    if (widget.onEdit == null) return widget.display;
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    return TapRegion(
      onTapOutside: (_) {
        if (_triggerFocus.hasFocus) _triggerFocus.unfocus();
      },
      child: Semantics(
        button: true,
        label: widget.label,
        child: FocusableActionDetector(
          focusNode: _triggerFocus,
          mouseCursor: SystemMouseCursors.click,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          onShowHoverHighlight: (value) => setState(() => _hovered = value),
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onEdit!();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onEdit,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: math.max(t.sizeControl, t.sizeHitTarget),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: widget.paddingInline ?? t.spaceControlInsetInline,
                vertical: t.borderWidthDefault,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(t.radiusControl),
                border: Border.all(
                  width: t.borderWidthDefault,
                  color: _focused
                      ? t.colorBorderFocus
                      : _hovered
                      ? t.colorBorderDefault
                      : Colors.transparent,
                ),
              ),
              alignment: switch (DefaultTextStyle.of(context).textAlign) {
                TextAlign.end => AlignmentDirectional.centerEnd,
                TextAlign.right => Alignment.centerRight,
                TextAlign.center => Alignment.center,
                TextAlign.left => Alignment.centerLeft,
                _ => AlignmentDirectional.centerStart,
              },
              child: DefaultTextStyle(
                style: TextStyle(
                  fontFamily: t.fontFamily,
                  fontSize: t.fontBodySize,
                  fontWeight: t.fontBodyWeight,
                  height: t.fontBodyLineHeight / t.fontBodySize,
                  leadingDistribution: TextLeadingDistribution.even,
                  letterSpacing: t.fontBodyLetterSpacing,
                  color: t.colorTextPrimary,
                  fontVariations: [
                    FontVariation.weight(t.fontBodyWeight.value.toDouble()),
                    FontVariation.opticalSize(
                      MediaQuery.textScalerOf(
                        context,
                      ).scale(t.fontBodySize).clamp(14, 32),
                    ),
                  ],
                ),
                child: widget.display,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
