import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/quick_create_offer_fixture.dart';

void main() {
  testWidgets('quick create gallery opens all five UI-only options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: KAdaptiveTheme(
          overrides: const KAdaptiveOverrides(style: KStyle.material),
          child: const Scaffold(body: QuickCreateOfferFixture()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final action = find.bySemanticsLabel('Neu erstellen');
    expect(action, findsOneWidget);
    final fab = tester.widget<KFab>(find.byType(KFab));
    final tokens = Theme.of(
      tester.element(find.byType(KFab)),
    ).extension<KDesignTokens>()!;
    expect(fab.size, tokens.componentFabHeight);
    expect(
      fab.style!.backgroundColor!.resolve({}),
      tokens.componentFabBackground,
    );
    expect((fab.child as KIcon).color, tokens.componentFabForeground);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byType(KBottomSheet), findsNothing);
    expect(find.byType(KAdaptiveDialog), findsNothing);
    for (final label in [
      'Termin',
      'Kund:in',
      'Leistung',
      'Produkt',
      'Privater Termin',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    await tester.tap(find.bySemanticsLabel('Kund:in'));
    await tester.pumpAndSettle();
    expect(find.text('Kund:in ausgewählt · UI-Vorschau'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
