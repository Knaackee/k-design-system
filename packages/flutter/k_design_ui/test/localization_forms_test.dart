import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/generated/locales.dart';

void main() {
  testWidgets(
    'localized clear reset and remove defaults preserve overrides and labels',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController(text: 'Consumer text');
      addTearDown(controller.dispose);
      final messages = kLocaleCatalog['de']!['messages'] as Map;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: KLocalization(
              locale: 'de',
              child: Column(
                children: [
                  KInput(
                    controller: controller,
                    clearable: true,
                    label: 'Consumer input',
                  ),
                  KSelect(
                    options: const [
                      KSelectOption(value: 'a', label: 'Consumer option'),
                    ],
                    value: 'a',
                    onChanged: (_) {},
                    clearable: true,
                    clearLabel: 'Remove choice',
                  ),
                  KFilterChip(label: 'Consumer chip', onRemove: () {}),
                  KFilterChip(
                    label: 'Other chip',
                    onRemove: () {},
                    removeLabel: 'Custom remove',
                  ),
                  KFilterBar(
                    label: 'Consumer filters',
                    onReset: () {},
                    children: const [],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(messages['clear'] as String),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Remove choice'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          (messages['remove'] as String).replaceAll('{label}', 'Consumer chip'),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Custom remove'), findsOneWidget);
      expect(find.text(messages['resetAll'] as String), findsOneWidget);
      expect(find.text('Consumer option'), findsOneWidget);
      semantics.dispose();
    },
  );
  testWidgets(
    'combobox overlay inherits localized results and options with overrides',
    (tester) async {
      final semantics = tester.ensureSemantics();
      Future<void> mount({String? optionsLabel, String? noResultsLabel}) =>
          tester.pumpWidget(
            MaterialApp(
              theme: kDesignTheme(),
              home: Scaffold(
                body: KLocalization(
                  locale: 'fr',
                  child: KCombobox(
                    options: const [],
                    value: null,
                    onChanged: (_) {},
                    optionsLabel: optionsLabel,
                    noResultsLabel: noResultsLabel,
                  ),
                ),
              ),
            ),
          );
      await mount();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(
        find.text(kLocaleCatalog['fr']!['messages']['noResults']),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(kLocaleCatalog['fr']!['messages']['options']),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await mount(optionsLabel: 'Choices', noResultsLabel: 'None available');
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('None available'), findsOneWidget);
      expect(find.bySemanticsLabel('Choices'), findsOneWidget);
      semantics.dispose();
    },
  );
  test(
    'case-insensitive custom region fallback and missing messages use English',
    () {
      final data = KLocalizationData(
        locale: 'xx-AA',
        locales: {
          'XX': {
            ...kLocaleCatalog['en']!,
            'messages': {'apply': 'Proceed'},
          },
        },
      );
      expect(data.text('apply'), 'Proceed');
      expect(data.text('clear'), 'Clear');
      expect(
        KLocalizationData(
          locale: 'xx',
          locales: {
            'xx': {'name': 'Example'},
          },
        ).text('clear'),
        'Clear',
      );
    },
  );
  testWidgets(
    'duplicate abbreviated weekdays retain distinct full semantic names',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: KLocalization(
              locale: 'pt',
              child: KDatePicker(value: '2026-09-16', onChanged: (_) {}),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();
      final days = List<String>.from(kLocaleCatalog['pt']!['weekdays']);
      for (final day in days) {
        expect(find.bySemanticsLabel(day), findsOneWidget);
      }
      semantics.dispose();
    },
  );
}
