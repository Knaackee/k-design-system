import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final width in [360.0, 840.0]) {
    testWidgets('spinner stays circular in a stretched $width page', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [KSpinner(label: 'Refreshing', size: 24)],
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(CircularProgressIndicator)),
        const Size(24, 24),
      );
      expect(find.bySemanticsLabel('Refreshing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
