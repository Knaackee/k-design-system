import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_widgetbook/settings_grouped_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('packages/k_design_tokens/Inter');
    font.addFont(
      File(
        '../../packages/flutter/k_design_tokens/assets/fonts/InterVariable.ttf',
      ).readAsBytes().then(ByteData.sublistView),
    );
    await font.load();
  });
  for (final width in [390.0, 1024.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('grouped settings fit $width in $brightness', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 760);
        addTearDown(tester.view.reset);
        for (final page in [
          'profile',
          'appearance',
          'language',
          'payments',
          'integrations',
          'about',
          'access',
          'assistant',
          'server',
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: kDesignTheme(brightness: brightness),
              home: SettingsGroupedFixture(
                key: ValueKey(page),
                initialPage: page,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: page);
        }
      });
    }
  }
  testWidgets('empty invitation fixture has no pagination', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const SettingsGroupedFixture(
          initialPage: 'access',
          emptyAccess: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Keine Anfragen.'), findsOneWidget);
    expect(find.text('Seite 1 von 1'), findsNothing);
    expect(find.text('0'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
