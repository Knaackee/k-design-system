import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_icon.dart';

enum KLinkVariant { inline, standalone }

class KLink extends StatefulWidget {
  const KLink({
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.external = false,
    this.variant = KLinkVariant.inline,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final bool external;
  final KLinkVariant variant;

  @override
  State<KLink> createState() => _KLinkState();
}

class _KLinkState extends State<KLink> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final enabled = widget.onPressed != null;
    final color = !enabled
        ? t.colorTextMuted
        : _pressed
        ? t.colorActionPrimaryPressed
        : _hovered
        ? t.colorStatusInfoForeground
        : t.colorStatusInfoAccent;
    final standalone = widget.variant == KLinkVariant.standalone;
    return Semantics(
      link: true,
      enabled: enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          child: AnimatedContainer(
            duration: t.motionFast,
            constraints: standalone
                ? BoxConstraints(minHeight: t.sizeHitTarget)
                : const BoxConstraints(),
            padding: EdgeInsets.symmetric(
              horizontal: standalone ? t.spaceControlGap : 0,
              vertical: t.borderWidthStrong,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: _focused ? t.colorBorderFocus : Colors.transparent,
                width: t.borderWidthStrong,
              ),
              borderRadius: BorderRadius.circular(t.radiusSmall),
            ),
            child: IconTheme(
              data: IconThemeData(color: color, size: 16),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: color,
                  fontFamily: t.fontFamily,
                  fontSize: t.fontBodySmallSize,
                  fontWeight: t.fontLabelWeight,
                  decoration: TextDecoration.underline,
                  decorationThickness: _hovered ? 2 : 1,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.leading != null) ...[
                      widget.leading!,
                      SizedBox(width: t.spaceTight),
                    ],
                    Flexible(child: Text(widget.label)),
                    if (widget.trailing != null || widget.external) ...[
                      SizedBox(width: t.spaceTight),
                      widget.trailing ?? const KIcon(KIconName.externalLink),
                    ],
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
