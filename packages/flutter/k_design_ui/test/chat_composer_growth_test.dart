import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

void main() {
  for (final width in [375.0, 1100.0]) {
    testWidgets('composer grows and caps text height at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: KChatComposer(
                value: '',
                onValueChanged: (_) {},
                onSubmit: (_) {},
              ),
            ),
          ),
        ),
      );
      final field = find.byType(TextField);
      final initial = tester.getSize(field).height;
      await tester.enterText(
        field,
        List.filled(4, 'A longer message').join('\n'),
      );
      await tester.pump();
      expect(tester.getSize(field).height, greaterThan(initial));
      await tester.enterText(
        field,
        List.filled(40, 'A longer message').join('\n'),
      );
      await tester.pump();
      expect(tester.getSize(field).height, lessThanOrEqualTo(200));
      expect(tester.takeException(), isNull);
    });
  }
}
