import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('textarea preserves existing prose keyboard defaults', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: KTextarea())),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autocorrect, isTrue);
    expect(field.enableSuggestions, isTrue);
    expect(field.smartDashesType, SmartDashesType.enabled);
    expect(field.smartQuotesType, SmartQuotesType.enabled);
    expect(field.enableIMEPersonalizedLearning, isTrue);
  });

  testWidgets(
    'literal sensitive text disables correction and keyboard learning',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: KTextarea(
              autocorrect: false,
              enableIMEPersonalizedLearning: false,
            ),
          ),
        ),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.smartDashesType, SmartDashesType.disabled);
      expect(field.smartQuotesType, SmartQuotesType.disabled);
      expect(field.enableIMEPersonalizedLearning, isFalse);
      const pem =
          '-----BEGIN PRIVATE KEY-----\nabc+/123=\n-----END PRIVATE KEY-----';
      await tester.enterText(find.byType(TextField), pem);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        pem,
      );
    },
  );
}
