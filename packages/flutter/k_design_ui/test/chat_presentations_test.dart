import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
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
        await tester.tap(find.text('Open 0'));
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
