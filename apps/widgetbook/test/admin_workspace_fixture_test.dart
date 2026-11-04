import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/admin_workspace_fixture.dart';
import 'package:k_design_widgetbook/admin_workspace_parts.dart';

Widget host(String page, {bool dark = false, double scale = 1}) => MaterialApp(
  theme: ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    extensions: [dark ? KDesignTokens.orbitDark : KDesignTokens.orbitLight],
  ),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: KLocalization(
        locale: 'de',
        child: Scaffold(body: AdminWorkspaceFixture(initialPage: page)),
      ),
    ),
  ),
);

void main() {
  testWidgets('assistant save label is centered in its stretched button', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host('assistant'));
    await tester.pumpAndSettle();
    final button = find.byWidgetPredicate(
      (w) => w is KButton && w.label == 'Speichern',
    );
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('Speichern')).dx,
      closeTo(tester.getCenter(button).dx, .01),
    );
    expect(tester.getSize(button).width, greaterThan(300));
    expect(tester.takeException(), isNull);
  });
  testWidgets('desktop panes start at top and owner avatar stays circular', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host('partners'));
    await tester.pumpAndSettle();
    final heading = find.byWidgetPredicate(
      (w) =>
          w is KText &&
          w.data == 'Partnerschaften' &&
          w.variant == KTextVariant.heading2,
    );
    expect(tester.getTopLeft(heading).dy, lessThanOrEqualTo(64));
    final firstGroup = find.byType(AwGroup).first;
    expect(tester.getTopLeft(firstGroup).dy, lessThanOrEqualTo(32));
    final owner = find.byWidgetPredicate(
      (w) => w is KAvatar && w.alt == 'Denis Knaack',
    );
    final size = tester.getSize(owner);
    expect(size.width, closeTo(size.height, .01));
    expect(tester.takeException(), isNull);
  });
  testWidgets('KPI labels and values have full non-overlapping line boxes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host('partners'));
    await tester.pumpAndSettle();
    for (final pair in [
      ('Aktive Ambassadors', '2'),
      ('Vermittelte Anmeldungen', '83'),
    ]) {
      final label = find.text(pair.$1);
      final value = find.text(pair.$2);
      final labelRect = tester.getRect(label);
      final valueRect = tester.getRect(value);
      final text = tester.widget<Text>(value);
      expect(
        text.style!.height! * text.style!.fontSize!,
        greaterThanOrEqualTo(text.style!.fontSize!),
      );
      expect(valueRect.height, greaterThanOrEqualTo(22));
      expect(labelRect.bottom, lessThanOrEqualTo(valueRect.top));
    }
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 390.0, 1440.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('KPI row heights match at $width and text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(host('partners', scale: scale));
        await tester.pumpAndSettle();
        final cards = find.descendant(
          of: find.byType(AwKpis),
          matching: find.byType(AwCard),
        );
        expect(cards, findsNWidgets(2));
        final first = tester.getRect(cards.at(0));
        final second = tester.getRect(cards.at(1));
        expect(first.top, second.top);
        expect(first.height, closeTo(second.height, .01));
        expect(
          tester.getTopLeft(find.text('2')).dy,
          closeTo(tester.getTopLeft(find.text('83')).dy, .01),
        );
        if (width == 320 && scale == 1.5) {
          // The actual long label wraps; equal sizing is not just trend padding.
          expect(
            tester.getSize(find.text('Vermittelte Anmeldungen')).height,
            greaterThan(24),
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('phone pages retain actions with larger text', (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final page in [
      'overview',
      'customers',
      'access',
      'growth',
      'subscriptions',
      'waitlist',
      'invitations',
      'applications',
      'partners',
      'operations',
      'assistant',
      'audit',
    ]) {
      await tester.pumpWidget(host(page, scale: 1.5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: page);
      await tester.pumpWidget(const SizedBox());
    }
  });
  for (final width in [320.0, 390.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('admin pages fit width $width dark $dark', (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final page in [
          'overview',
          'navigation',
          'customers',
          'access',
          'growth',
          'subscriptions',
          'waitlist',
          'invitations',
          'applications',
          'partners',
          'operations',
          'assistant',
          'audit',
        ]) {
          await tester.pumpWidget(host(page, dark: dark));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: page);
          await tester.pumpWidget(const SizedBox());
        }
      });
    }
  }
  for (final page in ['partners', 'applications', 'customers', 'invitations']) {
    testWidgets(
      '$page badge is inside full clickable row and opens compact detail',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(host(page, dark: true));
        await tester.pumpAndSettle();
        final badge = find.byType(AwBadge).first;
        await tester.ensureVisible(badge);
        await tester.tap(badge);
        await tester.pumpAndSettle();
        expect(find.byType(KAdaptiveDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (page == 'partners') {
          final link = find
              .byWidgetPredicate(
                (w) => w is KText && w.data == 'https://example.invalid/sophie',
              )
              .last;
          final widget = tester.widget<KText>(link);
          expect(widget.maxLines, 1);
          expect(widget.overflow, TextOverflow.ellipsis);
          final rich = find.descendant(
            of: link,
            matching: find.byType(RichText),
          );
          expect(
            tester.renderObject<RenderParagraph>(rich).size.height,
            lessThan(40),
          );
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(KAdaptiveDialog), findsNothing);
      },
    );
  }
  testWidgets('customer empty search resets and restores entries', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host('customers'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no-such-fixture');
    await tester.pumpAndSettle();
    expect(find.text('Keine Einträge'), findsOneWidget);
    await tester.tap(find.text('Zurücksetzen'));
    await tester.pumpAndSettle();
    expect(find.text('Mara Krüger · Mara Hair Mobile'), findsOneWidget);
  });
}
