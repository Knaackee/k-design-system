import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/patterns/k_calendar_days.dart';

void main() {
  for (final scrollOffset in [0.0, 110.0]) {
    testWidgets(
      'all-day preview and drop agree after scrolling $scrollOffset',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(520, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        KCalendarMove<String>? committed;
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(brightness: Brightness.light),
            home: Scaffold(
              body: KCalendar<String>(
                date: DateTime(2026, 9, 21),
                view: KCalendarView.week,
                events: const ['Monday'],
                eventId: (event) => event,
                eventStart: (_) => DateTime(2026, 9, 21),
                eventEnd: (_) => DateTime(2026, 9, 22),
                eventAllDay: (_) => true,
                eventBuilder: (_, event) => Text(event.event),
                onEventMove: (move) => committed = move,
                onEventResize: (_) {},
                timeZone: 'UTC',
                height: 500,
              ),
            ),
          ),
        );
        final horizontal = tester.state<ScrollableState>(
          find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
          ),
        );
        horizontal.position.jumpTo(scrollOffset);
        await tester.pump();
        final lane = find.byType(KCalendarDays<String>);
        final rect = tester.getRect(lane);
        final origin = Offset(rect.left + 132, rect.top + 18);
        final target = Offset(rect.left + 160 + 65, rect.top + 18);
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: origin);
        await tester.pump();
        await gesture.down(origin);
        await tester.pump(const Duration(milliseconds: 600));
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump();
        await gesture.moveTo(target);
        await tester.pump();
        var days = tester.widget<KCalendarDays<String>>(lane);
        expect(days.previewMove?.start.date, '2026-09-22');
        expect(
          committed,
          isNull,
          reason: 'Preview must be visible before release',
        );
        final overlay = find.descendant(
          of: lane,
          matching: find.byWidgetPredicate(
            (w) => w is Opacity && w.opacity == .78,
          ),
        );
        expect(overlay, findsOneWidget);
        expect(tester.getRect(overlay).width, greaterThan(0));
        // Move back without dropping: the existing recognizer must survive.
        await gesture.moveTo(origin);
        await tester.pump();
        days = tester.widget<KCalendarDays<String>>(lane);
        expect(days.previewMove?.start.date, '2026-09-21');
        await gesture.moveTo(target);
        await tester.pump();
        await gesture.up();
        await tester.pump();
        expect(committed?.target.date, '2026-09-22');
        expect(tester.takeException(), isNull);
        await gesture.removePointer();
      },
    );
  }
}
