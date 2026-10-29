import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'language menu selects once, closes and keeps theme-button target size',
    (tester) async {
      var value = 'de';
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Row(
                children: [
                  KLanguageSwitcher(
                    value: value,
                    onChanged: (next) {
                      calls++;
                      setState(() => value = next);
                    },
                    languages: const [
                      KLanguageOption(value: 'de', label: 'Deutsch'),
                      KLanguageOption(value: 'en', label: 'English'),
                    ],
                  ),
                  KThemeSwitcher(value: ThemeMode.light, onChanged: (_) {}),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(KLanguageSwitcher)),
        tester.getSize(find.byType(KThemeSwitcher)),
      );
      await tester.tap(find.byType(KLanguageSwitcher));
      await tester.pumpAndSettle();
      expect(find.text('English'), findsOneWidget);
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(value, 'en');
      expect(calls, 1);
      expect(find.text('English'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
