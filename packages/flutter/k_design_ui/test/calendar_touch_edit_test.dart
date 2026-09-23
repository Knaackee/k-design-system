import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/patterns/k_calendar_touch_handles.dart';

void main() {
  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    for (final allDay in [true, false]) {
      testWidgets('touch selection and resize, allDay=$allDay, kind=$kind', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(700, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final moves = <KCalendarMove<String>>[];
        final resizes = <KCalendarResize<String>>[];
        var opens = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Scaffold(
              body: KCalendar<String>(
                date: DateTime.utc(2026, 9, 21),
                view: KCalendarView.week,
                events: const ['Touch event'],
                eventId: (e) => e,
                eventStart: (_) => DateTime.utc(2026, 9, 21, allDay ? 0 : 9),
                eventEnd: (_) => allDay
                    ? DateTime.utc(2026, 9, 22)
                    : DateTime.utc(2026, 9, 21, 9, 30),
                eventAllDay: (_) => allDay,
                eventBuilder: (_, e) => Text(e.event),
                onEventMove: moves.add,
                onEventResize: resizes.add,
                onEventOpen: (_) => opens++,
                timeZone: 'UTC',
                startHour: 7,
                endHour: 19,
                height: 650,
              ),
            ),
          ),
        );
        final event = find.text('Touch event');
        await tester.tap(event);
        await tester.pump();
        expect(opens, 1);
        // A touch swipe is scroll, not a move or resize.
        await tester.drag(event, const Offset(-90, 0), kind: kind);
        await tester.pumpAndSettle();
        expect(moves, isEmpty);
        expect(resizes, isEmpty);
        // Restore scroll and select with a stationary long press.
        final scroll = tester.state<ScrollableState>(
          find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
          ),
        );
        scroll.position.jumpTo(0);
        await tester.pump();
        final hold = await tester.startGesture(
          tester.getCenter(event),
          kind: kind,
        );
        await tester.pump(const Duration(milliseconds: 600));
        await hold.up();
        await tester.pumpAndSettle();
        expect(moves, isEmpty);
        expect(opens, 1);
        final handles = find.byWidgetPredicate(
          (w) =>
              w is GestureDetector &&
              (w.key == const ValueKey('calendar-touch-resize-start') ||
                  w.key == const ValueKey('calendar-touch-resize-end')),
        );
        expect(handles, findsNWidgets(2));
        for (final handle in handles.evaluate()) {
          expect(
            tester.getSize(find.byWidget(handle.widget)),
            const Size(48, 48),
          );
        }
        final end = handles.last;
        final gesture = await tester.startGesture(
          tester.getCenter(end),
          kind: kind,
        );
        await gesture.moveBy(
          allDay ? const Offset(160, 0) : const Offset(0, 56),
        );
        await gesture.moveBy(allDay ? const Offset(1, 0) : const Offset(0, 1));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
        expect(resizes, hasLength(1));
        expect(resizes.single.end.minutes, allDay ? 0 : 630);
        expect(resizes.single.edge, KCalendarResizeEdge.end);
        expect(resizes.single.end.date, allDay ? '2026-09-23' : '2026-09-21');
        expect(
          find.byWidgetPredicate(
            (w) => w is KCalendarTouchHandles && w.selected,
          ),
          findsOneWidget,
        );
        await tester.tapAt(const Offset(680, 740));
        await tester.pumpAndSettle();
        expect(handles, findsNothing);
        // Hold, then continue moving without lifting the finger.
        final moveGesture = await tester.startGesture(
          tester.getCenter(event),
          kind: kind,
        );
        await tester.pump(const Duration(milliseconds: 600));
        await moveGesture.moveBy(const Offset(160, 0));
        await tester.pump();
        await moveGesture.moveBy(const Offset(1, 0));
        await tester.pump();
        await moveGesture.up();
        await tester.pumpAndSettle();
        expect(moves, hasLength(1));
        expect(moves.single.target.date, '2026-09-22');
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('consumer controls and dismisses touch selection', (
    tester,
  ) async {
    String? selected;
    final requests = <String?>[];
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return KCalendar<String>(
                date: DateTime.utc(2026, 9, 21),
                view: KCalendarView.week,
                events: const ['Controlled'],
                eventId: (e) => e,
                eventStart: (_) => DateTime.utc(2026, 9, 21),
                eventEnd: (_) => DateTime.utc(2026, 9, 22),
                eventAllDay: (_) => true,
                eventBuilder: (_, e) => Text(e.event),
                onEventResize: (_) {},
                selectedEventId: selected,
                onSelectedEventChange: requests.add,
                timeZone: 'UTC',
                height: 400,
              );
            },
          ),
        ),
      ),
    );
    await tester.longPress(find.text('Controlled'));
    await tester.pumpAndSettle();
    expect(requests, ['Controlled']);
    expect(
      find.byKey(const ValueKey('calendar-touch-resize-end')),
      findsNothing,
    );
    rebuild(() => selected = 'Controlled');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('calendar-touch-resize-end')),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(750, 550));
    await tester.pump();
    expect(requests.last, isNull);
    rebuild(() => selected = null);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('calendar-touch-resize-end')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
