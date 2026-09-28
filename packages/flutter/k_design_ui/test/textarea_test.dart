import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'multiline edits, length limit and external controller survive rebuilds',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      Widget screen({bool readOnly = false, bool enabled = true}) =>
          MaterialApp(
            theme: kDesignTheme(),
            home: Scaffold(
              body: KField(
                label: 'Notes',
                required: true,
                errorText: 'Check the notes.',
                child: KTextarea(
                  controller: controller,
                  rows: 3,
                  maxLength: 12,
                  readOnly: readOnly,
                  enabled: enabled,
                ),
              ),
            ),
          );
      await tester.pumpWidget(screen());
      await tester.enterText(find.byType(TextField), 'Roof\nWalls');
      expect(controller.text, 'Roof\nWalls');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.minLines, 3);
      expect(field.maxLines, 3);
      expect(field.textInputAction, TextInputAction.newline);
      await tester.enterText(find.byType(TextField), 'abcdefghijklmnop');
      expect(controller.text, 'abcdefghijkl');
      await tester.pumpWidget(screen(readOnly: true));
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      expect(controller.text, 'abcdefghijkl');
      await tester.pumpWidget(screen(enabled: false));
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(controller.text, 'abcdefghijkl');
      await tester.pumpWidget(const SizedBox());
      controller.text = 'Still owned';
    },
  );
}
