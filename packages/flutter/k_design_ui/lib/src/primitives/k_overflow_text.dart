import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

/// Internal single-line text with full content on hover, long press and focus.
/// Interactive parents own focus; plain table text gets its own focus stop.
class KOverflowText extends StatefulWidget {
  const KOverflowText({required this.text, this.focusable = true, super.key});
  final Text text;
  final bool focusable;

  @override
  State<KOverflowText> createState() => _KOverflowTextState();
}

class _KOverflowTextState extends State<KOverflowText> {
  final _tooltip = GlobalKey<TooltipState>();
  bool _focused = false;
  bool _shownForFocus = false;

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final defaults = DefaultTextStyle.of(context);
    final focused = widget.focusable ? _focused : Focus.of(context).hasFocus;
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(
            text: text.data,
            children: text.textSpan == null ? null : [text.textSpan!],
            style: defaults.style.merge(text.style),
          ),
          textDirection: text.textDirection ?? Directionality.of(context),
          textScaler: text.textScaler ?? MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout(maxWidth: constraints.maxWidth);
        final clipped =
            painter.didExceedMaxLines || painter.width > constraints.maxWidth;
        painter.dispose();
        final show = clipped && focused;
        if (show != _shownForFocus) {
          _shownForFocus = show;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_shownForFocus) {
              _tooltip.currentState?.ensureTooltipVisible();
            } else {
              Tooltip.dismissAllToolTips();
            }
          });
        }
        final child = DefaultTextStyle.merge(
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          child: text,
        );
        if (!clipped) return child;
        return Focus(
          canRequestFocus: widget.focusable,
          skipTraversal: !widget.focusable,
          onFocusChange: (value) => setState(() => _focused = value),
          child: Tooltip(
            key: _tooltip,
            message: text.data ?? text.textSpan!.toPlainText(),
            excludeFromSemantics: true,
            decoration: BoxDecoration(
              color: tokens.colorSurfaceRaised,
              border: Border.all(
                color: tokens.colorBorderDefault,
                width: tokens.borderWidthDefault,
              ),
              borderRadius: BorderRadius.circular(tokens.radiusOverlay),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceControlInsetInline,
              vertical: tokens.spaceControlGap,
            ),
            textStyle: TextStyle(
              fontFamily: tokens.fontFamily,
              fontSize: tokens.fontBodySize,
              height: tokens.fontBodyLineHeight / tokens.fontBodySize,
              color: tokens.colorTextPrimary,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
