import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  test('crop bounds preserve a square and clamp pan/zoom', () {
    expect(
      kImageCropRect(const Size(800, 400), 1, Offset.zero),
      const Rect.fromLTWH(200, 0, 400, 400),
    );
    expect(
      kImageCropRect(const Size(400, 800), 2, const Offset(1, -1)),
      const Rect.fromLTWH(200, 0, 200, 200),
    );
    expect(
      kImageCropRect(const Size(800, 400), 20, const Offset(20, -20)),
      const Rect.fromLTWH(700, 0, 100, 100),
    );
  });
  testWidgets(
    'round export is PNG with transparent corners and selected size',
    (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late Uint8List source;
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawRect(
          const Rect.fromLTWH(0, 0, 80, 40),
          Paint()..color = Colors.red,
        );
        final picture = recorder.endRecording();
        final image = await picture.toImage(80, 40);
        picture.dispose();
        source = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        image.dispose();
      });
      Uint8List? output;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 240,
                child: KImageCropper(
                  image: MemoryImage(source),
                  outputSize: 32,
                  onConfirm: (bytes) => output = bytes,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(find.text('Use image')).dy,
        lessThanOrEqualTo(640),
      );
      await tester.ensureVisible(find.text('Use image'));
      await tester.tap(find.text('Use image'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(output, isNotNull);
      await tester.runAsync(() async {
        final codec = await ui.instantiateImageCodec(output!);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 32);
        expect(frame.image.height, 32);
        final pixels = (await frame.image.toByteData())!.buffer.asUint8List();
        expect(pixels[3], 0);
        expect(pixels[(16 * 32 + 16) * 4 + 3], 255);
        frame.image.dispose();
        codec.dispose();
      });
    },
  );
}
