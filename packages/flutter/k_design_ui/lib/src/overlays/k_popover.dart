import 'dart:async';
import 'dart:ui' show SemanticsRole;
import 'dart:math' as math;
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
    this.onOpenChanged,
    this.anchorTransitionDuration = Duration.zero,
    super.key,
  });
  final Widget trigger, content;
  final String label;
  final bool openOnLongPress, belowAnchor;
  final bool showArrow;
  final GlobalKey? anchorKey;
  final ValueChanged<bool>? onOpenChanged;
  final Duration anchorTransitionDuration;
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
    widget.onOpenChanged?.call(true);
    if (widget.onOpenChanged != null) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
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
                (widget.showArrow &&
                        widget.anchorTransitionDuration == Duration.zero
                    ? y + tokens.componentPopoverViewportInset
                    : 2 * tokens.componentPopoverViewportInset))
            .clamp(tokens.sizeHitTarget, tokens.layoutOverlayMaxHeight);
    final menu = PopupMenuItem<bool>(
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
    );
    if (widget.anchorTransitionDuration > Duration.zero) {
      await Navigator.of(context).push<bool>(
        _AnchoredPopoverRoute(
          anchor: () {
            final currentBox =
                (widget.anchorKey?.currentContext ?? context)
                        .findRenderObject()!
                    as RenderBox;
            return currentBox.localToGlobal(Offset.zero, ancestor: overlay) &
                currentBox.size;
          },
          width: width,
          inset: tokens.componentPopoverViewportInset,
          gap: widget.belowAnchor && !widget.showArrow
              ? tokens.spaceControlGap
              : 0,
          below: widget.belowAnchor,
          motion: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : widget.anchorTransitionDuration,
          child: menu,
        ),
      );
    } else {
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
        constraints: BoxConstraints(
          maxWidth: width,
          maxHeight: availableHeight,
        ),
        items: [menu],
      );
    }
    if (mounted) {
      _open = false;
      widget.onOpenChanged?.call(false);
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

/// Uses the route's finite entrance animation to track a moving trigger.
class _AnchoredPopoverRoute extends PopupRoute<bool> {
  _AnchoredPopoverRoute({
    required this.anchor,
    required this.child,
    required this.width,
    required this.inset,
    required this.gap,
    required this.below,
    required this.motion,
  });
  final Rect Function() anchor;
  final Widget child;
  final double width, inset, gap;
  final bool below;
  final Duration motion;
  @override
  Duration get transitionDuration => motion;
  @override
  Duration get reverseTransitionDuration => Duration.zero;
  @override
  Color? get barrierColor => null;
  @override
  bool get barrierDismissible => true;
  @override
  String get barrierLabel => 'Dismiss popover';
  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Shortcuts(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
    },
    child: Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            Navigator.of(context).pop();
            return null;
          },
        ),
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, bounds) => AnimatedBuilder(
            animation: animation,
            child: Semantics(
              role: SemanticsRole.menu,
              child: Material(color: Colors.transparent, child: child),
            ),
            builder: (context, content) {
              final current = anchor();
              final edge = math.min(inset, bounds.maxWidth / 2);
              final effectiveWidth = math.min(
                width,
                math.max(0.0, bounds.maxWidth - 2 * edge),
              );
              final x = (current.center.dx - effectiveWidth / 2).clamp(
                edge,
                bounds.maxWidth - edge - effectiveWidth,
              );
              final y = below ? current.bottom + gap : current.top;
              return Stack(
                children: [
                  Positioned(
                    left: x,
                    top: y,
                    width: effectiveWidth,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: (bounds.maxHeight - y - inset).clamp(
                          0.0,
                          bounds.maxHeight,
                        ),
                      ),
                      child: SingleChildScrollView(child: content),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
