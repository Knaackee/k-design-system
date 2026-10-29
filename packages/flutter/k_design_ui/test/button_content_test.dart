import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('rich content keeps accessible button name and tap action', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KButton(
            label: 'Choose categories',
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text('Categories'), Text('Hair · Face · Nails')],
            ),
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Choose categories'), findsOneWidget);
    expect(find.bySemanticsLabel('Hair · Face · Nails'), findsNothing);
    await tester.tap(find.text('Categories'));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
