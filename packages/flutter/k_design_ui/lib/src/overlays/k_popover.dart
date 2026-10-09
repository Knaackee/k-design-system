import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

class KPopover extends StatefulWidget {
  const KPopover({
    required this.trigger,
    required this.content,
    this.label = 'Open popover',
    this.openOnLongPress = false,
    this.belowAnchor = false,
    this.showArrow = false,
    this.anchorKey,
    super.key,
  });
  final Widget trigger, content;
  final String label;
  final bool openOnLongPress, belowAnchor;
  final bool showArrow;
  final GlobalKey? anchorKey;
  @override
  State<KPopover> createState() => _KPopoverState();
}

class _KPopoverState extends State<KPopover> {
  final _focus = FocusNode();
  bool _focused = false, _open = false;
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _show() async {
    if (_open) return;
    _open = true;
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final box =
        (widget.anchorKey?.currentContext ?? context).findRenderObject()!
            as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    // The gallery can embed its Navigator away from the window origin.
    // showMenu positions relative to that overlay, not the whole screen.
    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final anchor = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      box.size.width,
      box.size.height,
    );
    final width =
        (overlay.size.width - 2 * tokens.componentPopoverViewportInset).clamp(
          0.0,
          tokens.componentPopoverMaxWidth,
        );
    final x = (anchor.center.dx - width / 2).clamp(
      tokens.componentPopoverViewportInset,
      overlay.size.width - tokens.componentPopoverViewportInset - width,
    );
    final y = widget.belowAnchor
        ? anchor.bottom + (widget.showArrow ? 0 : tokens.spaceControlGap)
        : anchor.top;
    final availableHeight =
        (overlay.size.height -
                (widget.showArrow
                    ? y + tokens.componentPopoverViewportInset
                    : 2 * tokens.componentPopoverViewportInset))
            .clamp(tokens.sizeHitTarget, tokens.layoutOverlayMaxHeight);
    await showMenu<bool>(
      context: context,
      position: RelativeRect.fromLTRB(
        x,
        y,
        overlay.size.width - x - width,
        overlay.size.height - y,
      ),
      elevation: 0,
      color: Colors.transparent,
      menuPadding: EdgeInsets.zero,
      clipBehavior: Clip.none,
      constraints: BoxConstraints(maxWidth: width, maxHeight: availableHeight),
      items: [
        PopupMenuItem<bool>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: widget.showArrow ? tokens.spaceControlGap : 0,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.colorSurfaceRaised,
                    border: Border.all(
                      color: tokens.colorBorderDefault,
                      width: tokens.borderWidthDefault,
                    ),
                    borderRadius: BorderRadius.circular(tokens.radiusOverlay),
                    boxShadow: tokens.elevationPopover,
                  ),
                  child: Container(
                    width: width,
                    constraints: BoxConstraints(
                      maxHeight:
                          availableHeight -
                          (widget.showArrow ? tokens.spaceControlGap : 0),
                    ),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        color: tokens.colorTextPrimary,
                        fontFamily: tokens.fontFamily,
                      ),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: widget.content,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.showArrow)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: tokens.spaceControlGap + tokens.borderWidthDefault,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _PopoverArrow(
                        center: (anchor.center.dx - x).clamp(
                          tokens.spaceLayoutGutter,
                          width - tokens.spaceLayoutGutter,
                        ),
                        radius: tokens.spaceControlGap,
                        fill: tokens.colorSurfaceRaised,
                        border: tokens.colorBorderDefault,
                        stroke: tokens.borderWidthDefault,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    if (mounted) {
      _open = false;
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      button: true,
      label: widget.label,
      child: FocusableActionDetector(
        focusNode: _focus,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              unawaited(_show());
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => unawaited(_show()),
          onLongPress: widget.openOnLongPress ? () => unawaited(_show()) : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: _focused
                  ? Border.all(
                      color: tokens.colorBorderFocus,
                      width: tokens.borderWidthStrong,
                    )
                  : null,
              borderRadius: BorderRadius.circular(tokens.radiusControl),
            ),
            child: widget.trigger,
          ),
        ),
      ),
    );
  }
}

class _PopoverArrow extends CustomPainter {
  const _PopoverArrow({
    required this.center,
    required this.radius,
    required this.fill,
    required this.border,
    required this.stroke,
  });
  final double center, radius, stroke;
  final Color fill, border;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(center - radius, size.height)
      ..lineTo(center, stroke / 2)
      ..lineTo(center + radius, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    final edge = Path()
      ..moveTo(center - radius, size.height)
      ..lineTo(center, stroke / 2)
      ..lineTo(center + radius, size.height);
    canvas.drawPath(
      edge,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_PopoverArrow old) =>
      old.center != center ||
      old.radius != radius ||
      old.fill != fill ||
      old.border != border ||
      old.stroke != stroke;
}
