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
    this.onNavigate,
    this.monthEventDisplay = KCalendarMonthEventDisplay.auto,
    this.onMonthDayOpen,
    this.selectedMonthDay,
    this.onEventMove,
    this.onEventDropOutside,
    this.onEventResize,
    this.onCreate,
    this.pendingCreateSelection,
    this.onPendingCreateSelectionChange,
    this.onInteraction,
    this.selectedEventId,
    this.onSelectedEventChange,
    this.canMove,
    this.canDropOutside,
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

  /// Controlled event data. Values with a null start remain valid payloads for
  /// an external [LongPressDraggable<T>] but are not painted until scheduled.
  final List<T> events;
  final String Function(T) eventId;
  final DateTime? Function(T) eventStart, eventEnd;

  /// All-day values use their year/month/day fields; end dates are exclusive.
  final bool Function(T)? eventAllDay;
  final KCalendarEventBuilder<T> eventBuilder;
  final ValueChanged<T>? onEventOpen;

  /// Requests the previous (-1) or next (1) visible period after a swipe.
  final ValueChanged<int>? onNavigate;
  final KCalendarMonthEventDisplay monthEventDisplay;

  /// Opens a month day, including empty days, in either display mode.
  /// Appointment previews become non-interactive so the full day selects the agenda.
  final void Function(DateTime date, List<T> events)? onMonthDayOpen;

  /// The consumer's selected civil date in the month grid.
  final DateTime? selectedMonthDay;
  final ValueChanged<KCalendarMove<T>>? onEventMove;

  /// Receives an active event move released outside every calendar drop target.
  /// Consumers may use [KCalendarDropOutside.globalPosition] to test their own
  /// public drop surface.
  final ValueChanged<KCalendarDropOutside<T>>? onEventDropOutside;
  final ValueChanged<KCalendarResize<T>>? onEventResize;
  final ValueChanged<KCalendarSelection>? onCreate;

  /// Controlled create preview when [onPendingCreateSelectionChange] is set.
  /// Set this to null when the consumer-owned create flow is canceled.
  final KCalendarSelection? pendingCreateSelection;
  final ValueChanged<KCalendarSelection?>? onPendingCreateSelectionChange;
  final ValueChanged<KCalendarInteraction<T>>? onInteraction;

  /// With [onSelectedEventChange], controls the touch editing selection.
  final String? selectedEventId;

  /// Receives the selected event ID, or null when editing is dismissed.
  /// When omitted, the calendar manages touch selection internally.
  final ValueChanged<String?>? onSelectedEventChange;
  final bool Function(KCalendarMove<T>)? canMove;
  final bool Function(KCalendarDropOutside<T>)? canDropOutside;
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
  final _allDayLayout = GlobalKey();
  Timer? _autoScroll;
  Offset? _pointer;
  bool _moveCancelled = false;
  KCalendarSelection? _pendingSelection;
  KCalendarSelection? _previewMove;
  String? _previewMoveId;
  KCalendarSelection? _previewResize;
  String? _previewResizeId;
  String? _selectedEventId;
  String? _touchArmedId;
  int? _pagePointer;
  Offset? _pageOrigin;
  bool _pageAtStart = false, _pageAtEnd = false;
  bool _pageEditDragActive = false;
  String? get selectedEventId => widget.onSelectedEventChange != null
      ? widget.selectedEventId
      : _selectedEventId;
  KCalendarSelection? get pendingSelection =>
      widget.onPendingCreateSelectionChange != null
      ? widget.pendingCreateSelection
      : _pendingSelection;
  void setPendingSelection(KCalendarSelection? value) {
    if (widget.onPendingCreateSelectionChange != null) {
      widget.onPendingCreateSelectionChange!(value);
    } else {
      setState(() => _pendingSelection = value);
    }
  }

  void selectEvent(String? id) {
    if (selectedEventId == id) return;
    if (widget.onSelectedEventChange != null) {
      widget.onSelectedEventChange!(id);
    } else {
      setState(() => _selectedEventId = id);
    }
  }

  String get zone => widget.timeZone ?? KLocalization.of(context).timeZone;
  @override
  void didUpdateWidget(covariant KCalendar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date != oldWidget.date || widget.view != oldWidget.view) {
      _pendingSelection = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_horizontal.hasClients) _horizontal.jumpTo(0);
      });
    }
    if (widget.events.length != oldWidget.events.length) {
      _pendingSelection = null;
    }
  }

  void requestCreate(KCalendarSelection selection) {
    setPendingSelection(selection);
    widget.onCreate?.call(selection);
  }

  void pagePointerDown(PointerDownEvent event) {
    if (widget.onNavigate == null) return;
    _pageEditDragActive = false;
    final position = _horizontal.hasClients ? _horizontal.position : null;
    _pagePointer = event.pointer;
    _pageOrigin = event.position;
    _pageAtStart = position == null || position.pixels <= 1;
    _pageAtEnd =
        position == null || position.pixels >= position.maxScrollExtent - 1;
  }

  void pagePointerUp(PointerUpEvent event) {
    final origin = _pageOrigin;
    final matches = _pagePointer == event.pointer;
    final editedEvent = _pageEditDragActive;
    _pagePointer = null;
    _pageOrigin = null;
    _pageEditDragActive = false;
    if (!matches || origin == null || widget.onNavigate == null) return;
    if (editedEvent) return;
    if (_previewMoveId != null || _previewResizeId != null) return;
    final delta = event.position - origin;
    if (delta.dx.abs() < 48 || delta.dx.abs() <= delta.dy.abs() * 1.2) return;
    final direction = delta.dx < 0 ? 1 : -1;
    if ((direction == 1 && !_pageAtEnd) || (direction == -1 && !_pageAtStart)) {
      return;
    }
    widget.onNavigate!(direction);
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

  void clearMovePreview() {
    if (_previewMove == null && _previewMoveId == null) return;
    if (!mounted) return;
    setState(() {
      _previewMove = null;
      _previewMoveId = null;
    });
  }

  void beginResizePreview(String eventId) {
    if (!mounted) return;
    if (pendingSelection != null) setPendingSelection(null);
    final event = widget.events
        .where((value) => widget.eventId(value) == eventId)
        .firstOrNull;
    final selection = event == null ? null : selectionForEvent(event);
    setState(() {
      _previewMove = null;
      _previewMoveId = null;
      _previewResizeId = eventId;
      _previewResize = selection;
    });
  }

  void updateResizePreview(KCalendarResize<T> resize) {
    if (!mounted) return;
    setState(() {
      _previewResizeId = resize.eventId;
      _previewResize = KCalendarSelection(start: resize.start, end: resize.end);
    });
  }

  void clearResizePreview() {
    if (_previewResize == null && _previewResizeId == null) return;
    if (!mounted) return;
    setState(() {
      _previewResize = null;
      _previewResizeId = null;
    });
  }

  void beginMovePreview(String eventId) {
    if (!mounted) return;
    if (pendingSelection != null) setPendingSelection(null);
    final event = widget.events
        .where((value) => widget.eventId(value) == eventId)
        .firstOrNull;
    final selection = event == null ? null : selectionForEvent(event);
    setState(() {
      _previewResize = null;
      _previewResizeId = null;
      _previewMoveId = eventId;
      _previewMove = selection;
    });
  }

  KCalendarSelection? selectionForEvent(T event) {
    final start = localStart(event), end = localEnd(event);
    if (start == null || end == null) return null;
    final allDayValue = allDay(event);
    return KCalendarSelection(
      start: calendarSlot(
        start,
        allDayValue ? 0 : start.hour * 60 + start.minute,
        allDayValue,
        zone,
      ),
      end: calendarSlot(
        end,
        allDayValue ? 0 : end.hour * 60 + end.minute,
        allDayValue,
        zone,
      ),
    );
  }

  KCalendarMove<T> movement(T event, KCalendarSlot target) {
    final start = widget.eventStart(event), end = widget.eventEnd(event);
    final changingToTimed = allDay(event) && !target.allDay;
    return KCalendarMove(
      event: event,
      eventId: widget.eventId(event),
      target: target,
      durationMinutes: changingToTimed
          ? widget.defaultDurationMinutes
          : start != null && end != null
          ? math.max(widget.stepMinutes, end.difference(start).inMinutes)
          : widget.defaultDurationMinutes,
    );
  }

  bool move(T event, KCalendarSlot slot, {bool preview = false}) {
    // Holding selects an event; only actual movement starts a move request.
    if (_touchArmedId == widget.eventId(event)) return false;
    final change = movement(event, slot);
    if (preview && pendingSelection != null) setPendingSelection(null);
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
    } else if (_previewMove != null || _previewMoveId != null) {
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

  void moveAtAllDay(T event, Offset global) {
    final context = _allDayLayout.currentContext;
    if (context == null) return;
    final render = context.findRenderObject();
    if (render is! RenderBox) return;
    final local = render.globalToLocal(global);
    if (local.dy < 0 || local.dy >= render.size.height) {
      return;
    }
    final currentDays = days;
    final width = render.size.width / currentDays.length;
    final index = (local.dx / width).floor().clamp(0, currentDays.length - 1);
    move(
      event,
      calendarSlot(currentDays.first.add(Duration(days: index)), 0, true, zone),
      preview: true,
    );
  }

  int? resizeUnitsAtAllDay(T event, KCalendarResizeEdge edge, Offset global) {
    if (!allDay(event)) return null;
    final context = _allDayLayout.currentContext;
    if (context == null) return null;
    final render = context.findRenderObject();
    if (render is! RenderBox || render.size.width <= 0) return null;
    final local = render.globalToLocal(global);
    final currentDays = days;
    final width = render.size.width / currentDays.length;
    final index = (local.dx / width).floor().clamp(0, currentDays.length - 1);
    final targetDay = currentDays.first.add(Duration(days: index));
    final start = localStart(event), end = localEnd(event);
    if (start == null || end == null) return null;
    final boundary = edge == KCalendarResizeEdge.end
        ? targetDay.add(const Duration(days: 1))
        : targetDay;
    final original = edge == KCalendarResizeEdge.end ? end : start;
    return boundary.difference(original).inDays * 1440;
  }

  Widget event(T value, {required bool compact, double dayWidth = 160}) =>
      KCalendarEvent<T>(
        touchSelected: selectedEventId == widget.eventId(value),
        select: () {
          _touchArmedId = widget.eventId(value);
          clearMovePreview();
          selectEvent(widget.eventId(value));
        },
        deselect: () => selectEvent(null),
        calendar: widget,
        event: value,
        compact: compact,
        dayWidth: dayWidth,
        start: localStart(value),
        end: localEnd(value),
        zone: zone,
        scrollAt: scrollAt,
        startMove: () {
          _pageEditDragActive = true;
          _touchArmedId = null;
          // A drag that is interrupted before Flutter delivers its end event
          // must not leak its preview into the next interaction.
          beginMovePreview(widget.eventId(value));
          _moveCancelled = false;
        },
        cancelMove: () {
          _moveCancelled = true;
          clearMovePreview();
        },
        moveUpdate: (global) => moveAtAllDay(value, global),
        startResize: () {
          _pageEditDragActive = true;
          beginResizePreview(widget.eventId(value));
        },
        previewResize: updateResizePreview,
        endResize: clearResizePreview,
        resizeUnits: (edge, global) => resizeUnitsAtAllDay(value, edge, global),
        previewMoveId: _previewMoveId,
        previewResizeId: _previewResizeId,
        key: ValueKey(widget.eventId(value)),
      );

  T? get previewEvent => _previewMoveId == null
      ? null
      : widget.events
            .where((e) => widget.eventId(e) == _previewMoveId)
            .firstOrNull;

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
                final width = month
                    ? availableWidth
                    : math.max(availableWidth, minimumWidth);
                final dayWidth = (width - (month ? 0 : 56)) / count;
                final monthRowHeight = math.max(
                  1.0,
                  (widget.height - t.sizeHitTarget) / 6,
                );
                return Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: pagePointerDown,
                  onPointerUp: pagePointerUp,
                  onPointerCancel: (_) {
                    _pagePointer = null;
                    _pageOrigin = null;
                    _pageEditDragActive = false;
                  },
                  child: SingleChildScrollView(
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
                                if (!month)
                                  SizedBox(
                                    width: t.componentCalendarTimeLabelWidth,
                                  ),
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
                              child: Column(
                                children: [
                                  for (var index = 0; index < 6; index++)
                                    ClipRect(
                                      child: KCalendarDays<T>(
                                        calendar: widget,
                                        days: days.sublist(
                                          index * 7,
                                          index * 7 + 7,
                                        ),
                                        month: true,
                                        indicators:
                                            widget.monthEventDisplay ==
                                                KCalendarMonthEventDisplay
                                                    .indicators ||
                                            (widget.monthEventDisplay ==
                                                    KCalendarMonthEventDisplay
                                                        .auto &&
                                                widget.requireLongPress),
                                        fixedHeight: monthRowHeight,
                                        zone: zone,
                                        events: widget.events
                                            .where((e) => localStart(e) != null)
                                            .toList(),
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
                                        pendingSelection: pendingSelection,
                                        clearPendingSelection: () =>
                                            setPendingSelection(null),
                                        requestCreate: requestCreate,
                                        previewMove: _previewMove,
                                        previewMoveId: _previewMoveId,
                                        previewResize: _previewResize,
                                        previewResizeId: _previewResizeId,
                                        previewEvent: previewEvent,
                                      ),
                                    ),
                                ],
                              ),
                            )
                          else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: t.componentCalendarTimeLabelWidth,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      top: t.spaceControlGap,
                                    ),
                                    child: Text(
                                      widget.labels.allDay,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: t.fontCaptionSize,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: KCalendarDays<T>(
                                    key: _allDayLayout,
                                    calendar: widget,
                                    days: days,
                                    month: false,
                                    indicators: false,
                                    zone: zone,
                                    events: widget.events
                                        .where(allDay)
                                        .toList(),
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
                                    pendingSelection:
                                        pendingSelection?.start.allDay == true
                                        ? pendingSelection
                                        : null,
                                    clearPendingSelection: () =>
                                        setPendingSelection(null),
                                    requestCreate: requestCreate,
                                    previewMove: _previewMove,
                                    previewMoveId: _previewMoveId,
                                    previewResize: _previewResize,
                                    previewResizeId: _previewResizeId,
                                    previewEvent: previewEvent,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width:
                                            t.componentCalendarTimeLabelWidth,
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
                                            pendingSelection: pendingSelection,
                                            clearPendingSelection: () =>
                                                setPendingSelection(null),
                                            requestCreate: requestCreate,
                                            previewMove: _previewMove,
                                            previewMoveId: _previewMoveId,
                                            previewEvent: previewEvent,
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
