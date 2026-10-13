import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/patterns/k_calendar_time_day.dart';
import 'package:k_design_ui/src/patterns/k_calendar_days.dart';

void main() {
  testWidgets('external unplanned event drops into a calendar slot', (
    tester,
  ) async {
    const event = _Event('unplanned');
    KCalendarMove<_Event>? committed;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Column(
            children: [
              const LongPressDraggable<_Event>(
                data: event,
                feedback: Material(child: Text('Dragging')),
                child: Text('Unplanned'),
              ),
              Expanded(
                child: KCalendar<_Event>(
                  date: DateTime(2026, 9, 21),
                  view: KCalendarView.day,
                  events: const [event],
                  eventId: (value) => value.id,
                  eventStart: (value) => value.start,
                  eventEnd: (value) => value.end,
                  eventBuilder: (_, value) => Text(value.event.id),
                  onEventMove: (value) => committed = value,
                  timeZone: 'UTC',
                  startHour: 7,
                  endHour: 19,
                  height: 600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final origin = tester.getCenter(find.text('Unplanned'));
    final day = tester.getRect(find.byType(KCalendarTimeDay<_Event>));
    final gesture = await tester.startGesture(
      origin,
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(Offset(day.center.dx, day.top + 90));
    await tester.pump();
    final preview = tester.widget<KCalendarTimeDay<_Event>>(
      find.byType(KCalendarTimeDay<_Event>),
    );
    expect(preview.previewEvent, same(event));
    expect(preview.previewMove?.start.minutes, 480);
    expect(find.text('unplanned'), findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(committed?.event, same(event));
    expect(committed?.target.allDay, isFalse);
    expect(committed?.target.minutes, preview.previewMove?.start.minutes);
    expect(find.text('unplanned'), findsNothing);
  });

  testWidgets('rejected external all-day drop clears its snapped preview', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const event = _Event('unplanned');
    KCalendarMove<_Event>? committed;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Column(
            children: [
              const LongPressDraggable<_Event>(
                data: event,
                feedback: Material(child: Text('Dragging')),
                child: Text('Unplanned all day'),
              ),
              Expanded(
                child: KCalendar<_Event>(
                  date: DateTime(2026, 9, 21),
                  view: KCalendarView.week,
                  events: const [event],
                  eventId: (value) => value.id,
                  eventStart: (value) => value.start,
                  eventEnd: (value) => value.end,
                  eventBuilder: (_, value) => Text(value.event.id),
                  onEventMove: (value) => committed = value,
                  canMove: (_) => false,
                  timeZone: 'UTC',
                  height: 600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final origin = tester.getCenter(find.text('Unplanned all day'));
    final lane = find.byType(KCalendarDays<_Event>);
    final laneRect = tester.getRect(lane);
    final gesture = await tester.startGesture(
      origin,
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(Offset(laneRect.center.dx, laneRect.center.dy));
    await tester.pump();
    final preview = tester.widget<KCalendarDays<_Event>>(lane);
    expect(preview.previewEvent, same(event));
    expect(preview.previewMove?.start.allDay, isTrue);
    expect(find.text('unplanned'), findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(committed, isNull);
    expect(find.text('unplanned'), findsNothing);
    expect(tester.widget<KCalendarDays<_Event>>(lane).previewMove, isNull);
  });

  testWidgets('moved event released outside reports the host drop point', (
    tester,
  ) async {
    final event = _Event(
      'planned',
      start: DateTime.utc(2026, 9, 21, 9),
      end: DateTime.utc(2026, 9, 21, 10),
    );
    KCalendarDropOutside<_Event>? outside;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KCalendar<_Event>(
            date: DateTime(2026, 9, 21),
            view: KCalendarView.day,
            events: [event],
            eventId: (value) => value.id,
            eventStart: (value) => value.start,
            eventEnd: (value) => value.end,
            eventBuilder: (_, value) => Text(value.event.id),
            onEventMove: (_) {},
            onEventDropOutside: (value) => outside = value,
            timeZone: 'UTC',
            startHour: 7,
            endHour: 19,
            height: 500,
          ),
        ),
      ),
    );
    final origin = tester.getCenter(find.text('planned'));
    final gesture = await tester.startGesture(
      origin,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveTo(const Offset(5, 790));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(outside?.event, same(event));
    expect(outside?.globalPosition, const Offset(5, 790));
  });
}

class _Event {
  const _Event(this.id, {this.start, this.end});
  final String id;
  final DateTime? start;
  final DateTime? end;
}
