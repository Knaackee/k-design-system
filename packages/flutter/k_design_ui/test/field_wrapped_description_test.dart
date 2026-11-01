import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final scale in [1.0, 1.5]) {
    for (final invalid in [false, true]) {
      testWidgets(
        'wrapped field description has readable leading $scale $invalid',
        (tester) async {
          const description =
              'Suggestion · Availability will be checked when publishing your booking page.';
          final theme = kDesignTheme();
          final tokens = theme.extension<KDesignTokens>()!;
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Center(
                    child: SizedBox(
                      width: 220,
                      child: KField(
                        label: 'Address',
                        helperText: invalid ? null : description,
                        errorText: invalid ? description : null,
                        child: const KInput(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          final helper = tester.widget<Text>(find.text(description));
          expect(helper.style!.height, tokens.fontRelaxedHeight);
          final label = tester.widget<Text>(find.text('Address'));
          final fontSize = label.style!.fontSize! * scale;
          expect(label.style!.height, fontSize.round() / fontSize);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
