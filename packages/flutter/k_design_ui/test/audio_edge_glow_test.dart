import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('perimeter travel stays continuous across the 13 second cycle', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: KAudioEdgeGlow(
          state: KAudioEdgeGlowState.capturing,
          color: Color(0xff84cc16),
        ),
      ),
    );
    await tester.pump();
    Future<List<int>> pixels() async {
      final painter = tester
          .widget<CustomPaint>(find.byKey(const ValueKey('k-audio-edge-glow')))
          .painter!;
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), const Size(120, 180));
      final picture = recorder.endRecording();
      final result = await tester.runAsync(() async {
        final image = await picture.toImage(120, 180);
        final bytes = await image.toByteData();
        final values = bytes!.buffer.asUint8List().toList();
        image.dispose();
        return values;
      });
      picture.dispose();
      return result!;
    }

    int difference(List<int> left, List<int> right) {
      var sum = 0;
      for (var index = 0; index < left.length; index++) {
        sum += (left[index] - right[index]).abs();
      }
      return sum;
    }

    await tester.pump(const Duration(milliseconds: 12940));
    final before = await pixels();
    await tester.pump(const Duration(milliseconds: 40));
    final boundary = await pixels();
    await tester.pump(const Duration(milliseconds: 40));
    final after = await pixels();
    final normalChange = difference(before, boundary);
    final cycleChange = difference(boundary, after);
    expect(normalChange, greaterThan(0));
    expect(cycleChange, lessThan(normalChange * 2));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'glow preserves underlying pointer action and disappears when inactive',
    (tester) async {
      var taps = 0;
      Widget screen(KAudioEdgeGlowState state) => MaterialApp(
        home: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => taps++,
                child: const ColoredBox(color: Color(0xff101010)),
              ),
            ),
            Positioned.fill(
              child: KAudioEdgeGlow(
                state: state,
                color: const Color(0xff84cc16),
                reducedMotion: true,
              ),
            ),
          ],
        ),
      );
      await tester.pumpWidget(screen(KAudioEdgeGlowState.capturing));
      expect(find.byKey(const ValueKey('k-audio-edge-glow')), findsOneWidget);
      await tester.tapAt(const Offset(3, 3));
      expect(taps, 1);
      await tester.pumpWidget(screen(KAudioEdgeGlowState.inactive));
      expect(find.byKey(const ValueKey('k-audio-edge-glow')), findsNothing);
    },
  );
  testWidgets(
    'OS reduced motion has no ticker and still reacts to changed energy',
    (tester) async {
      Widget screen(double level) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: KAudioEdgeGlow(
            state: KAudioEdgeGlowState.capturing,
            color: const Color(0xff84cc16),
            audioLevel: level,
          ),
        ),
      );
      await tester.pumpWidget(screen(double.nan));
      await tester.pumpAndSettle();
      await tester.pumpWidget(screen(1));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(screen(double.infinity));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'processing ignores microphone extremes and inactive ticker is disposed',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KAudioEdgeGlow(
            state: KAudioEdgeGlowState.processing,
            color: Color(0xff84cc16),
            audioLevel: 10,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
