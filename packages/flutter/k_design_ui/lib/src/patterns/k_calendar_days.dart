import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'k_calendar.dart';
import 'k_calendar_types.dart';
import 'k_calendar_model.dart';

/// Shared spanning lane used above timed days and within each month week.
class KCalendarDays<T extends Object> extends StatefulWidget {
  const KCalendarDays({
    required this.calendar,
    required this.days,
    required this.month,
    required this.zone,
    required this.events,
    required this.start,
    required this.end,
    required this.eventWidget,
    required this.move,
    required this.scrollAt,
    required this.scrollBy,
    required this.pendingSelection,
    required this.requestCreate,
    required this.previewMove,
    required this.previewMoveId,
    this.previewEvent,
    super.key,
  });
  final KCalendar<T> calendar;
  final List<DateTime> days;
  final bool month;
  final String zone;
  final List<T> events;
  final DateTime? Function(T) start, end;
  final Widget Function(T) eventWidget;
  final bool Function(T, KCalendarSlot, {bool preview}) move;
  final ValueChanged<Offset?> scrollAt;
  final ValueChanged<Offset> scrollBy;
  final KCalendarSelection? pendingSelection;
  final ValueChanged<KCalendarSelection> requestCreate;
  final KCalendarSelection? previewMove;
  final String? previewMoveId;
  final T? previewEvent;
  @override
  State<KCalendarDays<T>> createState() => _KCalendarDaysState<T>();
}

class _KCalendarDaysState<T extends Object> extends State<KCalendarDays<T>> {
  int? _anchor, _last, _hover;
  bool _mouse = false;
  bool _allowLongPress = true;
  Offset? _tapPosition;
  Offset? _touchOrigin;
  bool _touchCancelled = false;
  final _focus = FocusNode();
  KCalendar<T> get c => widget.calendar;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KCalendarSlot slot(int index) => calendarSlot(
    widget.days.first.add(Duration(days: index)),
    0,
    true,
    widget.zone,
  );
  KCalendarSelection? get selection => _anchor == null
      ? null
      : KCalendarSelection(
          start: slot(math.min(_anchor!, _last ?? _anchor!)),
          end: slot(math.max(_anchor!, _last ?? _anchor!) + 1),
        );
  void emit(KCalendarInteractionPhase phase) => c.onInteraction?.call(
    KCalendarInteraction(
      kind: KCalendarInteractionKind.create,
      phase: phase,
      selection: selection,
    ),
  );
  void begin(int index, {bool tap = false}) {
    if (c.requireLongPress && !tap) return;
    if (c.onCreate == null) return;
    _focus.requestFocus();
    setState(() {
      _anchor = index;
      _last = index;
    });
    emit(KCalendarInteractionPhase.start);
  }

  void update(int index, Offset global) {
    if (_anchor == null) return;
    setState(() => _last = index);
    widget.scrollAt(global);
    emit(KCalendarInteractionPhase.preview);
  }

  void finish() {
    final value = selection;
    widget.scrollAt(null);
    if (value != null) {
      setState(() {
        _anchor = null;
      });
    }
    if (value != null) {
      if (c.canCreate?.call(value) != false) {
        emit(KCalendarInteractionPhase.commit);
        widget.requestCreate(value);
      } else {
        emit(KCalendarInteractionPhase.cancel);
      }
    }
  }

  void cancel() {
    if (_anchor != null) emit(KCalendarInteractionPhase.cancel);
    widget.scrollAt(null);
    setState(() => _anchor = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final segments = <({T event, int first, int last, int lane})>[];
    final occupied = <int>[];
    for (final event in widget.events) {
      final start = widget.start(event);
      if (start == null) continue;
      final end = widget.end(event) ?? start.add(const Duration(days: 1));
      final first = calendarDay(start).difference(widget.days.first).inDays;
      final endDay =
          calendarDay(end).difference(widget.days.first).inDays +
          ((c.eventAllDay?.call(event) == true ||
                  end.hour == 0 && end.minute == 0)
              ? 0
              : 1);
      final a = first.clamp(0, widget.days.length),
          b = endDay.clamp(0, widget.days.length);
      if (a >= b) continue;
      var lane = occupied.indexWhere((last) => last <= a);
      if (lane < 0) {
        lane = occupied.length;
        occupied.add(b);
      } else {
        occupied[lane] = b;
      }
      segments.add((event: event, first: a, last: b, lane: lane));
    }
    final preview = widget.previewMove;
    final active = widget.previewEvent;
    final previewFirst = preview == null
        ? 0
        : DateTime.parse(
            preview.start.date,
          ).difference(widget.days.first).inDays.clamp(0, widget.days.length);
    final previewLast = preview == null
        ? 0
        : (DateTime.parse(
                    preview.end.date,
                  ).difference(widget.days.first).inDays +
                  (preview.end.minutes > 0 ? 1 : 0))
              .clamp(0, widget.days.length);
    final visiblePreviewFirst = previewFirst.clamp(0, widget.days.length);
    final visiblePreviewLast = previewLast.clamp(0, widget.days.length);
    final top = widget.month ? 28.0 : 4.0;
    final height = math.max(
      widget.month ? 112.0 : 40.0,
      top + occupied.length * 32 + 8,
    );
    final pendingStart = widget.pendingSelection == null
        ? 0
        : calendarDay(DateTime.parse(widget.pendingSelection!.start.date))
              .difference(calendarDay(widget.days.first))
              .inDays
              .clamp(0, widget.days.length - 1);
    final pendingDays = widget.pendingSelection == null
        ? 1
        : (DateTime.parse(widget.pendingSelection!.end.date)
                  .difference(
                    DateTime.parse(widget.pendingSelection!.start.date),
                  )
                  .inDays)
              .clamp(1, widget.days.length - pendingStart);
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          cancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, size) {
          final width = size.maxWidth / widget.days.length;
          int at(double x) =>
              (x / width).floor().clamp(0, widget.days.length - 1);
          return SizedBox(
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Row(
                      children: [
                        for (var i = 0; i < widget.days.length; i++)
                          Expanded(
                            child: DragTarget<T>(
                              onWillAcceptWithDetails: (_) =>
                                  c.onEventMove != null,
                              onMove: (d) {
                                widget.move(d.data, slot(i), preview: true);
                                widget.scrollAt(d.offset);
                              },
                              onAcceptWithDetails: (d) =>
                                  widget.move(d.data, slot(i)),
                              builder: (context, candidates, rejected) =>
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: candidates.isEmpty
                                          ? null
                                          : t.colorBorderFocus.withValues(
                                              alpha: .1,
                                            ),
                                      border: Border(
                                        left: BorderSide(
                                          color: t.colorBorderDefault,
                                        ),
                                        bottom: BorderSide(
                                          color: t.colorBorderDefault,
                                        ),
                                      ),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: widget.month
                                          ? Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Text(
                                                '${widget.days[i].day}',
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (d) {
                        _mouse =
                            d.kind == PointerDeviceKind.mouse &&
                            !c.requireLongPress;
                        _allowLongPress =
                            d.kind != PointerDeviceKind.mouse &&
                            !c.requireLongPress;
                        if (_mouse) {
                          begin(at(d.localPosition.dx));
                        } else {
                          _touchOrigin = d.position;
                          _touchCancelled = false;
                        }
                      },
                      onPointerMove: (d) {
                        if (_mouse) {
                          update(at(d.localPosition.dx), d.position);
                        } else if (_anchor == null) {
                          final origin = _touchOrigin;
                          if (origin != null &&
                              (_touchCancelled ||
                                  (d.position - origin).distance > 8)) {
                            _touchCancelled = true;
                            if (c.requireLongPress) {
                              widget.scrollBy(origin - d.position);
                            }
                            _touchOrigin = d.position;
                          }
                        }
                      },
                      onPointerUp: (_) {
                        if (_mouse) {
                          finish();
                        } else {
                          _touchOrigin = null;
                        }
                      },
                      onPointerCancel: (_) {
                        _touchOrigin = null;
                        _touchCancelled = true;
                        cancel();
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (d) {
                          if (c.requireLongPress) {
                            _tapPosition = d.localPosition;
                          }
                        },
                        onTap: () {
                          final position = _tapPosition;
                          _tapPosition = null;
                          if (c.requireLongPress && position != null) {
                            begin(at(position.dx), tap: true);
                            finish();
                          }
                        },
                        onLongPressStart: (d) {
                          if (_allowLongPress && !_touchCancelled) {
                            begin(at(d.localPosition.dx));
                          }
                        },
                        onLongPressMoveUpdate: (d) =>
                            update(at(d.localPosition.dx), d.globalPosition),
                        onLongPressEnd: (_) {
                          if (_allowLongPress && !_touchCancelled) finish();
                          _touchOrigin = null;
                        },
                        onLongPressCancel: () {
                          _touchOrigin = null;
                          cancel();
                        },
                      ),
                    ),
                  ),
                  if (_hover != null && widget.previewMove == null)
                    Positioned(
                      left: _hover! * width,
                      width: width,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          color: t.colorBorderFocus.withValues(alpha: .12),
                        ),
                      ),
                    ),
                  if (_anchor != null || widget.pendingSelection != null)
                    Positioned(
                      left:
                          (widget.pendingSelection == null
                              ? math.min(_anchor!, _last ?? _anchor!)
                              : pendingStart) *
                          width,
                      width:
                          (widget.pendingSelection == null
                              ? ((_last ?? _anchor!) - _anchor!).abs() + 1
                              : pendingDays) *
                          width,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: t.colorBorderFocus.withValues(alpha: .28),
                            border: Border.all(color: t.colorBorderFocus),
                          ),
                          alignment: Alignment.topLeft,
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            c.labels.create,
                            style: TextStyle(
                              color: t.colorTextPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: t.fontCaptionSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  for (final segment in segments)
                    Positioned(
                      left: segment.first * width + 4,
                      width: (segment.last - segment.first) * width - 8,
                      top: top + segment.lane * 32,
                      height: 28,
                      child: Opacity(
                        opacity:
                            c.eventId(segment.event) == widget.previewMoveId
                            ? 0
                            : 1,
                        child: widget.eventWidget(segment.event),
                      ),
                    ),
                  if (active != null &&
                      preview != null &&
                      (widget.month || preview.start.allDay) &&
                      visiblePreviewLast > visiblePreviewFirst)
                    Positioned(
                      left: visiblePreviewFirst * width + 4,
                      width:
                          (visiblePreviewLast - visiblePreviewFirst) * width -
                              8,
                      top: top,
                      height: 26,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: .78,
                          child: widget.eventWidget(active),
                        ),
                      ),
                    ),
                ],
              ),
          );
        },
      ),
    );
  }
}
