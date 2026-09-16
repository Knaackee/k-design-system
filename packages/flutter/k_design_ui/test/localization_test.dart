import 'package:k_design_ui/src/actions/action_control.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/generated/locales.dart';

void main() {
  Finder trigger(String label) => find.byWidgetPredicate(
    (widget) => widget is KActionControl && widget.label == label,
  );
  Future<void> mount(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: kDesignTheme(),
      home: Scaffold(body: child),
    ),
  );
  test(
    'all bundled packs resolve regions and preserve independent formats',
    () {
      expect(kLocaleCatalog.length, 14);
      for (final code in kLocaleCatalog.keys) {
        final data = KLocalizationData(locale: '$code-XX');
        expect(data.pack('$code-XX'), kLocaleCatalog[code]);
        expect(data.calendar()['months'], hasLength(12));
        expect(data.calendar()['weekdays'], hasLength(7));
        expect(data.dateFormat, KDateFormat.iso);
        expect(data.timeFormat, KTimeFormat.h24);
        expect(data.timeZone, 'UTC');
      }
      expect(const KLocalizationData(locale: 'unknown').text('apply'), 'Apply');
      expect(
        const KLocalizationData(locale: 'DE_de').text('apply'),
        'Übernehmen',
      );
    },
  );
  testWidgets(
    'provider inherits formats and zone with independent component overrides',
    (tester) async {
      await mount(
        tester,
        KLocalization(
          locale: 'de-DE',
          calendarLocale: 'fr',
          dateFormat: KDateFormat.dayMonthYear,
          timeFormat: KTimeFormat.h12,
          timeZone: 'Europe/Berlin',
          child: Column(
            children: [
              KDateTimePicker(
                value: '2026-09-16T10:30:00.000Z',
                onChanged: (_) {},
              ),
              KDateTimePicker(
                value: '2026-09-16T10:30:00.000Z',
                onChanged: (_) {},
                dateFormat: KDateFormat.iso,
                timeZone: 'UTC',
                locale: KPickerLocale.en,
              ),
            ],
          ),
        ),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '16.09.2026 12:30 PM',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        '2026-09-16 10:30 AM',
      );
      await tester.tap(trigger('Datum und Uhrzeit wählen'));
      await tester.pumpAndSettle();
      expect(find.text('Übernehmen'), findsOneWidget);
      expect(find.text('septembre'), findsOneWidget);
      expect(find.text('Europe/Berlin'), findsNothing);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      await tester.tap(trigger('Choose date and time'));
      await tester.pumpAndSettle();
      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('September'), findsOneWidget);
    },
  );
  testWidgets(
    'live locale change updates defaults but preserves consumer copy',
    (tester) async {
      var locale = 'en';
      late StateSetter update;
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return KLocalization(
              locale: locale,
              child: Column(
                children: [
                  KDatePicker(
                    label: 'My appointment',
                    value: '2026-09-16',
                    onChanged: (_) {},
                  ),
                  KSelect(
                    label: 'My status',
                    options: const [],
                    value: null,
                    onChanged: (_) {},
                  ),
                  KFilterBar(
                    label: 'My filters',
                    onReset: () {},
                    children: const [],
                  ),
                ],
              ),
            );
          },
        ),
      );
      expect(trigger('Choose date'), findsOneWidget);
      update(() => locale = 'de');
      await tester.pumpAndSettle();
      expect(trigger('Datum wählen'), findsOneWidget);
      expect(find.text('Alle zurücksetzen'), findsOneWidget);
      expect(
        find.text(kLocaleCatalog['de']!['messages']['choose']),
        findsOneWidget,
      );
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('My appointment'), findsOneWidget);
      expect(find.bySemanticsLabel('My status'), findsOneWidget);
      semantics.dispose();
    },
  );
  testWidgets(
    'custom packs, message overrides and picker overrides reach dialogs',
    (tester) async {
      final custom = {
        ...kLocaleCatalog['en']!,
        'messages': {
          ...Map<String, String>.from(kLocaleCatalog['en']!['messages']),
          'chooseDate': 'Custom date',
          'apply': 'Custom apply',
        },
        'months': List.generate(12, (i) => 'Month ${i + 1}'),
      };
      await mount(
        tester,
        KLocalization(
          locale: 'xx-YY',
          locales: {'xx-YY': custom},
          messages: const {'cancel': 'Back'},
          child: KDatePicker(
            value: '2026-09-16',
            onChanged: (_) {},
            labels: const KPickerLabels(apply: 'Confirm'),
          ),
        ),
      );
      await tester.tap(trigger('Custom date'));
      await tester.pumpAndSettle();
      expect(find.text('Month 9'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Custom apply'), findsNothing);
    },
  );
  testWidgets(
    'ambient Flutter locale is fallback and nested providers inherit each setting',
    (tester) async {
      late KLocalizationData resolved;
      await mount(
        tester,
        Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: const Locale('fr', 'CA'),
            child: KLocalization(
              timeZone: 'Europe/Paris',
              dateFormat: KDateFormat.dayMonthYear,
              child: KLocalization(
                timeFormat: KTimeFormat.h12,
                child: Builder(
                  builder: (context) {
                    resolved = KLocalization.of(context);
                    return const SizedBox();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        resolved.text('apply'),
        kLocaleCatalog['fr']!['messages']['apply'],
      );
      expect(resolved.timeZone, 'Europe/Paris');
      expect(resolved.dateFormat, KDateFormat.dayMonthYear);
      expect(resolved.timeFormat, KTimeFormat.h12);
    },
  );
  testWidgets('locale changes preserve an uncommitted manual picker draft', (
    tester,
  ) async {
    var locale = 'en';
    late StateSetter update;
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return KLocalization(
            locale: locale,
            child: KDatePicker(
              value: '2026-09-16',
              allowTextInput: true,
              onChanged: (_) {},
            ),
          );
        },
      ),
    );
    await tester.enterText(find.byType(TextField), '2026-02-');
    update(() => locale = 'de');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '2026-02-',
    );
    expect(trigger('Datum wählen'), findsOneWidget);
  });
  testWidgets('open dialog language updates without discarding date draft', (
    tester,
  ) async {
    var locale = 'en';
    late StateSetter update;
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return KLocalization(
            locale: locale,
            messages: locale == 'en' ? const {'apply': 'Proceed'} : const {},
            child: KDatePicker(
              value: '2026-09-16',
              allowTextInput: true,
              onChanged: (_) {},
            ),
          );
        },
      ),
    );
    await tester.tap(trigger('Choose date'));
    await tester.pumpAndSettle();
    expect(find.text('Proceed'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '2026-10-20');
    update(() => locale = 'de');
    await tester.pumpAndSettle();
    expect(find.text('Übernehmen'), findsOneWidget);
    expect(find.text('Oktober'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      '2026-10-20',
    );
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
  });
}
