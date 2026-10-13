import 'package:card_stack_widget/card_stack_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_widgetbook/screen_switcher_reference_fixture.dart';

void main() {
  testWidgets('reference keeps gestures and renders every card upright', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: ScreenSwitcherReferenceFixture()),
      ),
    );
    await tester.pumpAndSettle();
    final stack = tester.widget<CardStackWidget>(find.byType(CardStackWidget));
    expect(stack.cardList.length, 15);
    expect(stack.swipeOrientation, CardOrientation.both);
    expect(stack.cardDismissOrientation, CardOrientation.both);
    expect(stack.animateCardScale, false);
    for (final card in tester.widgetList<CardWidget>(find.byType(CardWidget))) {
      expect(card.scale, inInclusiveRange(0.72, 1.0));
    }
    await tester.drag(find.byType(CardStackWidget), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Stapel zurücksetzen'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CardStackWidget>(find.byType(CardStackWidget))
          .cardList
          .length,
      15,
    );
  });
}
