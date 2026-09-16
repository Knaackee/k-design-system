import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_widgetbook/picker_fixtures.dart';

void main() {
  for (final kind in ['date', 'time', 'date-time']) {
    testWidgets('$kind fixture clears only its editable controlled value', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(body: PickerFixture(kind: kind)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Europe/Berlin"), findsNothing);
      final inputs = find.byType(TextField);
      expect(inputs, findsNWidgets(3));
      expect(tester.widget<TextField>(inputs.first).readOnly, isTrue);
      final original = tester.widget<TextField>(inputs.at(1)).controller!.text;
      expect(original, isNotEmpty);
      expect(tester.widget<TextField>(inputs.at(1)).readOnly, isTrue);
      expect(tester.widget<TextField>(inputs.at(2)).enabled, isFalse);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is FilledButton && widget.onPressed != null,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Europe/Berlin"), findsNothing);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(inputs.first).controller!.text, isEmpty);
      expect(tester.widget<TextField>(inputs.at(1)).controller!.text, original);
      expect(tester.widget<TextField>(inputs.at(2)).controller!.text, original);
      expect(find.text('Value: None'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
