import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'k_calendar_types.dart';

/// Touch targets live in the overlay so short events and calendar clipping do
/// not truncate them. Followers stay aligned when the calendar scrolls.
class KCalendarTouchHandles extends StatefulWidget {
  const KCalendarTouchHandles({
    required this.selected,
    required this.moving,
    required this.horizontal,
    required this.startOffset,
    required this.endOffset,
    required this.startLabel,
    required this.endLabel,
    required this.onDismiss,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
    required this.child,
    super.key,
  });
  final bool selected, moving, horizontal;
  final double startOffset, endOffset;
  final String startLabel, endLabel;
  final VoidCallback onDismiss, onEnd, onCancel;
  final ValueChanged<KCalendarResizeEdge> onStart;
  final void Function(double, Offset) onUpdate;
  final Widget child;
  @override
  State<KCalendarTouchHandles> createState() => _KCalendarTouchHandlesState();
}

class _KCalendarTouchHandlesState extends State<KCalendarTouchHandles> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  final _region = Object();
  @override
  void initState() {
    super.initState();
    if (widget.selected) _portal.show();
  }

  @override
  void didUpdateWidget(covariant KCalendarTouchHandles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected == widget.selected &&
        oldWidget.moving == widget.moving) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.selected && !widget.moving) {
        _portal.show();
      } else {
        _portal.hide();
      }
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final color = Theme.of(
        context,
      ).extension<KDesignTokens>()!.colorBorderFocus;
      return TapRegion(
        groupId: _region,
        onTapOutside: widget.selected ? (_) => widget.onDismiss() : null,
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (context) => Stack(
            children: [
              for (final edge in KCalendarResizeEdge.values)
                Positioned(
                  left: 0,
                  top: 0,
                  width: 48,
                  height: 48,
                  child: CompositedTransformFollower(
                    link: _link,
                    showWhenUnlinked: false,
                    offset: widget.horizontal
                        ? Offset(
                            (edge == KCalendarResizeEdge.start
                                    ? widget.startOffset
                                    : size.maxWidth + widget.endOffset) -
                                24,
                            size.maxHeight / 2 -
                                24 +
                                (size.maxWidth < 48
                                    ? (edge == KCalendarResizeEdge.start
                                          ? -24
                                          : 24)
                                    : 0),
                          )
                        : Offset(
                            size.maxWidth / 2 -
                                24 +
                                (size.maxHeight < 48
                                    ? (edge == KCalendarResizeEdge.start
                                          ? -24
                                          : 24)
                                    : 0),
                            (edge == KCalendarResizeEdge.start
                                    ? widget.startOffset
                                    : size.maxHeight + widget.endOffset) -
                                24,
                          ),
                    child: TapRegion(
                      groupId: _region,
                      child: Semantics(
                        label: edge == KCalendarResizeEdge.start
                            ? widget.startLabel
                            : widget.endLabel,
                        child: GestureDetector(
                          key: ValueKey('calendar-touch-resize-${edge.name}'),
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (_) => widget.onStart(edge),
                          onPanUpdate: (d) => widget.onUpdate(
                            widget.horizontal ? d.delta.dx : d.delta.dy,
                            d.globalPosition,
                          ),
                          onPanEnd: (_) => widget.onEnd(),
                          onPanCancel: widget.onCancel,
                          child: Center(
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 2,
                                ),
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
          child: CompositedTransformTarget(link: _link, child: widget.child),
        ),
      );
    },
  );
}
