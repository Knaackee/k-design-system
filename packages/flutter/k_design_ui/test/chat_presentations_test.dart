import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final configuration in [
    KDesignConfiguration.desktopApp,
    KDesignConfiguration.mobileApp,
  ]) {
    for (final scale in [1.0, 1.15, 2.0]) {
      testWidgets(
        'compact result keeps content and touch action at 360 / ${configuration.typeScale.name} / $scale',
        (tester) async {
          var opens = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: kDesignTheme(configuration: configuration),
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: SizedBox(
                    width: 360,
                    child: KPresentationCard(
                      title: 'ONZEIT-BACKEND-7',
                      description: '<anonymous> – 2 Events, neu, vor ~3 Std.',
                      action: KPresentationAction(
                        label: 'Open issue',
                        onPressed: () => opens++,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          final tokens = kDesignTheme(
            configuration: configuration,
          ).extension<KDesignTokens>()!;
          if (scale <= 1.15) {
            expect(
              tester.getSize(find.byType(KPresentationCard)).height,
              lessThanOrEqualTo(
                (tokens.fontBodySmallLineHeight * scale).ceilToDouble() * 4 +
                    tokens.spaceControlGap * 2.5 +
                    tokens.borderWidthDefault * 2,
              ),
            );
          }
          final title = tester.widget<KText>(
            find.widgetWithText(KText, 'ONZEIT-BACKEND-7'),
          );
          expect(title.variant, KTextVariant.bodySmall);
          final action = find.byTooltip('Open issue');
          expect(
            tester.getSize(action).height,
            greaterThanOrEqualTo(tokens.sizeHitTarget),
          );
          await tester.tap(action);
          expect(opens, 1);
          expect(
            find.text('<anonymous> – 2 Events, neu, vor ~3 Std.'),
            findsOneWidget,
          );
        },
      );
    }
  }
  for (final width in [390.0, 503.0]) {
    for (final variant in KPresentationCardVariant.values) {
      testWidgets('action carousel ${variant.name} at $width', (tester) async {
        var activations = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Scaffold(
              body: SizedBox(
                width: width,
                child: KPresentationCollection(
                  label: 'Cards',
                  children: [
                    for (var index = 0; index < 3; index++)
                      KPresentationCard(
                        title: 'Card $index',
                        description: 'Description of the presentation card.',
                        variant: variant,
                        action: KPresentationAction(
                          label: 'Open $index',
                          onPressed: () => activations++,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (variant == KPresentationCardVariant.cover) {
          expect(
            tester.getSize(find.byType(KPresentationCard).first).height,
            greaterThanOrEqualTo(280),
          );
        }
        await tester.tap(
          variant == KPresentationCardVariant.cover
              ? find.text('Open 0')
              : find.byTooltip('Open 0'),
        );
        await tester.pumpAndSettle();
        expect(activations, 1);

        final track = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        final initialOffset = track.position.pixels;
        await tester.tap(find.byTooltip('Weitere Karten'));
        await tester.pumpAndSettle();
        expect(track.position.pixels, greaterThan(initialOffset));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Vorherige Karten'));
        await tester.pumpAndSettle();
        expect(track.position.pixels, closeTo(initialOffset, 1));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
