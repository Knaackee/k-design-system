import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('button activates once and renders from theme tokens', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Center(
          child: KButton(label: 'Continue', onPressed: () => activations += 1),
        ),
      ),
    );

    await tester.tap(find.text('Continue'));
    expect(activations, 1);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('loading button blocks activation', (tester) async {
    var activated = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KButton(
          label: 'Saving',
          loading: true,
          onPressed: () => activated = true,
        ),
      ),
    );

    await tester.tap(find.text('Saving'));
    expect(activated, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
