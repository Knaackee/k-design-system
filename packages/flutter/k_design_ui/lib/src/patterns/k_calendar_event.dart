import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'k_calendar.dart';
import 'k_calendar_types.dart';
import 'k_calendar_model.dart';

class KCalendarEvent<T extends Object> extends StatefulWidget {
  const KCalendarEvent({
    required this.calendar,
    required this.event,
    required this.compact,
    required this.start,
    required this.end,
    required this.zone,
    required this.dayWidth,
    required this.scrollAt,
    required this.startMove,
    required this.cancelMove,
    super.key,
  });
  final KCalendar<T> calendar;
  final T event;
  final bool compact;
  final DateTime? start, end;
  final String zone;
  final double dayWidth;
  final ValueChanged<Offset?> scrollAt;
  final VoidCallback startMove, cancelMove;
  @override
  State<KCalendarEvent<T>> createState() => _KCalendarEventState<T>();
}

class _KCalendarEventState<T extends Object> extends State<KCalendarEvent<T>> {
  double _delta = 0;
  KCalendarResizeEdge? _edge;
  bool _cancelled = false;
  bool _moving = false;
  final _focus = FocusNode();
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KCalendar<T> get c => widget.calendar;
  bool get allDay => c.eventAllDay?.call(widget.event) == true;
  int get units => allDay
      ? (_delta / widget.dayWidth).round() * 1440
      : (_delta / (c.hourHeight * c.stepMinutes / 60)).round() * c.stepMinutes;
  KCalendarResize<T>? get change {
    final start = widget.start, end = widget.end, edge = _edge;
    if (start == null || end == null || edge == null) return null;
    final a = edge == KCalendarResizeEdge.start
        ? start.add(Duration(minutes: units))
        : start;
    final b = edge == KCalendarResizeEdge.end
        ? end.add(Duration(minutes: units))
        : end;
    if (!b.isAfter(a)) return null;
    final result = KCalendarResize<T>(
      event: widget.event,
      eventId: c.eventId(widget.event),
      start: calendarSlot(a, a.hour * 60 + a.minute, allDay, widget.zone),
      end: calendarSlot(b, b.hour * 60 + b.minute, allDay, widget.zone),
      edge: edge,
    );
    return c.canResize?.call(result) == false ? null : result;
  }

  void notify(KCalendarInteractionPhase phase, {KCalendarResize<T>? resize}) =>
      c.onInteraction?.call(
        KCalendarInteraction(
          kind: KCalendarInteractionKind.resize,
          phase: phase,
          event: widget.event,
          resize: resize,
        ),
      );
  void begin(KCalendarResizeEdge edge) {
    _focus.requestFocus();
    setState(() {
      _edge = edge;
      _delta = 0;
      _cancelled = false;
    });
    notify(KCalendarInteractionPhase.start, resize: change);
  }

  void update(double delta, Offset global) {
    setState(() => _delta += delta);
    widget.scrollAt(global);
    notify(KCalendarInteractionPhase.preview, resize: change);
  }

  void finish() {
    final value = change;
    widget.scrollAt(null);
    if (!_cancelled && value != null) {
      c.onEventResize?.call(value);
      notify(KCalendarInteractionPhase.commit, resize: value);
    } else {
      notify(KCalendarInteractionPhase.cancel);
    }
    setState(() {
      _edge = null;
      _delta = 0;
    });
  }

  void cancel() {
    _cancelled = true;
    if (_moving) {
      widget.cancelMove();
      c.onInteraction?.call(
        KCalendarInteraction(
          kind: KCalendarInteractionKind.move,
          phase: KCalendarInteractionPhase.cancel,
          event: widget.event,
        ),
      );
    }
    widget.scrollAt(null);
    if (_edge != null) {
      notify(KCalendarInteractionPhase.cancel);
      setState(() {
        _edge = null;
        _delta = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final base = Material(
      color: t.colorSurfaceSubtle,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: t.colorBorderFocus),
        borderRadius: BorderRadius.circular(t.radiusSmall),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => c.onEventOpen?.call(widget.event),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: c.eventBuilder(
            context,
            KCalendarEventContext(
              event: widget.event,
              eventId: c.eventId(widget.event),
              compact: widget.compact,
              start: widget.start,
              end: widget.end,
              allDay: allDay,
            ),
          ),
        ),
      ),
    );
    Widget content = base;
    if (c.onEventResize != null &&
        widget.start != null &&
        widget.end != null &&
        (!allDay || c.view != KCalendarView.day) &&
        (!widget.compact || allDay)) {
      content = LayoutBuilder(
        builder: (context, size) {
          final preview = change != null
              ? units * (allDay ? widget.dayWidth / 1440 : c.hourHeight / 60)
              : 0.0;
          final leading = _edge == KCalendarResizeEdge.start ? preview : 0.0;
          final trailing = _edge == KCalendarResizeEdge.end ? preview : 0.0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: allDay ? leading : 0,
                right: allDay ? -trailing : 0,
                top: allDay ? 0 : leading,
                bottom: allDay ? 0 : -trailing,
                child: base,
              ),
              for (final edge in KCalendarResizeEdge.values)
                Positioned(
                  left: allDay
                      ? (edge == KCalendarResizeEdge.start ? leading - 5 : null)
                      : 24,
                  right: allDay
                      ? (edge == KCalendarResizeEdge.end ? -trailing - 1 : null)
                      : 24,
                  top: allDay
                      ? 0
                      : edge == KCalendarResizeEdge.start
                      ? leading
                      : null,
                  bottom: allDay
                      ? 0
                      : edge == KCalendarResizeEdge.end
                      ? -trailing
                      : null,
                  width: allDay ? 12 : null,
                  height: allDay ? null : 12,
                  child: Semantics(
                    label: edge == KCalendarResizeEdge.start
                        ? c.labels.resizeStart
                        : c.labels.resizeEnd,
                    child: MouseRegion(
                      cursor: allDay
                          ? SystemMouseCursors.resizeLeftRight
                          : SystemMouseCursors.resizeUpDown,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragStart: allDay
                            ? (_) => begin(edge)
                            : null,
                        onHorizontalDragUpdate: allDay
                            ? (d) => update(d.delta.dx, d.globalPosition)
                            : null,
                        onHorizontalDragEnd: allDay ? (_) => finish() : null,
                        onVerticalDragStart: allDay ? null : (_) => begin(edge),
                        onVerticalDragUpdate: allDay
                            ? null
                            : (d) => update(d.delta.dy, d.globalPosition),
                        onVerticalDragEnd: allDay ? null : (_) => finish(),
                        onHorizontalDragCancel: allDay ? cancel : null,
                        onVerticalDragCancel: allDay ? null : cancel,
                        child: Align(
                          alignment: allDay
                              ? Alignment.center
                              : edge == KCalendarResizeEdge.start
                              ? Alignment.topCenter
                              : Alignment.bottomCenter,
                          child: Container(
                            width: allDay ? 3 : 24,
                            height: allDay ? 16 : 3,
                            color: t.colorBorderFocus,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }
    if (c.onEventMove != null) {
      final child = content;
      void start() {
        _cancelled = false;
        _moving = true;
        _focus.requestFocus();
        widget.startMove();
        c.onInteraction?.call(
          KCalendarInteraction(
            kind: KCalendarInteractionKind.move,
            phase: KCalendarInteractionPhase.start,
            event: widget.event,
          ),
        );
      }

      void end(DraggableDetails details) {
        _moving = false;
        widget.scrollAt(null);
        if (!details.wasAccepted && !_cancelled) {
          c.onInteraction?.call(
            KCalendarInteraction(
              kind: KCalendarInteractionKind.move,
              phase: KCalendarInteractionPhase.cancel,
              event: widget.event,
            ),
          );
        }
      }

      content = Listener(
        onPointerDown: (d) {},
        child: LayoutBuilder(
          builder: (context, _) => _PointerDrag<T>(
            data: widget.event,
            // The calendar owns the snapped, full-width preview. Keeping the
            // platform drag feedback empty avoids a second free-floating card.
            onStart: start,
            onUpdate: (d) => widget.scrollAt(d.globalPosition),
            onEnd: end,
            child: child,
          ),
        ),
      );
    }
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          cancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: content,
    );
  }
}

class _PointerDrag<T extends Object> extends StatefulWidget {
  const _PointerDrag({
    required this.data,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.child,
  });
  final T data;
  final Widget child;
  final VoidCallback onStart;
  final ValueChanged<DragUpdateDetails> onUpdate;
  final ValueChanged<DraggableDetails> onEnd;
  @override
  State<_PointerDrag<T>> createState() => _PointerDragState<T>();
}

class _PointerDragState<T extends Object> extends State<_PointerDrag<T>> {
  bool _mouse = false;

  void startDrag() {
    widget.onStart();
  }

  void endDrag(DraggableDetails details) {
    widget.onEnd(details);
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) {
      if (!_mouse) setState(() => _mouse = true);
    },
    onExit: (_) {
      if (_mouse) setState(() => _mouse = false);
    },
    child: _mouse
        ? Draggable<T>(
            data: widget.data,
            feedback: const SizedBox.shrink(),
            dragAnchorStrategy: childDragAnchorStrategy,
            onDragStarted: startDrag,
            onDragUpdate: widget.onUpdate,
            onDragEnd: endDrag,
            // The calendar relays out the active event into its preview lane;
            // keep that layout slot but let the visible feedback follow the
            // pointer. The stable event key prevents the drag state from
            // restarting when lanes are recalculated.
            childWhenDragging: Opacity(opacity: 0, child: widget.child),
            child: widget.child,
          )
        : LongPressDraggable<T>(
            data: widget.data,
            feedback: const SizedBox.shrink(),
            dragAnchorStrategy: childDragAnchorStrategy,
            onDragStarted: startDrag,
            onDragUpdate: widget.onUpdate,
            onDragEnd: endDrag,
            childWhenDragging: Opacity(opacity: 0, child: widget.child),
            child: widget.child,
          ),
  );
}
