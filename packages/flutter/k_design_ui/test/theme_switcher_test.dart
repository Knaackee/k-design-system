import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'theme button reports next choice and stays consumer controlled',
    (tester) async {
      ThemeMode? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: KThemeSwitcher(
              value: ThemeMode.light,
              onChanged: (mode) => selected = mode,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(KThemeSwitcher));
      await tester.pumpAndSettle();
      expect(selected, ThemeMode.dark);
      expect(
        tester.widget<KThemeSwitcher>(find.byType(KThemeSwitcher)).value,
        ThemeMode.light,
      );
      expect(find.text('Dark'), findsNothing);
    },
  );
  testWidgets('consumer can cycle light dark system and back', (tester) async {
    var mode = ThemeMode.light;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: KThemeSwitcher(
              value: mode,
              onChanged: (value) => setState(() => mode = value),
            ),
          ),
        ),
      ),
    );
    for (final expected in [
      ThemeMode.dark,
      ThemeMode.system,
      ThemeMode.light,
    ]) {
      await tester.tap(find.byType(KThemeSwitcher));
      await tester.pumpAndSettle();
      expect(mode, expected);
    }
  });
  testWidgets('custom labels and disabled trigger are respected', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KThemeSwitcher(
            value: ThemeMode.system,
            label: 'Darstellung',
            labels: const {ThemeMode.system: 'Automatisch'},
            disabled: true,
            onChanged: (_) => fail('Disabled'),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Darstellung: Automatisch'), findsWidgets);
    await tester.tap(find.byType(KThemeSwitcher));
    await tester.pumpAndSettle();
    expect(find.text('Light'), findsNothing);
  });
}
