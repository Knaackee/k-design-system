import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('builder page sheet respects its narrower surface width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: KButton(
              label: 'Open',
              onPressed: () => KPageSheet.show<void>(
                context: context,
                builder: (_) => const KPageSheet(
                  maxWidth: 480,
                  title: Text('Title'),
                  child: SizedBox(width: double.infinity, child: Text('Body')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.text('Body')).width, lessThanOrEqualTo(480));
    expect(tester.takeException(), isNull);
  });
  for (final size in [const Size(390, 844), const Size(1200, 800)]) {
    testWidgets('page sheet scrolls and closes at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: KButton(
                onPressed: () => KPageSheet.show<void>(
                  context: context,
                  title: const Text('Edit day'),
                  actions: const Text('Save action'),
                  child: Column(
                    children: List.generate(
                      30,
                      (i) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Row $i'),
                      ),
                    ),
                  ),
                ),
                label: 'Open',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(find.text('Save action').hitTestable(), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Row 29'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Row 29').hitTestable(), findsOneWidget);
      expect(find.text('Save action').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Edit day'), findsNothing);
    });
  }
}
