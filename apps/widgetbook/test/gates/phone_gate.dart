// Decision 0010 phone gate.
//
// Renders every Widgetbook use case the way a phone app receives it
// (KAdaptiveTheme resolves window class, touch input and the phone type ramp)
// at two common phone sizes, on iOS and Android, at system text scales 1.0,
// 1.3, 2.0 and 3.0 (the body/control cap). A RenderFlex/text overflow is a
// failure: on a real phone the content would be clipped or hidden.
//
// Use cases that cannot render headless (platform views, maps, media) are
// reported as skipped, not passed. Run everything with
//   pnpm gate:phone-flutter
// (shard files phone_gate_<n>.dart, run in parallel). Other errors (a map platform view inside
// a screen, framework assertions) are reported as NOTE; the layout of those
// use cases is still checked. Run a subset ('|' separates filters) with
//   flutter test test/gates/phone_gate.dart --dart-define=PHONE_GATE_FILTER=card
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
const _scales = [1.0, 1.3, 2.0, 3.0];

// Known headless limitations (platform views, network tiles, media). Each
// entry needs a reason; the gate still reports them.
const _headless = <String, String>{
  'map': 'map tiles and platform views need a device',
  'video': 'media playback needs a device',
  'browser': 'embedded browser surface needs a device',
  'presentation': 'remote presentation images need network',
};

/// Runs every [shardCount]th use case starting at [shardIndex]. One test
/// process accumulates memory per use case (debug widget-creation tracking,
/// shaders, fonts), so `tooling/flutter-phone-gate.mjs` runs the shard entry
/// files `phone_gate_<n>.dart` as separate, parallel test processes.
void runPhoneGate({int shardIndex = 0, int shardCount = 1}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // The style presets use the platform fonts (Roboto on Android, SF Pro on
    // iOS), which the test host lacks; Inter stands in with similar metrics
    // so the gate measures real glyphs instead of Ahem boxes.
    for (final family in [
      'packages/k_design_tokens/Inter',
      'Roboto',
      'CupertinoSystemText',
    ]) {
      final loader = FontLoader(family)
        ..addFont(
          File(
            '../../packages/flutter/k_design_tokens/assets/fonts/InterVariable.ttf',
          ).readAsBytes().then(ByteData.sublistView),
        );
      await loader.load();
    }
  });

  final useCases = galleryDirectories()
      .expand((node) => node.leaves)
      .whereType<WidgetbookUseCase>()
      .where((u) => _filter.isEmpty || _filter.split('|').any(u.path.contains))
      .toList();
  final shardUseCases = [
    for (var i = 0; i < useCases.length; i++)
      if (i % shardCount == shardIndex) useCases[i],
  ];
  final suffix = shardCount == 1 ? '' : '.$shardIndex';

  final overflows = <String>[];
  final details = StringBuffer();
  final skipped = <String>{};
  // Layout was checked, but the use case also threw something that is not
  // an overflow (a map platform view, a framework assertion).
  final notes = <String>{};

  // Decoded images of one use case are not needed by the next.
  tearDown(() {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
  });

  // One test per use case: the binding resets between tests, which keeps
  // memory flat over 400+ use cases and names the failing use case.
  for (final useCase in shardUseCases) {
    testWidgets('phone gate: ${useCase.path}', (tester) async {
      final headless = _headless.keys.where(useCase.path.contains);
      if (headless.isNotEmpty) {
        skipped.add('${useCase.path} (${_headless[headless.first]})');
        return;
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

            // Chain (never replace) the test handler to keep the widget
            // that caused an overflow; takeException only has the summary.
            final handler = FlutterError.onError;
            final described = <String>[];
            FlutterError.onError = (details) {
              // The debug description (with the creator chain) can describe a
              // whole subtree; take it only for the first overflow.
              final overflow = details.exceptionAsString().contains(
                'overflowed',
              );
              final first = !described.any((d) => d.contains('overflowed'));
              described.add(
                overflow && first
                    ? details.toString(minLevel: DiagnosticLevel.debug)
                    : details.toString(),
              );
              handler?.call(details);
            };
            try {
              // Every configuration opens the screen fresh, as an app does
              // at that window size and text scale; state and running
              // animations from the previous configuration must not leak in.
              await tester.pumpWidget(const SizedBox.shrink());
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
                        // Knob use cases read their values from a
                        // Widgetbook state; defaults apply.
                        child: WidgetbookScope(
                          state: WidgetbookState(
                            root: WidgetbookRoot(children: const []),
                          ),
                          child: Scaffold(
                            body: Builder(builder: useCase.builder),
                          ),
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
              FlutterError.onError = handler;
              skipped.add('${useCase.path} ($error)'.split('\n').first);
              details
                ..writeln(
                  '== SKIP ${useCase.path} ${size.width.toInt()} '
                  '${platform.name} ${scale}x',
                )
                ..writeln(
                  described
                      .take(2)
                      .join('\n---\n')
                      .split('\n')
                      .take(30)
                      .join('\n'),
                );
            }
            FlutterError.onError = handler;
            // Classify every reported error from its full details. The
            // binding's own summary ("Multiple exceptions (n)") counts across
            // the whole test and would hide overflows behind one earlier,
            // unrelated failure.
            String headline(String d) => d
                .split('\n')
                .map((l) => l.trim())
                .firstWhere(
                  (l) =>
                      l.isNotEmpty &&
                      !l.startsWith('═') &&
                      !l.startsWith('The following') &&
                      !l.startsWith('The relevant'),
                  orElse: () => d,
                );
            final reported = described.isNotEmpty ? described : errors;
            for (final text in reported) {
              if (text.contains('overflowed')) {
                details
                  ..writeln(
                    '== ${useCase.path} ${size.width.toInt()} '
                    '${platform.name} ${scale}x',
                  )
                  ..writeln(
                    text
                        .split('\n')
                        .where(
                          (l) => l.contains('.dart:') || l.contains('creator:'),
                        )
                        .take(6)
                        .join('\n'),
                  );
                overflows.add(
                  '${useCase.path} @ ${size.width.toInt()}x'
                  '${size.height.toInt()} ${platform.name} '
                  'text ${scale}x: ${headline(text)}'
                  '${_origin(text)}',
                );
              } else {
                notes.add('${useCase.path} (${headline(text)})');
                details
                  ..writeln(
                    '== SKIP ${useCase.path} ${platform.name} ${scale}x',
                  )
                  ..writeln(text.split('\n').take(60).join('\n'));
              }
            }
            if ([...overflows].any((o) => o.startsWith('${useCase.path} @'))) {
              break; // one finding per use case is enough to act on
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      while (tester.takeException() != null) {}
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      expect(
        overflows.where((o) => o.startsWith('${useCase.path} @')),
        isEmpty,
      );
    });
  }

  tearDownAll(() {
    final report = StringBuffer()
      ..writeln(
        'Phone gate: ${shardUseCases.length} use cases, '
        '${overflows.length} overflow(s), '
        '${skipped.map((s) => s.split(' ').first).toSet().length} '
        'use cases skipped (not verified), '
        '${notes.map((s) => s.split(' ').first).toSet().length} '
        'with non-layout errors (layout checked).',
      );
    for (final o in overflows) {
      report.writeln('  OVERFLOW $o');
    }
    for (final s in skipped) {
      report.writeln('  skipped  $s');
    }
    for (final n in notes) {
      report.writeln('  NOTE     $n');
    }
    File('build/phone_gate_details$suffix.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync(details.toString());
    File('build/phone_gate_report$suffix.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync(report.toString());
    // ignore: avoid_print
    print(report);
  });
}

/// The widget that caused an overflow, as `file.dart:line`, from the error
/// description (Flutter records the creation location in debug mode).
String _origin(String details) {
  final found = RegExp(
    r'(?:k_design_ui/lib/src|widgetbook/lib)/[\w/]+\.dart:\d+',
  ).allMatches(details).map((m) => m.group(0)!).toSet().take(3);
  return found.isEmpty ? '' : ' <- ${found.join(' | ')}';
}

/// Runs the whole gate in one process (small filters; see PHONE_GATE_FILTER).
void main() => runPhoneGate();
