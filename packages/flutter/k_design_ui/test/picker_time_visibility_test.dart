import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/pickers/picker_calendar.dart';
import 'package:k_design_ui/src/pickers/picker_panel.dart';
import 'package:k_design_ui/src/pickers/picker_time.dart';

void main() {
  for (final width in [375.0, 1024.0]) {
    testWidgets(
      'time stays hidden until explicit date selection at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? value = '2026-09-16T10:30:00.000Z';
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Scaffold(
              body: KDateTimePicker(
                value: value,
                onChanged: (next) => value = next,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton).first);
        await tester.pumpAndSettle();
        expect(find.byType(PickerTime), findsOneWidget);
        final calendarWidth = tester.getSize(find.byType(PickerCalendar)).width;
        final panelWidth = tester.getSize(find.byType(PickerPanel)).width;
        await tester.tap(find.widgetWithText(TextButton, 'September'));
        await tester.pumpAndSettle();
        expect(find.byType(PickerTime), findsNothing);
        expect(
          tester.getSize(find.byType(PickerCalendar)).width,
          calendarWidth,
        );
        expect(tester.getSize(find.byType(PickerPanel)).width, panelWidth);
        await tester.tap(find.widgetWithText(TextButton, 'Oct'));
        await tester.pumpAndSettle();
        expect(find.byType(PickerTime), findsNothing);
        await tester.tap(find.widgetWithText(TextButton, '2026'));
        await tester.pumpAndSettle();
        expect(find.byType(PickerTime), findsNothing);
        await tester.tap(find.widgetWithText(TextButton, '2027'));
        await tester.pumpAndSettle();
        expect(find.byType(PickerTime), findsNothing);
        await tester.tap(find.widgetWithText(TextButton, '17'));
        await tester.pumpAndSettle();
        expect(find.byType(PickerTime), findsOneWidget);
        expect(value, '2026-09-16T10:30:00.000Z');
        await tester.tap(find.byTooltip('Next month'));
        await tester.pumpAndSettle();
        expect(find.byType(PickerTime), findsNothing);
        await tester.tap(find.widgetWithText(TextButton, '18'));
        await tester.pumpAndSettle();
        expect(find.byType(PickerTime), findsOneWidget);
        await tester.ensureVisible(find.text('Apply'));
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
        expect(value, '2027-11-18T10:30:00.000Z');
      },
    );
  }
  testWidgets(
    'empty DateTime requires a chosen day and validates manual date confirmation',
    (tester) async {
      Future<void> mount({bool manual = false}) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Scaffold(
              body: KDateTimePicker(
                value: null,
                onChanged: (_) {},
                allowTextInput: manual,
                now: DateTime.utc(2026, 9, 16, 10, 30),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilledButton).first);
        await tester.pumpAndSettle();
      }

      await mount();
      expect(find.byType(PickerTime), findsNothing);
      await tester.tap(find.widgetWithText(TextButton, '16'));
      await tester.pumpAndSettle();
      expect(find.byType(PickerTime), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await mount(manual: true);
      expect(find.byType(PickerTime), findsNothing);
      await tester.enterText(find.byType(TextField).last, '2026-02-30');
      await tester.pumpAndSettle();
      expect(find.byType(PickerTime), findsNothing);
      await tester.enterText(find.byType(TextField).last, '2026-09-20');
      await tester.pumpAndSettle();
      expect(find.byType(PickerTime), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'invalid');
      await tester.pumpAndSettle();
      expect(find.byType(PickerTime), findsNothing);
    },
  );
}
