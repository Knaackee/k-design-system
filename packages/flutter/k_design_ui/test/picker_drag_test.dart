import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/pickers/picker_time.dart';

void main() {
  for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
    testWidgets('time column scrolls with $kind drag without changing draft', (
      tester,
    ) async {
      String? value = '10:30';
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: KTimePicker(value: value, onChanged: (next) => value = next),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();
      final column = find.byWidgetPredicate(
        (widget) => widget is PickerTimeColumn && widget.label == 'Hours',
      );
      final list = find.descendant(of: column, matching: find.byType(ListView));
      final scroll = find.descendant(
        of: list,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scroll).position;
      final before = position.pixels;
      await tester.drag(list, const Offset(0, -100), kind: kind);
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(before + 20));
      expect(value, '10:30');
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(value, '10:30');
    });
  }
}
