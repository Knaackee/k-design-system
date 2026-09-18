import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/data_table_cells_fixture.dart';

Future<void> mount(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1024, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: kDesignTheme(),
      home: const Scaffold(body: DataTableCellsFixture()),
    ),
  );
  await tester.pumpAndSettle();
}

Finder cell(String kind) => find.byWidgetPredicate(
  (w) => w is KEditableCell && w.label == 'Cell $kind',
);
Finder input(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is KInput && w.label == label),
  matching: find.byType(TextField),
);
void main() {
  testWidgets(
    'text, checkbox, selection, combobox and currency are consumer controlled',
    (tester) async {
      await mount(tester);
      await tester.tap(cell('text'));
      await tester.pumpAndSettle();
      await tester.enterText(input('Cell text'), 'Edited project');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Edited project'), findsOneWidget);
      await tester.tap(find.byType(KCheckbox));
      await tester.pumpAndSettle();
      expect(tester.widget<KCheckbox>(find.byType(KCheckbox)).value, false);
      await tester.tap(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) => w is KSelect && w.label == 'Cell select',
          ),
          matching: find.byType(TextField),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Planned').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<KSelect>(
              find.byWidgetPredicate(
                (w) => w is KSelect && w.label == 'Cell select',
              ),
            )
            .value,
        'planned',
      );
      final combo = find.descendant(
        of: find.byType(KCombobox),
        matching: find.byType(TextField),
      );
      await tester.tap(combo);
      await tester.pumpAndSettle();
      expect(find.text('Sam Rivera'), findsOneWidget);
      await tester.tap(find.text('Sam Rivera'));
      await tester.pumpAndSettle();
      expect(tester.widget<KCombobox>(find.byType(KCombobox)).value, 'sam');
      await tester.tap(cell('currency'));
      await tester.pumpAndSettle();
      final currency = find.descendant(
        of: find.byType(KCurrencyInput),
        matching: find.byType(TextField),
      );
      await tester.enterText(currency, '987,65');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('987,65\u00a0€'), findsOneWidget);
      expect(tester.widget<KEditableCell>(cell('readonly')).onEdit, isNull);
    },
  );
  for (final kind in ['date', 'time', 'datetime']) {
    testWidgets(
      '$kind inline picker opens in one click and cancel retains value',
      (tester) async {
        await mount(tester);
        final picker = find.byWidgetPredicate(
          (w) => w is KDatePicker && w.label == 'Cell $kind',
        );
        final value = tester.widget<KDatePicker>(picker).value;
        await tester.tap(cell(kind));
        await tester.pumpAndSettle();
        expect(find.text('Apply'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(tester.widget<KDatePicker>(picker).value, value);
      },
    );
  }
}
