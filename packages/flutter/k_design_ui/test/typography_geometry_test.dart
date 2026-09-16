import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('packages/k_design_tokens/Inter');
    loader.addFont(
      File(
        '../k_design_tokens/assets/fonts/InterVariable.ttf',
      ).readAsBytes().then(ByteData.sublistView),
    );
    await loader.load();
  });
  testWidgets('scaled Inter geometry matches measured Web line boxes', (
    tester,
  ) async {
    // Chromium measurements from the same bundled Inter family and token settings.
    for (final (scale, headingWidth, labelWidth, buttonWidth) in [
      (1.0, 130.875, 46.90625, 87.46875),
      (2.0, 250.953125, 88.984375, 143.609375),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Center(
              child: KStack(
                children: [
                  const KText(
                    'Project settings',
                    variant: KTextVariant.heading4,
                  ),
                  const KText('Canvas', variant: KTextVariant.label),
                  KButton(label: 'Configure', onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final heading = tester.getSize(find.text('Project settings'));
      final label = tester.getSize(find.text('Canvas'));
      expect(heading.width, closeTo(headingWidth, .5));
      expect(heading.height, closeTo(24 * scale, .5));
      expect(label.width, closeTo(labelWidth, .5));
      expect(label.height, closeTo(18 * scale, .5));
      final button = tester.getSize(find.byType(KButton));
      expect(button.width, closeTo(buttonWidth, .5));
      expect(button.height, closeTo(36, .5));
      expect(tester.takeException(), isNull);
    }
  });
}
