import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'k_calendar.dart';
import 'k_calendar_types.dart';
import 'k_calendar_model.dart';

class KCalendarTimeDay<T extends Object> extends StatefulWidget {
  const KCalendarTimeDay({
    required this.calendar,
    required this.day,
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
  final DateTime day;
  final String zone;
  final List<T> events;
  final DateTime? Function(T) start, end;
  final Widget Function(T, {required bool compact}) eventWidget;
  final bool Function(T, KCalendarSlot, {bool preview}) move;
  final ValueChanged<Offset?> scrollAt;
  final ValueChanged<Offset> scrollBy;
  final KCalendarSelection? pendingSelection;
  final ValueChanged<KCalendarSelection> requestCreate;
  final KCalendarSelection? previewMove;
  final String? previewMoveId;
  final T? previewEvent;
  @override
  State<KCalendarTimeDay<T>> createState() => _KCalendarTimeDayState<T>();
}

class _KCalendarTimeDayState<T extends Object>
    extends State<KCalendarTimeDay<T>> {
  final _key = GlobalKey();
  final _focus = FocusNode();
  int? _anchor, _last, _hover;
  bool _mouse = false;
  bool _allowLongPress = true;
  Offset? _tapPosition;
  Offset? _touchOrigin;
  bool _touchCancelled = false;
  KCalendar<T> get c => widget.calendar;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  int minutesAt(double y) =>
      (((c.startHour * 60 + y / c.hourHeight * 60) / c.stepMinutes).floor() *
              c.stepMinutes)
          .clamp(c.startHour * 60, c.endHour * 60 - c.stepMinutes);
  KCalendarSlot slot(int minutes) =>
      calendarSlot(widget.day, minutes, false, widget.zone);
  KCalendarSelection? get selection => _anchor == null
      ? null
      : KCalendarSelection(
          start: slot(math.min(_anchor!, _last ?? _anchor!)),
          end: slot(
            math.min(
              c.endHour * 60,
              math.max(_anchor!, _last ?? _anchor!) +
                  ((_last == null || _last == _anchor)
                      ? c.defaultDurationMinutes
                      : c.stepMinutes),
            ),
          ),
        );
  void emit(KCalendarInteractionPhase phase) => c.onInteraction?.call(
    KCalendarInteraction(
      kind: KCalendarInteractionKind.create,
      phase: phase,
      selection: selection,
    ),
  );
  void begin(double y, {bool tap = false}) {
    if (c.requireLongPress && !tap) return;
    if (c.onCreate == null) return;
    _focus.requestFocus();
    setState(() {
      _anchor = minutesAt(y);
      _last = _anchor;
    });
    emit(KCalendarInteractionPhase.start);
  }

  void update(double y, Offset global) {
    if (_anchor == null) return;
    setState(() => _last = minutesAt(y));
    widget.scrollAt(global);
    emit(KCalendarInteractionPhase.preview);
  }

  void finish() {
    final value = selection;
    widget.scrollAt(null);
    if (value != null) {
      setState(() {
        _anchor = null;
        _last = null;
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
    setState(() {
      _anchor = null;
      _last = null;
      _hover = null;
    });
  }

  double localY(Offset global) =>
      (_key.currentContext!.findRenderObject() as RenderBox)
          .globalToLocal(global)
          .dy;
  int dayMinutes(DateTime value) =>
      calendarDay(value).difference(calendarDay(widget.day)).inDays * 1440 +
      value.hour * 60 +
      value.minute;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final visible = widget.events.where((e) {
      final a = widget.start(e);
      final b = widget.end(e);
      return a != null &&
          dayMinutes(a) < c.endHour * 60 &&
          (b == null
                  ? dayMinutes(a) + c.defaultDurationMinutes
                  : dayMinutes(b)) >
              c.startHour * 60;
    }).toList();
    visible.sort((a, b) => widget.start(a)!.compareTo(widget.start(b)!));
    final rects = <({T event, int start, int end, int lane, int lanes})>[];
    final ends = <int>[];
    for (final e in visible) {
      final a = dayMinutes(widget.start(e)!);
      final end = widget.end(e);
      final b = end == null ? a + c.defaultDurationMinutes : dayMinutes(end);
      var lane = ends.indexWhere((end) => end <= a);
      if (lane < 0) {
        lane = ends.length;
        ends.add(b);
      } else {
        ends[lane] = b;
      }
      rects.add((event: e, start: a, end: b, lane: lane, lanes: 1));
    }
    // Width is shared only by one connected overlap cluster. A later event
    // must return to the full column width once the previous cluster ends.
    final laidOut = rects.map((rect) {
      var clusterStart = rect.start;
      var clusterEnd = rect.end;
      var changed = true;
      while (changed) {
        changed = false;
        for (final other in rects) {
          if (other.start < clusterEnd && other.end > clusterStart) {
            if (other.start < clusterStart) {
              clusterStart = other.start;
              changed = true;
            }
            if (other.end > clusterEnd) {
              clusterEnd = other.end;
              changed = true;
            }
          }
        }
      }
      final lanes = rects
          .where(
            (other) => other.start < clusterEnd && other.end > clusterStart,
          )
          .map((other) => other.lane)
          .fold(0, (max, lane) => math.max(max, lane + 1));
      return (
        event: rect.event,
        start: rect.start,
        end: rect.end,
        lane: rect.lane,
        lanes: math.max(1, lanes),
      );
    }).toList();
    final shownSelection = selection ?? widget.pendingSelection;
    final preview = widget.previewMove;
    final active = widget.previewEvent;
    int previewMinutes(KCalendarSlot value) =>
        DateTime.parse(value.date).difference(calendarDay(widget.day)).inDays *
            1440 +
        value.minutes;
    final rawPreviewStart = preview == null ? 0 : previewMinutes(preview.start);
    final rawPreviewEnd = preview == null ? 0 : previewMinutes(preview.end);
    final previewSpansDays = rawPreviewEnd - rawPreviewStart >= 1440;
    final previewStartsOnThisDay =
        preview != null && preview.start.date == calendarDateKey(widget.day);
    final previewIntersects =
        preview != null &&
        rawPreviewStart < c.endHour * 60 &&
        rawPreviewEnd > c.startHour * 60 &&
        (previewSpansDays || previewStartsOnThisDay);
    final previewStart = previewIntersects
        ? math.max(c.startHour * 60, rawPreviewStart)
        : 0;
    final previewEnd = previewIntersects
        ? math.min(c.endHour * 60, rawPreviewEnd)
        : 0;
    // The move overlay never participates in the committed event layout.
    final shownHover = widget.previewMove == null ? _hover : null;
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
          cancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: DragTarget<T>(
        onWillAcceptWithDetails: (d) => c.onEventMove != null,
        onMove: (d) {
          final minute = minutesAt(localY(d.offset));
          final allowed = widget.move(d.data, slot(minute), preview: true);
          setState(() => _hover = allowed ? minute : null);
          widget.scrollAt(d.offset);
        },
        onLeave: (_) {
          setState(() => _hover = null);
        },
        onAcceptWithDetails: (d) {
          widget.move(d.data, slot(minutesAt(localY(d.offset))));
          setState(() => _hover = null);
        },
        builder: (context, candidates, rejected) => LayoutBuilder(
        builder: (context, size) => SizedBox(
            key: _key,
            height: (c.endHour - c.startHour) * c.hourHeight,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: Listener(
                    onPointerDown: (d) {
                      _mouse =
                          d.kind == PointerDeviceKind.mouse &&
                          !c.requireLongPress;
                      _allowLongPress =
                          d.kind != PointerDeviceKind.mouse &&
                          !c.requireLongPress;
                      if (_mouse) {
                        begin(d.localPosition.dy);
                      } else {
                        _touchOrigin = d.position;
                        _touchCancelled = false;
                      }
                    },
                    onPointerMove: (d) {
                      if (_mouse) {
                        update(d.localPosition.dy, d.position);
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
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) {
                        if (c.requireLongPress) _tapPosition = d.localPosition;
                      },
                      onTap: () {
                        final position = _tapPosition;
                        _tapPosition = null;
                        if (c.requireLongPress && position != null) {
                          begin(position.dy, tap: true);
                          finish();
                        }
                      },
                      onLongPressStart: (d) {
                        if (_allowLongPress && !_touchCancelled) {
                          begin(d.localPosition.dy);
                        }
                      },
                      onLongPressMoveUpdate: (d) =>
                          update(d.localPosition.dy, d.globalPosition),
                      onLongPressEnd: (_) {
                        if (_allowLongPress && !_touchCancelled) finish();
                        _touchOrigin = null;
                      },
                      onLongPressCancel: () {
                        _touchOrigin = null;
                        cancel();
                      },
                      child: CustomPaint(
                        painter: _HourGridPainter(
                          color: t.colorBorderDefault,
                          hourHeight: c.hourHeight,
                        ),
                      ),
                    ),
                  ),
                ),
                for (final rect in laidOut)
                  Positioned(
                    top:
                        (math.max(c.startHour * 60, rect.start) -
                            c.startHour * 60) /
                        60 *
                        c.hourHeight,
                    left: rect.lane / rect.lanes * size.maxWidth + 4,
                    width: size.maxWidth / rect.lanes - 8,
                    height: math.max(
                      24,
                      (math.min(c.endHour * 60, rect.end) -
                              math.max(c.startHour * 60, rect.start)) /
                          60 *
                          c.hourHeight,
                    ),
                    child: Opacity(
                      // Preserve the active event's layout slot while its
                      // floating feedback follows the pointer.
                      opacity:
                          widget.previewMoveId != null &&
                              c.eventId(rect.event) == widget.previewMoveId
                          ? 0
                          : 1,
                      child: widget.eventWidget(rect.event, compact: false),
                    ),
                  ),
                if (active != null &&
                    previewIntersects &&
                    !preview.start.allDay &&
                    previewEnd > previewStart)
                  Positioned(
                    left: 4,
                    right: 4,
                    top: (previewStart - c.startHour * 60) / 60 * c.hourHeight,
                    height: math.max(
                      24,
                      (previewEnd - previewStart) / 60 * c.hourHeight,
                    ),
                    child: IgnorePointer(
                      child: SizedBox.expand(
                        child: Opacity(
                          opacity: .78,
                          child: widget.eventWidget(active, compact: false),
                        ),
                      ),
                    ),
                  ),
                if (shownSelection != null || shownHover != null)
                  Positioned(
                    left: 3,
                    right: 3,
                    top:
                        ((shownSelection?.start.minutes ?? shownHover!) -
                            c.startHour * 60) /
                        60 *
                        c.hourHeight,
                    height:
                        ((shownSelection == null
                                    ? c.defaultDurationMinutes
                                    : DateTime.parse(shownSelection.end.date)
                                              .difference(
                                                DateTime.parse(
                                                  shownSelection.start.date,
                                                ),
                                              )
                                              .inMinutes +
                                          shownSelection.end.minutes -
                                          shownSelection.start.minutes) /
                                60 *
                                c.hourHeight)
                            .clamp(12, double.infinity),
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          color: t.colorBorderFocus.withValues(alpha: .28),
                          border: Border.all(color: t.colorBorderFocus),
                        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HourGridPainter extends CustomPainter {
  const _HourGridPainter({required this.color, required this.hourHeight});
  final Color color;
  final double hourHeight;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double y = 0; y <= size.height; y += hourHeight) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, 1, size.height), paint);
  }

  @override
  bool shouldRepaint(_HourGridPainter old) =>
      color != old.color || hourHeight != old.hourHeight;
}
