// Decision 0010 geometry parity, Flutter half.
//
// Measures every entry of the shared GeometryParityFixture under the same
// configurations the Web half (tooling/geometry-parity.mjs) uses and writes
// build/geometry-parity.flutter.json. The Web half measures the Storybook
// story Review/GeometryParity and fails on differences.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/geometry_parity_fixture.dart';

/// Must match `configurations` in tooling/geometry-parity.mjs.
const _configurations = <String, (Size, TargetPlatform)>{
  'phone': (Size(393, 852), TargetPlatform.iOS),
  'desktop': (Size(1280, 800), TargetPlatform.macOS),
};
const _scales = [1.0, 1.3, 2.0];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('packages/k_design_tokens/Inter')
      ..addFont(
        File(
          '../../packages/flutter/k_design_tokens/assets/fonts/InterVariable.ttf',
        ).readAsBytes().then(ByteData.sublistView),
      );
    await loader.load();
  });

  testWidgets('geometry parity: measure Flutter reference', (tester) async {
    final result = <String, Map<String, Map<String, double>>>{};
    for (final MapEntry(key: name, value: (size, platform))
        in _configurations.entries) {
      for (final scale in _scales) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(platform: platform),
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
              ),
              child: const KAdaptiveTheme(
                child: KLocalization(
                  locale: 'en',
                  child: Scaffold(
                    body: Align(
                      alignment: Alignment.topLeft,
                      child: GeometryParityFixture(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        final entries = <String, Map<String, double>>{};
        for (final id in kGeometryParityEntries.keys) {
          final box = tester.getSize(
            find.byKey(GeometryParityFixture.keyFor(id)),
          );
          entries[id] = {'w': box.width, 'h': box.height};
        }
        result['$name@$scale'] = entries;
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    File('build/geometry-parity.flutter.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent(
          '  ',
        ).convert({'axes': kGeometryParityEntries, 'measurements': result}),
      );
  });
}
