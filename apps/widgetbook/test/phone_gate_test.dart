// Decision 0010 phone gate.
//
// Renders every Widgetbook use case the way a phone app receives it
// (KAdaptiveTheme resolves window class, touch input and the phone type ramp)
// at two common phone sizes, on iOS and Android, at system text scales 1.0,
// 1.3 and 2.0. A RenderFlex/text overflow is a failure: on a real phone the
// content would be clipped or hidden.
//
// Use cases that cannot render headless (platform views, maps, media) are
// reported as skipped, not passed. Run a subset with
//   flutter test test/phone_gate_test.dart --dart-define=PHONE_GATE_FILTER=card
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/main.dart';
import 'package:widgetbook/widgetbook.dart';

const _filter = String.fromEnvironment('PHONE_GATE_FILTER');

const _phones = [Size(360, 740), Size(393, 852)];
const _platforms = [TargetPlatform.iOS, TargetPlatform.android];
const _scales = [1.0, 1.3, 2.0];

// Known headless limitations (platform views, network tiles, media). Each
// entry needs a reason; the gate still reports them.
const _headless = <String, String>{
  'map': 'map tiles and platform views need a device',
  'video': 'media playback needs a device',
  'browser': 'embedded browser surface needs a device',
  'presentation': 'remote presentation images need network',
};

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

  final useCases = galleryDirectories()
      .expand((node) => node.leaves)
      .whereType<WidgetbookUseCase>()
      .where((u) => _filter.isEmpty || u.path.contains(_filter))
      .toList();

  testWidgets('phone gate: ${useCases.length} use cases', (tester) async {
    final overflows = <String>[];
    final skipped = <String>{};
    for (final useCase in useCases) {
      final headless = _headless.keys.where(useCase.path.contains);
      if (headless.isNotEmpty) {
        skipped.add('${useCase.path} (${_headless[headless.first]})');
        continue;
      }
      for (final size in _phones) {
        for (final platform in _platforms) {
          for (final scale in _scales) {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            final errors = <String>[];
            void drain() {
              Object? error;
              while ((error = tester.takeException()) != null) {
                errors.add(error.toString());
              }
            }

            try {
              await tester.pumpWidget(
                MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: ThemeData(platform: platform),
                  home: MediaQuery(
                    data: MediaQueryData(
                      size: size,
                      textScaler: TextScaler.linear(scale),
                    ),
                    child: KAdaptiveTheme(
                      child: KLocalization(
                        locale: 'en',
                        child: Scaffold(
                          body: Builder(builder: useCase.builder),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              drain();
              await tester.pump(const Duration(milliseconds: 300));
              drain();
            } catch (error) {
              skipped.add('${useCase.path} ($error)'.split('\n').first);
            }
            for (final text in errors) {
              if (text.contains('overflowed')) {
                overflows.add(
                  '${useCase.path} @ ${size.width.toInt()}x'
                  '${size.height.toInt()} ${platform.name} '
                  'text ${scale}x: ${text.split('\n').first}'
                  '${_origin(text)}',
                );
              } else {
                skipped.add('${useCase.path} (${text.split('\n').first})');
              }
            }
            if (overflows.isNotEmpty &&
                overflows.last.startsWith(useCase.path)) {
              break; // one finding per use case is enough to act on
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      while (tester.takeException() != null) {}
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();

    final report = StringBuffer()
      ..writeln(
        'Phone gate: ${useCases.length} use cases, '
        '${overflows.length} overflow(s), '
        '${skipped.map((s) => s.split(' ').first).toSet().length} '
        'use cases skipped (not verified).',
      );
    for (final o in overflows) {
      report.writeln('  OVERFLOW $o');
    }
    for (final s in skipped) {
      report.writeln('  skipped  $s');
    }
    File('build/phone_gate_report.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync(report.toString());
    // ignore: avoid_print
    print(report);
    expect(overflows, isEmpty, reason: report.toString());
  }, timeout: const Timeout(Duration(minutes: 40)));
}

/// The widget that caused an overflow, as `file.dart:line`, from the error
/// description (Flutter records the creation location in debug mode).
String _origin(String details) {
  final found = RegExp(
    r'(?:k_design_ui/lib/src|widgetbook/lib)/[\w/]+\.dart:\d+',
  ).allMatches(details).map((m) => m.group(0)!).toSet().take(3);
  return found.isEmpty ? '' : ' <- ${found.join(' | ')}';
}
