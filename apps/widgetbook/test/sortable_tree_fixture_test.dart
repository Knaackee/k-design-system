import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/sortable_tree_fixture.dart';

void main() {
  testWidgets('add category validates, saves and can undo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
        home: const Scaffold(body: SortableTreeFixture(kind: 'empty')),
      ),
    );
    await tester.tap(find.text('Kategorie'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(KButton, 'Übernehmen');
    expect(tester.widget<KButton>(save).onPressed, isNull);
    await tester.enterText(
      find.descendant(
        of: find.byType(KDialog),
        matching: find.byType(EditableText),
      ),
      'Neue Angebote',
    );
    await tester.pump();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Neue Angebote'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.widgetWithText(KButton, 'Rückgängig'));
    await tester.pumpAndSettle();
    expect(find.text('Neue Angebote'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 900.0]) {
    testWidgets('offer gallery fits $width with enlarged text', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [KDesignTokens.orbitDark]),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 900),
              textScaler: const TextScaler.linear(1.5),
            ),
            child: const Scaffold(body: SortableTreeFixture(kind: 'ungrouped')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Ohne Kategorie'), findsOneWidget);
      expect(find.byType(KSelect), findsOneWidget);
      // Ungrouped offers start collapsed, matching the onboarding fixture.
      expect(find.text('Pflegeshampoo'), findsNothing);
      await tester.tap(find.text('Ohne Kategorie'));
      await tester.pumpAndSettle();
      expect(find.text('Pflegeshampoo'), findsOneWidget);
      await tester.tap(find.text('Ohne Kategorie'));
      await tester.pumpAndSettle();
      expect(find.text('Pflegeshampoo'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
