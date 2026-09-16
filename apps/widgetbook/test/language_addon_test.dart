import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/configuration_addon.dart';
import 'package:k_design_widgetbook/picker_fixtures.dart';

void main() {
  test(
    'language query defaults to English and preserves supported choices',
    () {
      final addon = KLanguageAddon();
      expect(addon.valueFromQueryGroup({}), 'en');
      for (final locale in KLanguageAddon.supportedLocales) {
        expect(addon.valueFromQueryGroup({'locale': locale}), locale);
      }
      expect(KLanguageAddon.supportedLocales.length, 14);
    },
  );

  for (final override in [false, true]) {
    testWidgets('global German reaches picker and dialog, override=$override', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Builder(
              builder: (context) => KLanguageAddon().buildUseCase(
                context,
                Scaffold(
                  body: PickerFixture(
                    locale: override ? KPickerLocale.en : null,
                  ),
                ),
                'de',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(override ? 'Choose date' : 'Datum w\u00e4hlen'),
          findsNWidgets(3),
        );
        expect(find.text('Schedule'), findsOneWidget);
        await tester.tap(
          find.byWidgetPredicate(
            (widget) => widget is FilledButton && widget.onPressed != null,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(override ? 'Apply' : '\u00dcbernehmen'),
          findsOneWidget,
        );
        expect(find.text(override ? 'Cancel' : 'Abbrechen'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    });
  }
}
