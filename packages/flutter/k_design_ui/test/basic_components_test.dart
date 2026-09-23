import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget frame(Widget child) => MaterialApp(
  theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('attachment exposes activation without owning navigation', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      frame(
        KAttachment(
          title: const Text('Brief.pdf'),
          activateLabel: 'Open Brief.pdf',
          onActivate: () => activations++,
        ),
      ),
    );

    await tester.tap(find.text('Brief.pdf'));
    expect(activations, 1);
  });

  testWidgets('alert dialog returns the selected result', (tester) async {
    await tester.pumpWidget(
      frame(
        Builder(
          builder: (context) => KButton(
            label: 'Open',
            onPressed: () => KAlertDialog.show(
              context: context,
              title: const Text('Delete project?'),
              description: const Text('This cannot be undone.'),
              cancelLabel: 'Cancel',
              actionLabel: 'Delete',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete project?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete project?'), findsNothing);
  });

  testWidgets('carousel reports page changes', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      frame(
        SizedBox(
          width: 480,
          child: KCarousel(
            label: 'Projects',
            onIndexChanged: (value) => selected = value,
            children: const [Text('First'), Text('Second')],
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Next slide'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.text('Second'), findsOneWidget);
  });
}
