import 'package:flutter/widgets.dart';

enum KCalendarView { day, threeDay, week, month }

enum KCalendarMonthEventDisplay { auto, appointments, indicators }

enum KCalendarResizeEdge { start, end }

enum KCalendarInteractionPhase { start, preview, commit, cancel }

enum KCalendarInteractionKind { create, move, resize }

@immutable
class KCalendarSlot {
  const KCalendarSlot({
    required this.date,
    required this.minutes,
    required this.allDay,
    required this.timeZone,
  });
  final String date;
  final int minutes;
  final bool allDay;
  final String timeZone;
}

@immutable
class KCalendarSelection {
  const KCalendarSelection({required this.start, required this.end});
  final KCalendarSlot start;

  /// Exclusive end of the selection, including for all-day dates.
  final KCalendarSlot end;
}

@immutable
class KCalendarMove<T> {
  const KCalendarMove({
    required this.event,
    required this.eventId,
    required this.target,
    required this.durationMinutes,
  });
  final T event;
  final String eventId;
  final KCalendarSlot target;
  final int durationMinutes;
}

@immutable
class KCalendarDropOutside<T> {
  const KCalendarDropOutside({
    required this.event,
    required this.eventId,
    required this.globalPosition,
  });
  final T event;
  final String eventId;
  final Offset globalPosition;
}

@immutable
class KCalendarResize<T> {
  const KCalendarResize({
    required this.event,
    required this.eventId,
    required this.start,
    required this.end,
    required this.edge,
  });
  final T event;
  final String eventId;
  final KCalendarSlot start;
  final KCalendarSlot end;
  final KCalendarResizeEdge edge;
}

@immutable
class KCalendarInteraction<T> {
  const KCalendarInteraction({
    required this.kind,
    required this.phase,
    this.event,
    this.selection,
    this.move,
    this.resize,
  });
  final KCalendarInteractionKind kind;
  final KCalendarInteractionPhase phase;
  final T? event;
  final KCalendarSelection? selection;
  final KCalendarMove<T>? move;
  final KCalendarResize<T>? resize;
}

@immutable
class KCalendarLabels {
  const KCalendarLabels({
    this.allDay = 'All day',
    this.resizeStart = 'Change start',
    this.resizeEnd = 'Change end',
    this.create = 'Create event',
  });
  final String allDay, resizeStart, resizeEnd, create;
}

@immutable
class KCalendarEventContext<T> {
  const KCalendarEventContext({
    required this.event,
    required this.eventId,
    required this.compact,
    required this.start,
    required this.end,
    this.allDay = false,
  });
  final T event;
  final String eventId;
  final bool compact;
  final DateTime? start, end;
  final bool allDay;
}

typedef KCalendarEventBuilder<T> =
    Widget Function(BuildContext context, KCalendarEventContext<T> event);
