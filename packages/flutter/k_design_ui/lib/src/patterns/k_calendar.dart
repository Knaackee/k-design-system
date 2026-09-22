import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../localization/k_localization.dart';
import 'k_calendar_time_day.dart';
import 'k_calendar_types.dart';
import 'k_calendar_model.dart';
import 'k_calendar_event.dart';
import 'k_calendar_days.dart';

/// Controlled calendar canvas. Compose navigation, filters and unplanned items
/// outside this component. All changes are requests; events are never mutated.
class KCalendar<T extends Object> extends StatefulWidget {
  const KCalendar({
    required this.date,
    required this.view,
    required this.events,
    required this.eventId,
    required this.eventStart,
    required this.eventEnd,
    required this.eventBuilder,
    this.eventAllDay,
    this.onEventOpen,
    this.onEventMove,
    this.onEventResize,
    this.onCreate,
    this.onInteraction,
    this.canMove,
    this.canResize,
    this.canCreate,
    this.locale,
    this.timeZone,
    this.dayLabelBuilder,
    this.firstDayOfWeek = DateTime.monday,
    this.startHour = 0,
    this.endHour = 24,
    this.stepMinutes = 30,
    this.defaultDurationMinutes = 30,
    this.hourHeight = 56,
    this.height = 680,
    this.minimumDayWidth = 160,
    this.requireLongPress = false,
    this.labels = const KCalendarLabels(),
    this.semanticLabel = 'Calendar',
    super.key,
  });
  final DateTime date;
  final KCalendarView view;
  final List<T> events;
  final String Function(T) eventId;
  final DateTime? Function(T) eventStart, eventEnd;

  /// All-day values use their year/month/day fields; end dates are exclusive.
  final bool Function(T)? eventAllDay;
  final KCalendarEventBuilder<T> eventBuilder;
  final ValueChanged<T>? onEventOpen;
  final ValueChanged<KCalendarMove<T>>? onEventMove;
  final ValueChanged<KCalendarResize<T>>? onEventResize;
  final ValueChanged<KCalendarSelection>? onCreate;
  final ValueChanged<KCalendarInteraction<T>>? onInteraction;
  final bool Function(KCalendarMove<T>)? canMove;
  final bool Function(KCalendarResize<T>)? canResize;
  final bool Function(KCalendarSelection)? canCreate;
  final String? locale, timeZone;
  final String Function(DateTime)? dayLabelBuilder;
  final int firstDayOfWeek,
      startHour,
      endHour,
      stepMinutes,
      defaultDurationMinutes;
  final double hourHeight, height, minimumDayWidth;

  /// Uses tap-to-create in compact or portrait presentations, reserving
  /// pointer drags for scrolling.
  final bool requireLongPress;
  final KCalendarLabels labels;
  final String semanticLabel;
  @override
  State<KCalendar<T>> createState() => _KCalendarState<T>();
}

class _KCalendarState<T extends Object> extends State<KCalendar<T>> {
  final _horizontal = ScrollController(), _vertical = ScrollController();
  final _viewport = GlobalKey();
  Timer? _autoScroll;
  Offset? _pointer;
  bool _moveCancelled = false;
  KCalendarSelection? _pendingSelection;
  KCalendarSelection? _previewMove;
  String? _previewMoveId;
  String get zone => widget.timeZone ?? KLocalization.of(context).timeZone;
  @override
  void didUpdateWidget(covariant KCalendar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.events.length != oldWidget.events.length) {
      _pendingSelection = null;
    }
  }

  void requestCreate(KCalendarSelection selection) {
    setState(() => _pendingSelection = selection);
    widget.onCreate?.call(selection);
  }

  DateTime? localStart(T event) {
    final value = widget.eventStart(event);
    return value == null
        ? null
        : widget.eventAllDay?.call(event) == true
        ? calendarDay(value)
        : calendarLocal(value, zone);
  }

  DateTime? localEnd(T event) {
    final value = widget.eventEnd(event);
    return value == null
        ? null
        : widget.eventAllDay?.call(event) == true
        ? calendarDay(value)
        : calendarLocal(value, zone);
  }

  bool allDay(T event) => widget.eventAllDay?.call(event) == true;
  List<DateTime> get days =>
      calendarDays(widget.date, widget.view, widget.firstDayOfWeek);
  @override
  void dispose() {
    _autoScroll?.cancel();
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  void scrollAt(Offset? position) {
    _pointer = position;
    if (position == null) {
      _autoScroll?.cancel();
      _autoScroll = null;
      return;
    }
    _autoScroll ??= Timer.periodic(const Duration(milliseconds: 30), (_) {
      final box = _viewport.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || _pointer == null) return;
      final point = box.globalToLocal(_pointer!);
      void step(ScrollController controller, double at, double max) {
        if (!controller.hasClients) return;
        final delta = at < 36
            ? -12.0
            : at > max - 36
            ? 12.0
            : 0.0;
        if (delta != 0) {
          controller.jumpTo(
            (controller.offset + delta).clamp(
              0.0,
              controller.position.maxScrollExtent,
            ),
          );
        }
      }

      step(_horizontal, point.dx, box.size.width);
      step(_vertical, point.dy, box.size.height);
    });
  }

  void scrollBy(Offset delta) {
    if (_horizontal.hasClients && delta.dx != 0) {
      _horizontal.jumpTo(
        (_horizontal.offset + delta.dx).clamp(
          0.0,
          _horizontal.position.maxScrollExtent,
        ),
      );
    }
    if (_vertical.hasClients && delta.dy != 0) {
      _vertical.jumpTo(
        (_vertical.offset + delta.dy).clamp(
          0.0,
          _vertical.position.maxScrollExtent,
        ),
      );
    }
  }

  KCalendarMove<T> movement(T event, KCalendarSlot target) {
    final start = widget.eventStart(event), end = widget.eventEnd(event);
    return KCalendarMove(
      event: event,
      eventId: widget.eventId(event),
      target: target,
      durationMinutes: start != null && end != null
          ? math.max(widget.stepMinutes, end.difference(start).inMinutes)
          : widget.defaultDurationMinutes,
    );
  }

  bool move(T event, KCalendarSlot slot, {bool preview = false}) {
    final change = movement(event, slot);
    final allowed =
        !_moveCancelled &&
        widget.onEventMove != null &&
        widget.canMove?.call(change) != false;
    widget.onInteraction?.call(
      KCalendarInteraction(
        kind: KCalendarInteractionKind.move,
        phase: preview
            ? KCalendarInteractionPhase.preview
            : allowed
            ? KCalendarInteractionPhase.commit
            : KCalendarInteractionPhase.cancel,
        event: event,
        move: change,
      ),
    );
    if (preview) {
      final end = calendarSlot(
        DateTime.parse(slot.date),
        slot.minutes + change.durationMinutes,
        slot.allDay,
        slot.timeZone,
      );
      setState(() {
        _previewMoveId = change.eventId;
        _previewMove = KCalendarSelection(start: slot, end: end);
      });
    } else if (_previewMove != null) {
      setState(() {
        _previewMove = null;
        _previewMoveId = null;
      });
    }
    if (!preview) {
      scrollAt(null);
      if (allowed) widget.onEventMove?.call(change);
    }
    return allowed;
  }

  Widget event(T value, {required bool compact, double dayWidth = 160}) =>
      KCalendarEvent<T>(
        calendar: widget,
        event: value,
        compact: compact,
        dayWidth: dayWidth,
        start: localStart(value),
        end: localEnd(value),
        zone: zone,
        scrollAt: scrollAt,
        startMove: () => _moveCancelled = false,
        cancelMove: () => _moveCancelled = true,
        key: ValueKey(widget.eventId(value)),
      );
  String dayLabel(DateTime day, {bool weekdayOnly = false}) {
    if (!weekdayOnly && widget.dayLabelBuilder != null) {
      return widget.dayLabelBuilder!(day);
    }
    final pack = KLocalization.of(context).calendar(locale: widget.locale);
    final weekdays = pack['weekdays'] as List?;
    final label = weekdays == null
        ? MaterialLocalizations.of(context).narrowWeekdays[day.weekday % 7]
        : '${weekdays[day.weekday % 7]}'.characters.take(2).toString();
    return weekdayOnly ? label : '$label ${day.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.startHour < 0 ||
        widget.endHour > 24 ||
        widget.startHour >= widget.endHour ||
        widget.stepMinutes <= 0 ||
        60 % widget.stepMinutes != 0 ||
        widget.defaultDurationMinutes <= 0 ||
        widget.hourHeight <= 0 ||
        widget.minimumDayWidth <= 0 ||
        widget.height <= 0 ||
        widget.firstDayOfWeek < 1 ||
        widget.firstDayOfWeek > 7) {
      throw ArgumentError('Invalid calendar geometry');
    }
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      label: widget.semanticLabel,
      container: true,
      child: SizedBox(
        key: _viewport,
        height: widget.height,
        child: ColoredBox(
          color: t.colorSurfaceCanvas,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.stylus,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.mouse,
              },
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final month = widget.view == KCalendarView.month;
                final count = month ? 7 : days.length;
                // Widgetbook and consumers may place the calendar in a
                // horizontally scrolling or otherwise unconstrained parent.
                // Never propagate an infinite width into the scroll view:
                // use the minimum day geometry as the intrinsic canvas width
                // until a bounded viewport is available.
                final minimumWidth =
                    (month ? 0 : 56) + count * widget.minimumDayWidth;
                final availableWidth = constraints.hasBoundedWidth
                    ? constraints.maxWidth
                    : minimumWidth;
                final width = math.max(availableWidth, minimumWidth);
                final dayWidth = (width - (month ? 0 : 56)) / count;
                return SingleChildScrollView(
                  controller: _horizontal,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: Column(
                      children: [
                        SizedBox(
                          height: t.sizeHitTarget,
                          child: Row(
                            children: [
                              if (!month) const SizedBox(width: 56),
                              for (final day in days.take(count))
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      dayLabel(day, weekdayOnly: month),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (month)
                          Expanded(
                            child: ListView.builder(
                              controller: _vertical,
                              itemCount: 6,
                              itemBuilder: (context, index) => KCalendarDays<T>(
                                calendar: widget,
                                days: days.sublist(index * 7, index * 7 + 7),
                                month: true,
                                zone: zone,
                                events: widget.events
                                    .where((e) => localStart(e) != null)
                                    .toList(),
                                start: localStart,
                                end: localEnd,
                                eventWidget: (e) =>
                                    event(e, compact: true, dayWidth: dayWidth),
                                move: move,
                                scrollAt: scrollAt,
                                scrollBy: scrollBy,
                                pendingSelection: _pendingSelection,
                                requestCreate: requestCreate,
                                previewMove: _previewMove,
                                previewMoveId: _previewMoveId,
                              ),
                            ),
                          )
                        else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 56,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    widget.labels.allDay,
                                    style: TextStyle(
                                      fontSize: t.fontCaptionSize,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: KCalendarDays<T>(
                                  calendar: widget,
                                  days: days,
                                  month: false,
                                  zone: zone,
                                  events: widget.events.where(allDay).toList(),
                                  start: localStart,
                                  end: localEnd,
                                  eventWidget: (e) => event(
                                    e,
                                    compact: true,
                                    dayWidth: dayWidth,
                                  ),
                                  move: move,
                                  scrollAt: scrollAt,
                                  scrollBy: scrollBy,
                                  pendingSelection: _pendingSelection,
                                  requestCreate: requestCreate,
                                  previewMove: _previewMove,
                                  previewMoveId: _previewMoveId,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _vertical,
                              child: SizedBox(
                                height:
                                    (widget.endHour - widget.startHour) *
                                    widget.hourHeight,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 56,
                                      child: Column(
                                        children: [
                                          for (
                                            var hour = widget.startHour;
                                            hour < widget.endHour;
                                            hour++
                                          )
                                            SizedBox(
                                              height: widget.hourHeight,
                                              child: Text(
                                                '${hour.toString().padLeft(2, '0')}:00',
                                                style: TextStyle(
                                                  fontSize: t.fontCaptionSize,
                                                  color: t.colorTextMuted,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    for (final day in days)
                                      Expanded(
                                        child: KCalendarTimeDay<T>(
                                          calendar: widget,
                                          day: day,
                                          zone: zone,
                                          events: widget.events
                                              .where(
                                                (e) =>
                                                    !allDay(e) &&
                                                    localStart(e) != null,
                                              )
                                              .toList(),
                                          start: localStart,
                                          end: localEnd,
                                          eventWidget:
                                              (e, {required compact}) =>
                                                  event(e, compact: compact),
                                          move: move,
                                          scrollAt: scrollAt,
                                          scrollBy: scrollBy,
                                          pendingSelection: _pendingSelection,
                                          requestCreate: requestCreate,
                                          previewMove: _previewMove,
                                          previewMoveId: _previewMoveId,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
