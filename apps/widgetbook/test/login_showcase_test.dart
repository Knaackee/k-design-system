import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/login_showcase.dart';

void main() {
  for (final width in [375.0, 1024.0]) {
    testWidgets('login validates locally and masks password at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: const Scaffold(body: LoginShowcase()),
        ),
      );
      final submit = find.byType(KButton);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Bitte Benutzername eingeben.'), findsOneWidget);
      expect(find.text('Mindestens 12 Zeichen eingeben.'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'demo');
      await tester.enterText(
        find.byType(TextField).last,
        'Synthetic-password-123',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField).last).obscureText,
        isTrue,
      );
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Demo: Eingaben geprüft. Es wurden keine Zugangsdaten gesendet.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byType(KLink));
      await tester.tap(find.byType(KLink));
      await tester.pumpAndSettle();
      expect(
        find.text('Demo: Hier würde die Passwort-Wiederherstellung geöffnet.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
