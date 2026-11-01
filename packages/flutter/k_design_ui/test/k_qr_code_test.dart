import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('all variants fit a narrow canvas and expose their label', (
    tester,
  ) async {
    for (final variant in KQrCodeVariant.values) {
      for (final shape in KQrCodeModuleShape.values) {
        for (final eyes in KQrCodeEyeShape.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Center(
                child: SizedBox(
                  width: 200,
                  child: KQrCode(
                    data: 'https://example.com/book/alex',
                    label: 'Booking QR',
                    variant: variant,
                    moduleShape: shape,
                    eyeShape: eyes,
                    title: 'Alex',
                    caption: 'Book now',
                  ),
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          expect(find.bySemanticsLabel('Booking QR'), findsOneWidget);
          if (variant == KQrCodeVariant.card) {
            expect(find.text('Book now'), findsOneWidget);
          }
        }
      }
    }
  });
}
