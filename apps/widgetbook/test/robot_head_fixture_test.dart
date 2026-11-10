import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/robot_head_fixture.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final eventChannels = <MethodChannel>[];

  setUp(() async {
    for (final channel in [
      const MethodChannel('xyz.luan/audioplayers.global'),
      const MethodChannel('xyz.luan/audioplayers.global/events'),
    ]) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => null,
      );
    }
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        if (call.method == 'create') {
          final id = (call.arguments as Map)['playerId'];
          final channel = MethodChannel('xyz.luan/audioplayers/events/$id');
          eventChannels.add(channel);
          binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            (_) async => null,
          );
        }
        return null;
      },
    );
    await AudioPlayer.global.ensureInitialized();
  });

  tearDown(() {
    for (final channel in [
      const MethodChannel('xyz.luan/audioplayers'),
      const MethodChannel('xyz.luan/audioplayers.global'),
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      ...eventChannels,
    ]) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    }
    eventChannels.clear();
  });

  testWidgets('playground renders at phone size for bounded animation frames', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: RobotHeadPlaygroundFixture()),
      ),
    );
    expect(tester.takeException(), isNull);

    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }

    expect(find.text('KRobotHead'), findsOneWidget);
    expect(find.text('PCM-WAV auswählen'), findsOneWidget);
    expect(find.byType(KPage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(360, 740), const Size(393, 852)]) {
    testWidgets(
      'playground controls fit ${size.width} pt',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        for (final scale in [1.0, 1.3, 2.0, 3.0]) {
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                  disableAnimations: true,
                ),
                child: KAdaptiveTheme(child: child!),
              ),
              home: const Scaffold(body: RobotHeadPlaygroundFixture()),
            ),
          );
          expect(tester.takeException(), isNull, reason: 'Text scale $scale');
        }

        final antennaLabel = find.text('Antenne');
        expect(antennaLabel, findsOneWidget);
        await tester.ensureVisible(antennaLabel);
        await tester.pump();
        await tester.tap(antennaLabel);
        await tester.pump();
        expect(
          tester.widget<KRobotHead>(find.byType(KRobotHead)).antenna,
          false,
        );
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.iOS,
        TargetPlatform.android,
      }),
    );
  }
}
