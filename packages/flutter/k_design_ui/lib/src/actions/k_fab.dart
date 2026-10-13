import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../chat/k_chat_bubble.dart';
import 'k_fab_attention.dart';

enum KFabActivation { press, longPress }

class KFabItem {
  const KFabItem({
    required this.id,
    required this.label,
    required this.child,
    required this.onSelected,
  });
  final String id, label;
  final Widget child;
  final VoidCallback? onSelected;
}

/// Generic floating action group. Placement and content belong to the consumer.
class KFab extends StatefulWidget {
  const KFab({
    required this.label,
    required this.child,
    required this.items,
    this.activation = KFabActivation.press,
    this.onPressed,
    this.open,
    this.onOpenChanged,
    this.visible = true,
    this.size = 64,
    this.clipBehavior = Clip.antiAlias,
    this.itemGap = 8,
    this.style,
    this.attention = const [],
    this.attentionShowDuration = const Duration(milliseconds: 1800),
    this.attentionPauseDuration = const Duration(milliseconds: 7000),
    this.attentionPeekFraction = 0.5,
    this.attentionHoldDuration = const Duration(milliseconds: 324),
    this.onAttentionSelect,
    super.key,
  });
  final String label;
  final Widget child;
  final List<KFabItem> items;
  final KFabActivation activation;
  final VoidCallback? onPressed;
  final bool? open;
  final ValueChanged<bool>? onOpenChanged;
  final bool visible;
  final double size;
  final Clip clipBehavior;
  final double itemGap;
  final ButtonStyle? style;
  final List<KFabAttention> attention;
  final Duration attentionShowDuration;
  final Duration attentionPauseDuration;
  final double attentionPeekFraction;
  final Duration attentionHoldDuration;
  final ValueChanged<KFabAttention>? onAttentionSelect;
  @override
  State<KFab> createState() => _KFabState();
}

class _KFabState extends State<KFab> {
  final _anchor = GlobalKey();
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  bool _localOpen = false;
  bool get _open =>
      widget.visible && widget.items.isNotEmpty && (widget.open ?? _localOpen);
  void _change(bool value) {
    setState(() => _localOpen = value);
    widget.onOpenChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final dimension = math.max(widget.size, tokens.sizeHitTarget);
    final peek = widget.attentionPeekFraction.isFinite
        ? widget.attentionPeekFraction.clamp(0.0, 1.0)
        : 0.5;
    final hasAttention =
        widget.visible &&
        widget.attention.any(
          (notice) => widget.items.any(
            (item) => item.id == notice.itemId && item.onSelected != null,
          ),
        );
    final itemGap = widget.itemGap.isFinite
        ? (widget.itemGap < 0 ? 0.0 : widget.itemGap)
        : 8.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _portal.show();
    });
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        final box = _anchor.currentContext!.findRenderObject()! as RenderBox;
        final overlay =
            Overlay.of(context).context.findRenderObject()! as RenderBox;
        final top = box.localToGlobal(Offset.zero, ancestor: overlay).dy;
        return IgnorePointer(
          ignoring: !_open,
          child: ExcludeSemantics(
            excluding: !_open,
            child: ExcludeFocus(
              excluding: !_open,
              child: TickerMode(
                enabled: _open,
                child: Offstage(
                  offstage: !_open,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _change(false),
                          onSecondaryTap: () => _change(false),
                        ),
                      ),
                      CompositedTransformFollower(
                        link: _link,
                        showWhenUnlinked: false,
                        targetAnchor: Alignment.topRight,
                        followerAnchor: Alignment.bottomRight,
                        offset: Offset(
                          tokens.spaceLayoutGutter,
                          -itemGap + tokens.spaceLayoutGutter,
                        ),
                        child: CallbackShortcuts(
                          bindings: {
                            const SingleActivator(
                              LogicalKeyboardKey.escape,
                            ): () =>
                                _change(false),
                          },
                          child: Focus(
                            autofocus: _open,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: _open ? 1 : 0),
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : tokens.motionEmphasis,
                              builder: (_, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * itemGap),
                                  child: child,
                                ),
                              ),
                              child: SizedBox(
                                width:
                                    math.max(
                                      widget.size,
                                      tokens.sizeHitTarget,
                                    ) +
                                    2 * tokens.spaceLayoutGutter,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: math.max(
                                      0,
                                      top - itemGap - tokens.spaceControlGap,
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.all(
                                      tokens.spaceLayoutGutter,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        for (
                                          var i = 0;
                                          i < widget.items.length;
                                          i++
                                        ) ...[
                                          if (i > 0) SizedBox(height: itemGap),
                                          KChatBubble(
                                            key: ValueKey(widget.items[i].id),
                                            label: widget.items[i].label,
                                            size: widget.size,
                                            clipBehavior: widget.clipBehavior,
                                            style:
                                                widget.attention.any(
                                                  (notice) =>
                                                      notice.itemId ==
                                                      widget.items[i].id,
                                                )
                                                ? ButtonStyle(
                                                    side: WidgetStatePropertyAll(
                                                      BorderSide(
                                                        color: tokens
                                                            .colorBorderFocus,
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                            onPressed:
                                                widget.items[i].onSelected ==
                                                    null
                                                ? null
                                                : () {
                                                    _change(false);
                                                    widget
                                                        .items[i]
                                                        .onSelected!();
                                                  },
                                            child: widget.items[i].child,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: SizedBox(
        width: dimension,
        height: dimension * (1 + (hasAttention ? peek : 0)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: KFabAttentionBubble(
                notices: widget.attention,
                clipBehavior: widget.clipBehavior,
                items: widget.items,
                size: widget.size,
                active: widget.visible && !_open,
                showDuration: widget.attentionShowDuration,
                pauseDuration: widget.attentionPauseDuration,
                peekFraction: peek,
                holdDuration: widget.attentionHoldDuration,
                onSelect: widget.onAttentionSelect,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onSecondaryTap: widget.items.isEmpty
                    ? null
                    : () => _change(!_open),
                child: CompositedTransformTarget(
                  link: _link,
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                          _change(true),
                      const SingleActivator(
                        LogicalKeyboardKey.f10,
                        shift: true,
                      ): () =>
                          _change(true),
                      const SingleActivator(LogicalKeyboardKey.escape): () =>
                          _change(false),
                    },
                    child: KChatBubble(
                      key: _anchor,
                      label: widget.label,
                      size: widget.size,
                      clipBehavior: widget.clipBehavior,
                      visible: widget.visible,
                      style: widget.style,
                      onPressed: () {
                        if (widget.activation == KFabActivation.press &&
                            widget.items.isNotEmpty) {
                          _change(!_open);
                        } else {
                          _change(false);
                          widget.onPressed?.call();
                        }
                      },
                      onLongPress:
                          widget.activation == KFabActivation.longPress &&
                              widget.items.isNotEmpty
                          ? () => _change(!_open)
                          : null,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
