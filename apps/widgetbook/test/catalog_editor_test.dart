import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_widgetbook/catalog_editor_fixture.dart';

void main() {
  for (final width in [390.0, 1024.0]) {
    for (final dark in [false, true]) {
      testWidgets('catalog editor fits $width dark=$dark', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: CatalogEditorFixture(product: true, dark: dark),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Produkt bearbeiten'), findsOneWidget);
        final save = find.byWidgetPredicate(
          (w) => w is KButton && w.label == 'Speichern',
        );
        expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(844));
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.text('Gespeichert'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('stock remains separate from draft and supports recount', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const CatalogEditorFixture(product: true, panel: 'stock'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bestand ändern'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Jetzt buchen'));
    await tester.pumpAndSettle();
    expect(find.text('11 verfügbar'), findsWidgets);
    expect(find.text('Bestand in dieser Demo gebucht'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
