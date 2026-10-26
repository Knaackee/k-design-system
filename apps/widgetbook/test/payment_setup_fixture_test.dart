import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/payment_setup_fixture.dart';

Widget frame(
  Widget child, {
  Brightness brightness = Brightness.light,
  double scale = 1,
  bool reduced = false,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: kDesignTheme(brightness: brightness),
  home: MediaQuery(
    data: MediaQueryData(
      textScaler: TextScaler.linear(scale),
      disableAnimations: reduced,
    ),
    child: Scaffold(body: child),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('packages/k_design_tokens/Inter');
    loader.addFont(
      File(
        '../../packages/flutter/k_design_tokens/assets/fonts/InterVariable.ttf',
      ).readAsBytes().then(ByteData.sublistView),
    );
    await loader.load();
  });
  testWidgets('captures payment setup responsive render evidence', (
    tester,
  ) async {
    if (!const bool.fromEnvironment('PAYMENT_SETUP_EVIDENCE')) return;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory = Directory('build/payment-setup-evidence')
      ..createSync(recursive: true);
    for (final width in [375.0, 768.0, 1280.0]) {
      for (final brightness in Brightness.values) {
        tester.view.physicalSize = Size(width, 1400);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: frame(
              const PaymentSetupFixture(),
              reduced: true,
              brightness: brightness,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '${directory.path}/${width.toInt()}-${brightness.name}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
  });
  testWidgets(
    'all six fixtures render at mobile tablet desktop widths in both themes',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [320.0, 768.0, 1280.0]) {
        tester.view.physicalSize = Size(width, 1000);
        for (final brightness in Brightness.values) {
          for (final state in KPaymentSetupState.values) {
            await tester.pumpWidget(
              frame(
                PaymentSetupFixture(key: UniqueKey(), state: state),
                brightness: brightness,
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byType(KPaymentSetup), findsOneWidget);
            expect(
              tester.takeException(),
              isNull,
              reason: '$state $width $brightness',
            );
          }
          await tester.pumpWidget(
            frame(
              PaymentSetupFixture(key: UniqueKey(), longContent: true),
              brightness: brightness,
              scale: 2,
              reduced: true,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'long content $width $brightness',
          );
        }
      }
    },
  );
  testWidgets('setup and refresh simulate consumer state, disclosure expands', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      frame(const PaymentSetupFixture(state: KPaymentSetupState.connected)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Einrichtung starten'));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
    expect(find.text('Es fehlen noch ein paar Angaben'), findsOneWidget);
    await tester.tap(find.text('Einrichtung fortsetzen'));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
    expect(find.text('Deine Angaben werden geprüft'), findsOneWidget);
    await tester.tap(find.text('Status aktualisieren'));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pumpAndSettle();
    expect(find.text('Dein Zahlungskonto ist bereit'), findsOneWidget);
    await tester.tap(find.text('Testmodus: So funktioniert die Prüfung'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Hier fließt kein echtes Geld.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Zahlungen ansehen'));
    await tester.pumpAndSettle();
    expect(
      find.text('In der Anwendung öffnet sich jetzt die Zahlungsübersicht.'),
      findsOneWidget,
    );
  });
  testWidgets(
    'steps switch from vertical to horizontal at content breakpoint',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [320.0, 1280.0]) {
        tester.view.physicalSize = Size(width, 1200);
        await tester.pumpWidget(frame(PaymentSetupFixture(key: UniqueKey())));
        await tester.pumpAndSettle();
        final connection = tester.getTopLeft(
          find.byKey(const ValueKey('connection')),
        );
        final setup = tester.getTopLeft(find.byKey(const ValueKey('setup')));
        if (width == 320) {
          expect(setup.dy, greaterThan(connection.dy));
          expect(setup.dx, connection.dx);
        } else {
          expect(setup.dx, greaterThan(connection.dx));
          expect(setup.dy, connection.dy);
        }
      }
    },
  );
}
