import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/deployment_overhaul_fixture.dart';
import 'package:k_design_widgetbook/onzeit_overhaul_day.dart';
import 'package:k_design_widgetbook/onzeit_overhaul_fixture.dart';
import 'package:k_design_widgetbook/settings_grouped_fixture.dart';
import 'package:k_design_widgetbook/settings_overhaul_dialogs.dart';

void main() {
  for (final width in [320.0, 1280.0]) {
    testWidgets('calendar shows the options for width $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: const OnzeitOverhaulFixture(initialPage: 'calendar'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Liste'), findsOneWidget);
      expect(find.text('Monat'), findsOneWidget);
      expect(find.text('Woche'), width > 1000 ? findsOneWidget : findsNothing);
      expect(find.text('3 Tage'), width < 1000 ? findsOneWidget : findsNothing);
      if (width > 1000) {
        await tester.tap(find.text('Liste'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Anstehend'), findsOneWidget);
      expect(find.text('Jonas Becker'), findsWidgets);
      expect(find.byType(KAvatar), findsWidgets);
      expect(find.text('33,54\u00a0€'), findsOneWidget);
      expect(find.byType(KBadge), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 1280.0]) {
    testWidgets(
      'month day agenda tracks selection and returning months at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 850);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: const OnzeitOverhaulFixture(initialPage: 'calendar'),
          ),
        );
        await tester.tap(find.text('Monat'));
        await tester.pumpAndSettle();

        Finder day(String label) => find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == label,
        );
        bool? selected(String label) =>
            tester.widget<Semantics>(day(label)).properties.selected;
        Future<void> openDay(String label) async {
          final cell = day(label);
          await tester.ensureVisible(cell);
          final position = tester.getTopLeft(cell) + const Offset(12, 8);
          await tester.tapAt(position);
          await tester.pumpAndSettle();
        }

        Future<void> press(String label) async {
          final control = label == 'Heute'
              ? find.widgetWithText(KButton, label).last
              : find.byWidgetPredicate(
                  (widget) => widget is KIconButton && widget.label == label,
                );
          await tester.ensureVisible(control);
          await tester.tap(control);
          await tester.pumpAndSettle();
        }

        expect(selected('3.11.2026, 4'), isTrue);
        if (width > 700) expect(find.text('+2'), findsOneWidget);
        expect(find.text('33,54\u00a0€'), findsOneWidget);
        await openDay('4.11.2026, 1');
        expect(selected('4.11.2026, 1'), isTrue);
        expect(find.text('35,40\u00a0€'), findsOneWidget);
        expect(find.text('33,54\u00a0€'), findsNothing);

        await openDay('7.11.2026, 0');
        expect(selected('7.11.2026, 0'), isTrue);
        expect(find.text('Keine Termine.'), findsOneWidget);
        await press('Nächster Zeitraum');
        expect(find.text('Dezember 2026'), findsOneWidget);
        expect(selected('1.12.2026, 0'), isTrue);
        await press('Vorheriger Zeitraum');
        expect(selected('7.11.2026, 0'), isTrue);
        expect(find.text('Keine Termine.'), findsOneWidget);
        await press('Heute');
        expect(selected('3.11.2026, 4'), isTrue);
        expect(find.text('33,54\u00a0€'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('delete-account sheet requires explicit confirmation', (
    tester,
  ) async {
    reviewPageSheetPreference.value = true;
    addTearDown(() => reviewPageSheetPreference.value = false);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 600);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const SettingsGroupedFixture(
          overhaul: true,
          initialDialog: 'Konto löschen?',
        ),
      ),
    );
    await tester.pumpAndSettle();
    final action = find.descendant(
      of: find.byType(KAdaptiveDialog),
      matching: find.widgetWithText(KButton, 'Konto löschen'),
    );
    expect(tester.widget<KButton>(action).onPressed, isNull);
    await tester.enterText(find.byType(EditableText), 'LÖSCHEN');
    await tester.pumpAndSettle();
    expect(tester.widget<KButton>(action).onPressed, isNotNull);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('Bestätigung in der Vorschau geprüft.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('page-sheet comparison opens the shared day editor', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 740);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const OverhaulPageSheetFixture(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tag anpassen'));
    await tester.pumpAndSettle();
    expect(find.byType(KPageSheet), findsOneWidget);
    expect(find.text('Freier Tag'), findsWidgets);
    expect(find.text('Übernehmen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deployment private appointment validates title and saves', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const DeploymentOverhaulFixture(initialSheet: 'private'),
      ),
    );
    await tester.pumpAndSettle();
    final action = find.widgetWithText(KButton, 'Speichern');
    expect(tester.widget<KButton>(action).onPressed, isNull);
    await tester.enterText(find.byType(EditableText).first, 'Werkstatt');
    await tester.pumpAndSettle();
    expect(tester.widget<KButton>(action).onPressed, isNotNull);
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.text('In dieser Vorschau übernommen.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
