import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/pickers/picker_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final rootFont = File(
      'packages/flutter/k_design_tokens/assets/fonts/InterVariable.ttf',
    );
    final font = rootFont.existsSync()
        ? rootFont
        : File('../k_design_tokens/assets/fonts/InterVariable.ttf');
    final loader = FontLoader('packages/k_design_tokens/Inter')
      ..addFont(font.readAsBytes().then(ByteData.sublistView));
    await loader.load();
  });
  testWidgets(
    'wrapped footer spacer fills its first line with German large text',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(
            configuration: const KDesignConfiguration(
              density: KDensity.spacious,
              inputMode: KInputMode.touch,
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: KDatePicker(
              value: '2026-09-16',
              onChanged: (_) {},
              locale: KPickerLocale.de,
              clearable: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      final clear = tester.getRect(find.widgetWithText(KButton, 'Leeren'));
      final cancel = tester.getRect(find.widgetWithText(KButton, 'Abbrechen'));
      final apply = tester.getRect(find.widgetWithText(KButton, 'Übernehmen'));
      final panel = tester.getRect(find.byType(PickerPanel));
      expect(clear.top, cancel.top);
      expect(cancel.right, closeTo(panel.right - 9, .1));
      expect(apply.left, closeTo(clear.left, .1));
      expect(apply.top, greaterThan(clear.bottom));
      expect(tester.takeException(), isNull);
    },
  );
}
