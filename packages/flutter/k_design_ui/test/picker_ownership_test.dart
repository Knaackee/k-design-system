import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final kind in ['date', 'time', 'datetime']) {
    testWidgets(
      '$kind modal reports balanced ownership after commit and cancel',
      (tester) async {
        final events = <String>[];
        void open(bool value) => events.add('open:$value');
        void changed(String? value) => events.add('value');
        final picker = switch (kind) {
          'time' => KTimePicker(
            value: '14:30',
            onChanged: changed,
            onOpenChange: open,
          ),
          'datetime' => KDateTimePicker(
            value: '2026-09-17T12:30:00Z',
            timeZone: 'Europe/Berlin',
            onChanged: changed,
            onOpenChange: open,
          ),
          _ => KDatePicker(
            value: '2026-09-17',
            onChanged: changed,
            onOpenChange: open,
          ),
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Scaffold(body: SizedBox(width: 360, child: picker)),
          ),
        );
        await tester.tap(find.byType(FilledButton).first);
        await tester.pumpAndSettle();
        expect(events, ['open:true']);
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
        expect(events, ['open:true', 'value', 'open:false']);
        await tester.tap(find.byType(FilledButton).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(events, [
          'open:true',
          'value',
          'open:false',
          'open:true',
          'open:false',
        ]);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('removing open picker releases ownership and removes its route', (
    tester,
  ) async {
    final events = <bool>[];
    late StateSetter update;
    var visible = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return visible
                  ? SizedBox(
                      width: 360,
                      child: KDatePicker(
                        value: '2026-09-17',
                        onChanged: (_) {},
                        onOpenChange: events.add,
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    expect(find.text('Apply'), findsOneWidget);
    update(() => visible = false);
    await tester.pumpAndSettle();
    expect(events, [true, false]);
    expect(find.text('Apply'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
