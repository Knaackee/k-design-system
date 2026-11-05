// Review screenshots for visual acceptance (Decision 0014). Not a gate:
// runs only with --dart-define=K_SCREENSHOTS=<story>, for example
//   flutter test test/tools/review_screenshots_test.dart \
//     --dart-define=K_SCREENSHOTS=app-shell --dart-define=K_SCREENSHOTS_OUT=<dir>
// and writes <style>-<width>-<scale>.png with the packaged Inter font.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/core_components_fixture.dart';

const _story = String.fromEnvironment('K_SCREENSHOTS');
const _out = String.fromEnvironment(
  'K_SCREENSHOTS_OUT',
  defaultValue: 'build/review',
);
final _stories = <String, Widget Function()>{
  'app-shell': () => const AppShellFixture(),
  'list': () => const ListFixture(),
  'page-header': () => const PageHeaderFixture(),
  'segmented-control': () => const SegmentedControlFixture(),
};
const _shots = [
  (Size(393, 852), TargetPlatform.iOS, 1.0),
  (Size(393, 852), TargetPlatform.iOS, 1.3),
  (Size(393, 852), TargetPlatform.iOS, 2.0),
  (Size(393, 852), TargetPlatform.iOS, 3.0),
  (Size(820, 1180), TargetPlatform.iOS, 1.0),
  (Size(1280, 800), TargetPlatform.macOS, 1.0),
];

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

  testWidgets('review screenshots', skip: _story.isEmpty, (tester) async {
    final build = _stories[_story]!;
    Directory(_out).createSync(recursive: true);
    for (final style in KStyle.values) {
      for (final brightness in Brightness.values) {
        for (final (size, platform, scale) in _shots) {
          final key = GlobalKey();
          tester.view.physicalSize = size * 2;
          tester.view.devicePixelRatio = 2;
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(platform: platform),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    devicePixelRatio: 2,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: KAdaptiveTheme(
                    // SF Pro and Roboto do not exist in the test host.
                    fontFamily: 'packages/k_design_tokens/Inter',
                    brightness: brightness,
                    overrides: KAdaptiveOverrides(style: style),
                    child: KLocalization(
                      locale: 'en',
                      child: Builder(
                        builder: (context) => Material(
                          color: Theme.of(
                            context,
                          ).extension<KDesignTokens>()!.colorSurfaceCanvas,
                          child: build(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final bytes = await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            return data!.buffer.asUint8List();
          });
          File(
            '$_out/${style.name}-${brightness.name}-${size.width.toInt()}-$scale.png',
          ).writeAsBytesSync(bytes!);
        }
      }
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
