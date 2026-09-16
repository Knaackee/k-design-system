import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final density in KDensity.values) {
    for (final inputMode in KInputMode.values) {
      testWidgets('button size follows ${density.name}/${inputMode.name}', (
        tester,
      ) async {
        final configuration = KDesignConfiguration(
          density: density,
          inputMode: inputMode,
        );
        final tokens = kDesignTokens(configuration: configuration);
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(configuration: configuration),
            home: Center(
              child: KButton(label: 'Configure', onPressed: () {}),
            ),
          ),
        );
        final material = find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(Material),
        );
        expect(tester.getSize(material).height, tokens.sizeControl);
        expect(
          tester.getSize(find.byType(KButton)).height,
          greaterThanOrEqualTo(tokens.sizeHitTarget),
        );
      });
    }
  }
}
