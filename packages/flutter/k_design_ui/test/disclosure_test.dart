import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget frame(Widget child) => MaterialApp(
  theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('trailing action leaves disclosure state unchanged', (
    tester,
  ) async {
    var actionCount = 0;
    await tester.pumpWidget(
      frame(
        KDisclosure(
          title: 'Details',
          actions: TextButton(
            onPressed: () => actionCount++,
            child: const Text('More'),
          ),
          child: const Text('Content'),
        ),
      ),
    );

    await tester.tap(find.text('More'));
    await tester.pump();
    expect(actionCount, 1);
    expect(find.text('Content'), findsNothing);

    await tester.tap(find.text('Details'));
    await tester.pump();
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('accordion opens one section at a time', (tester) async {
    await tester.pumpWidget(
      frame(
        const KAccordion(
          defaultValue: ['first'],
          items: [
            KAccordionItem(id: 'first', title: 'First', child: Text('One')),
            KAccordionItem(id: 'second', title: 'Second', child: Text('Two')),
          ],
        ),
      ),
    );

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsNothing);
    await tester.tap(find.text('Second'));
    await tester.pump();
    expect(find.text('One'), findsNothing);
    expect(find.text('Two'), findsOneWidget);
  });
}
