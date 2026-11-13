import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Match the phone gate's real-glyph substitute for unavailable platform fonts.
    for (final family in [
      'packages/k_design_tokens/Inter',
      'Roboto',
      'CupertinoSystemText',
    ]) {
      final loader = FontLoader(family)
        ..addFont(
          File(
            '../k_design_tokens/assets/fonts/InterVariable.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        );
      await loader.load();
    }
  });
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final width in [360.0, 393.0]) {
      for (final scale in [1.0, 1.3, 2.0, 3.0]) {
        for (final value in ['2 : 1', '1:0', '20:45']) {
          testWidgets('comparison $value wraps at $width / $scale / $platform', (
            tester,
          ) async {
            final left = value == '20:45'
                ? 'Serbien'
                : 'Borussia Mönchengladbach';
            final right = value == '20:45'
                ? 'Deutschland'
                : 'Eintracht Frankfurt';
            const detail =
                'Endstand nach Verlängerung · Borussia gewinnt das Heimspiel und zieht in die nächste Runde ein.';
            await tester.pumpWidget(
              MaterialApp(
                theme: kDesignTheme().copyWith(platform: platform),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 852),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: KAdaptiveTheme(
                    child: Scaffold(
                      body: SingleChildScrollView(
                        child: SizedBox(
                          width: width,
                          child: KPresentationComparison(
                            label: 'Bundesliga · Beendet',
                            left: KPresentationParty(
                              name: left,
                              detail: 'Heim',
                            ),
                            right: KPresentationParty(
                              name: right,
                              detail: 'Gast',
                            ),
                            value: value,
                            detail: detail,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            expect(tester.takeException(), isNull);
            final summary = tester.getRect(find.text(detail));
            final leftName = tester.getRect(find.text(left));
            final rightName = tester.getRect(find.text(right));
            final score = tester.getRect(find.text(value));
            if (value == '20:45' && scale == 1) {
              expect(rightName.height, leftName.height);
            }
            expect(score.center.dx, closeTo(width / 2, 0.01));
            expect(summary.top, greaterThan(leftName.bottom));
            expect(summary.top, greaterThan(rightName.bottom));
            expect(summary.top, greaterThan(score.bottom));
            expect(summary.width, greaterThan(score.width));
            expect(leftName.right, lessThanOrEqualTo(score.left));
            expect(score.right, lessThanOrEqualTo(rightName.left));
            expect(summary.right, lessThanOrEqualTo(width));
          });
        }
      }
    }
  }
}
