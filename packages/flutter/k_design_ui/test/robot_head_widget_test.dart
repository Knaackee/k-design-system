import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('activation and reactions stay separate when paused', (
    tester,
  ) async {
    final controller = KRobotHeadController();
    var activates = 0;
    var reactions = 0;
    await tester.pumpWidget(
      host(
        KRobotHead(
          controller: controller,
          paused: true,
          onActivate: () => activates++,
          onReactionStart: () => reactions++,
        ),
      ),
    );
    await tester.tap(find.byType(KRobotHead));
    expect(activates, 1);
    expect(reactions, 0);
    expect(controller.react(), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(activates, 3);
    await tester.pumpWidget(const SizedBox());
    expect(controller.react(), isFalse);
    controller.reset();
    expect(tester.takeException(), isNull);
  });

  testWidgets('controller reaction ends once and reset cancels it', (
    tester,
  ) async {
    final controller = KRobotHeadController();
    var starts = 0, ends = 0;
    await tester.pumpWidget(
      host(
        KRobotHead(
          controller: controller,
          onReactionStart: () => starts++,
          onReactionEnd: () => ends++,
        ),
      ),
    );
    expect(controller.react(), isTrue);
    expect(controller.react(), isTrue);
    expect(starts, 1);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(ends, 1);
    expect(controller.react(), isTrue);
    controller.reset();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(ends, 1);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('audio reads stop when paused, reduced, or removed', (
    tester,
  ) async {
    var reads = 0;
    final controller = KRobotHeadController();
    Widget robot({bool paused = false, bool reduced = false}) => host(
      KRobotHead(
        controller: controller,
        paused: paused,
        reducedMotion: reduced,
        state: KRobotHeadState.speaking,
        audioSource: () {
          reads++;
          return const KRobotHeadAudioFrame(level: .7);
        },
      ),
    );
    await tester.pumpWidget(robot());
    await tester.pump(const Duration(milliseconds: 16));
    expect(reads, greaterThan(0));
    await tester.pumpWidget(robot(paused: true));
    final frozen = reads;
    await tester.pump(const Duration(seconds: 1));
    expect(reads, frozen);
    await tester.pumpWidget(robot(reduced: true));
    await tester.pump(const Duration(seconds: 1));
    expect(reads, frozen);
    expect(controller.react(), isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(reads, frozen);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all shapes and states paint with finite bounds', (tester) async {
    for (final shape in KRobotHeadShape.values) {
      for (final state in KRobotHeadState.values) {
        await tester.pumpWidget(
          host(
            KRobotHead(
              shape: shape,
              state: state,
              reducedMotion: true,
              size: 240,
              interactive: false,
            ),
          ),
        );
        expect(tester.getSize(find.byType(KRobotHead)), const Size(240, 240));
        expect(tester.takeException(), isNull, reason: '$shape $state');
      }
    }
    await tester.pumpWidget(const SizedBox());
  });
}
