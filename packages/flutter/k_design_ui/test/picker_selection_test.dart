import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/pickers/picker_panel.dart';
import 'package:k_design_ui/src/pickers/picker_time.dart';

void main() {
  Future<void> mount(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(body: SizedBox(width: 360, child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
  }

  Finder column(String label) => find.byWidgetPredicate(
    (widget) => widget is PickerTimeColumn && widget.label == label,
  );
  Finder option(String label, String value) => find.descendant(
    of: column(label),
    matching: find.widgetWithText(TextButton, value),
  );
  testWidgets(
    'default field opens selection panel without manual date fields',
    (tester) async {
      await mount(tester, KDatePicker(value: '2026-09-16', onChanged: (_) {}));
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('Apply'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      final input = tester.widget<TextField>(find.byType(TextField));
      input.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('Apply'), findsOneWidget);
    },
  );
  testWidgets(
    'time selector preserves off-step minute and commits only on Apply',
    (tester) async {
      String? value = '13:37';
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => KTimePicker(
            value: value,
            minuteStep: 15,
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      );
      await open(tester);
      expect(find.byType(TextField), findsOneWidget);
      expect(option('Minutes', '37'), findsOneWidget);
      await tester.tap(option('Hours', '14'));
      await tester.pumpAndSettle();
      expect(value, '13:37');
      await tester.tap(option('Minutes', '45'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(value, '14:45');
    },
  );
  testWidgets('h12 hour keyboard and period selector edit local draft', (
    tester,
  ) async {
    String? value = '00:15';
    await mount(
      tester,
      KTimePicker(
        value: value,
        timeFormat: KTimeFormat.h12,
        minuteStep: 15,
        onChanged: (next) => value = next,
      ),
    );
    await open(tester);
    final hour = tester.widget<TextButton>(option('Hours', '12'));
    hour.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(option('Hours', '01'), findsOneWidget);
    await tester.tap(option('Period', 'PM'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(value, '13:15');
  });
  testWidgets(
    'month and year chooser browse without prematurely selecting date',
    (tester) async {
      String? value = '2026-09-16';
      await mount(
        tester,
        KDatePicker(value: value, onChanged: (next) => value = next),
      );
      await open(tester);
      await tester.tap(find.widgetWithText(TextButton, 'September'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Oct'));
      await tester.pumpAndSettle();
      expect(find.text('October'), findsOneWidget);
      expect(value, '2026-09-16');
      await tester.tap(find.widgetWithText(TextButton, '2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '2027'));
      await tester.pumpAndSettle();
      expect(value, '2026-09-16');
      await tester.tap(find.widgetWithText(TextButton, '17'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(value, '2027-10-17');
    },
  );
  testWidgets(
    'datetime uses two equal columns on desktop and stacks on phone',
    (tester) async {
      await mount(
        tester,
        KDateTimePicker(value: '2026-09-16T10:30:00.000Z', onChanged: (_) {}),
      );
      await open(tester);
      expect(tester.getSize(find.byType(PickerPanel)).width, 720);
      expect(
        tester.getTopLeft(column('Hours')).dy,
        lessThan(
          tester.getBottomLeft(find.widgetWithText(TextButton, '16')).dy,
        ),
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester);
      expect(tester.getSize(find.byType(PickerPanel)).width, 359);
      expect(
        tester.getTopLeft(column('Hours')).dy,
        greaterThan(
          tester.getBottomLeft(find.widgetWithText(TextButton, '16')).dy,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'invalid minuteStep is rejected and manual entry is explicitly optional',
    (tester) async {
      await mount(
        tester,
        KTimePicker(value: '10:00', minuteStep: 7, onChanged: (_) {}),
      );
      expect(tester.takeException(), isArgumentError);
      await mount(
        tester,
        KTimePicker(
          value: '10:00',
          minuteStep: 15,
          allowTextInput: true,
          onChanged: (_) {},
        ),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).readOnly,
        isFalse,
      );
      await open(tester);
      expect(find.byType(TextField), findsNWidgets(2));
    },
  );
  testWidgets(
    'month and year grids focus the active choice and restore same-day focus',
    (tester) async {
      await mount(tester, KDatePicker(value: '2026-09-16', onChanged: (_) {}));
      await open(tester);
      await tester.tap(find.widgetWithText(TextButton, 'September'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Sep'))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '16'))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.tap(find.widgetWithText(TextButton, '2026'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '2026'))
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '16'))
            .focusNode!
            .hasFocus,
        isTrue,
      );
    },
  );
  testWidgets(
    'paging month chooser does not highlight a month in another year',
    (tester) async {
      final handle = tester.ensureSemantics();
      await mount(tester, KDatePicker(value: '2026-09-16', onChanged: (_) {}));
      await open(tester);
      await tester.tap(find.widgetWithText(TextButton, 'September'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next year'));
      await tester.pumpAndSettle();
      final september = tester
          .getSemantics(find.widgetWithText(TextButton, 'Sep'))
          .getSemanticsData();
      expect(september.flagsCollection.isSelected.name, 'isFalse');
      handle.dispose();
    },
  );
  testWidgets('drag across readonly picker field does not open a dialog', (
    tester,
  ) async {
    await mount(tester, KDatePicker(value: '2026-09-16', onChanged: (_) {}));
    await tester.drag(find.byType(TextField), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(find.text('Apply'), findsNothing);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('Apply'), findsOneWidget);
  });
  testWidgets('dialog stays within the nearest 375px navigator viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Center(
          child: SizedBox(
            width: 375,
            height: 812,
            child: MediaQuery(
              data: const MediaQueryData(size: Size(375, 812)),
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    body: KDateTimePicker(
                      value: '2026-09-16T10:30:00.000Z',
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await open(tester);
    final panel = tester.getRect(find.byType(PickerPanel));
    expect(panel.width, 359);
    expect(panel.left, closeTo((1024 - 375) / 2 + 8, .1));
    expect(
      tester.getTopLeft(column('Hours')).dy,
      greaterThan(
        tester.getBottomLeft(find.widgetWithText(TextButton, '16')).dy,
      ),
    );
    expect(
      MediaQuery.sizeOf(tester.element(find.byType(PickerPanel))),
      const Size(375, 812),
    );
    expect(tester.takeException(), isNull);
  });
}
