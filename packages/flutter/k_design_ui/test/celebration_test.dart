import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('Reveal is nonblocking, settles and does not replay on rebuild', (
    tester,
  ) async {
    var tapped = 0;
    Widget build() => MaterialApp(
      theme: kDesignTheme(),
      home: Scaffold(
        body: Center(
          child: KCelebration(
            active: true,
            child: TextButton(
              onPressed: () => tapped++,
              child: const Text('Edit'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(build());
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Edit'));
    expect(tapped, 1);
    await tester.pumpAndSettle();
    await tester.pumpWidget(build());
    expect(
      tester
          .widget<Opacity>(
            find
                .descendant(
                  of: find.byType(KCelebration),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      1,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Reduced motion keeps child visible without particles', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const KCelebration(active: true, child: Text('Identity')),
        ),
      ),
    );
    expect(find.text('Identity'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(KCelebration),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });
}
