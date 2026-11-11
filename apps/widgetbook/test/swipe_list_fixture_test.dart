import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/swipe_card_fixtures.dart';

void main() {
  testWidgets('swipe list scrolls to its actions on a large-text phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme().copyWith(platform: TargetPlatform.iOS),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(body: SwipeListFixture()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(KPage), findsOneWidget);
    await tester.ensureVisible(find.text('Reset list'));
    await tester.pumpAndSettle();
    expect(find.text('Reset list').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Reset list'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Mara Feld'), findsOneWidget);
    expect(find.text('Tom Seidel'), findsOneWidget);
  });
}
