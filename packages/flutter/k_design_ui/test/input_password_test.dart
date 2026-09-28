import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'password input masks text while preserving controller and defaults',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      Widget screen(bool masked) => MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KInput(controller: controller, obscureText: masked),
        ),
      );
      await tester.pumpWidget(screen(true));
      await tester.enterText(find.byType(TextField), 'Synthetic-password-123');
      var field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(controller.text, 'Synthetic-password-123');
      await tester.pumpWidget(screen(false));
      field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isFalse);
      expect(field.autocorrect, isTrue);
      expect(field.enableSuggestions, isTrue);
      expect(controller.text, 'Synthetic-password-123');
    },
  );
}
