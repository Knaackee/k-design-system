import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/patterns/k_calendar_time_day.dart';

void main() {
  test('slots preserve civil all-day dates and resolve named time zones', () {
    expect(
      kCalendarSlotToDate(
        const KCalendarSlot(
          date: '2026-09-21',
          minutes: 540,
          allDay: false,
          timeZone: 'Europe/Berlin',
        ),
      ),
      DateTime.utc(2026, 9, 21, 7),
    );
    expect(
      kCalendarSlotToDate(
        const KCalendarSlot(
          date: '2026-09-21',
          minutes: 0,
          allDay: true,
          timeZone: 'America/New_York',
        ),
      ),
      DateTime.utc(2026, 9, 21),
    );
  });

  testWidgets(
    'free-slot long press emits range; resizing emits changed start and end',
    (tester) async {
      KCalendarSelection? created;
      KCalendarResize<_Event>? resized;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(brightness: Brightness.light),
          home: Scaffold(
            body: KCalendar<_Event>(
              date: DateTime.utc(2026, 9, 21),
              view: KCalendarView.day,
              events: [
                _Event(
                  start: DateTime.utc(2026, 9, 21, 9),
                  end: DateTime.utc(2026, 9, 21, 10, 30),
                ),
              ],
              eventId: (_) => 'event',
              eventStart: (e) => e.start,
              eventEnd: (e) => e.end,
              eventBuilder: (_, _) => const Text('Editable event'),
              timeZone: 'UTC',
              startHour: 7,
              endHour: 19,
              height: 500,
              onCreate: (value) => created = value,
              onEventResize: (value) => resized = value,
            ),
          ),
        ),
      );
      final day = tester.getRect(find.byType(KCalendarTimeDay<_Event>));
      await tester.longPressAt(Offset(day.left + 20, day.top + 60));
      await tester.pump();
      expect(created?.start.minutes, 480);
      expect(created?.end.minutes, 510);
      final handle = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Change end',
      );
      await tester.drag(handle, const Offset(0, 56));
      await tester.pump();
      expect(resized?.edge, KCalendarResizeEdge.end);
      expect(resized?.start.minutes, 540);
      expect(resized?.end.minutes, 660);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'calendar renders controlled week and month views at compact width',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final view in [KCalendarView.week, KCalendarView.month]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(brightness: Brightness.dark),
            home: Scaffold(
              body: KCalendar<_Event>(
                date: DateTime(2026, 9, 21),
                view: view,
                events: [
                  _Event(
                    start: DateTime(2026, 9, 21, 9),
                    end: DateTime(2026, 9, 21, 10, 30),
                  ),
                ],
                eventId: (_) => 'event',
                eventStart: (event) => event.start,
                eventEnd: (event) => event.end,
                eventBuilder: (_, _) => const Text('Design review'),
                onEventResize: (_) {},
                startHour: 7,
                endHour: 19,
                height: 680,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Design review'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}

class _Event {
  const _Event({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}
