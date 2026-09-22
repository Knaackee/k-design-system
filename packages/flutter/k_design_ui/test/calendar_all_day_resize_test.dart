import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/patterns/k_calendar_days.dart';

void main() {
  for (final extendStart in [false, true]) {
    testWidgets(
      'all-day resize exposes preview before commit (start: $extendStart)',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        KCalendarResize<_E>? committed;
        final phases = <KCalendarInteractionPhase>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Scaffold(
              body: KCalendar<_E>(
                date: DateTime.utc(2026, 9, 21),
                view: KCalendarView.week,
                events: const [_E()],
                eventId: (_) => 'e',
                eventStart: (_) => DateTime.utc(2026, 9, extendStart ? 22 : 21),
                eventEnd: (_) => DateTime.utc(2026, 9, extendStart ? 23 : 24),
                eventAllDay: (_) => true,
                eventBuilder: (_, _) => const Text('event'),
                onEventResize: (v) => committed = v,
                onEventMove: (_) {},
                onInteraction: (event) => phases.add(event.phase),
                height: 500,
              ),
            ),
          ),
        );
        await tester.pump();
        final handle = find.bySemanticsLabel(
          extendStart ? 'Change start' : 'Change end',
        );
        expect(handle, findsOneWidget);
        final g = await tester.startGesture(tester.getCenter(handle));
        await g.moveBy(const Offset(-160, 0));
        await g.moveBy(const Offset(-1, 0));
        await tester.pump();
        final days = tester.widget<KCalendarDays<_E>>(
          find.byType(KCalendarDays<_E>),
        );
        expect(days.previewResize?.end.date, '2026-09-23');
        expect(days.previewResize?.start.date, '2026-09-21');
        final overlay = find.byWidgetPredicate(
          (w) => w is Opacity && w.opacity == .78,
        );
        final calendarRect = tester.getRect(find.byType(KCalendarDays<_E>));
        final overlayRect = tester.getRect(overlay);
        expect(overlayRect.left, closeTo(calendarRect.left + 4, .01));
        expect(overlayRect.width, closeTo(calendarRect.width / 7 * 2 - 8, .01));
        expect(committed, isNull);
        await g.up();
        await tester.pump();
        expect(committed?.end.date, '2026-09-23');
        expect(phases, contains(KCalendarInteractionPhase.preview));
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _E {
  const _E();
}
