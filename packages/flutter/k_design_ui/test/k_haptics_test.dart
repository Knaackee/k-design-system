import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class _Recorder implements KHapticBackend {
  final cues = <KHapticCue>[];
  bool fail = false;
  @override
  Future<void> perform(KHapticCue cue) async {
    if (fail) throw StateError('no engine');
    cues.add(cue);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('off by default; enabled cues play once per interval', () async {
    final backend = _Recorder();
    final haptics = KHapticController(backend: backend);
    await haptics.perform(KHapticCue.selection);
    expect(backend.cues, isEmpty);
    haptics.setEnabled(true);
    await haptics.perform(KHapticCue.selection);
    await haptics.perform(KHapticCue.selection);
    expect(backend.cues, [KHapticCue.selection]);
    haptics.dispose();
  });

  test('zero interval, background and failures', () async {
    final backend = _Recorder();
    final haptics = KHapticController(
      enabled: true,
      backend: backend,
      minInterval: Duration.zero,
    );
    await haptics.perform(KHapticCue.light);
    await haptics.perform(KHapticCue.success);
    expect(backend.cues, [KHapticCue.light, KHapticCue.success]);
    haptics.didChangeAppLifecycleState(AppLifecycleState.paused);
    await haptics.perform(KHapticCue.error);
    expect(backend.cues, hasLength(2));
    haptics.didChangeAppLifecycleState(AppLifecycleState.resumed);
    backend.fail = true;
    await expectLater(haptics.perform(KHapticCue.error), completes);
    haptics.dispose();
    backend.fail = false;
    await haptics.perform(KHapticCue.error);
    expect(backend.cues, hasLength(2));
  });

  test('platform backend maps cues to HapticFeedback', () async {
    final calls = <Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments);
          }
          return null;
        });
    final haptics = KHapticController(
      enabled: true,
      minInterval: Duration.zero,
    );
    for (final cue in KHapticCue.values) {
      await haptics.perform(cue);
    }
    expect(calls, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
      'HapticFeedbackType.successNotification',
      'HapticFeedbackType.warningNotification',
      'HapticFeedbackType.errorNotification',
    ]);
    haptics.dispose();
  });

  testWidgets('switch and theme switcher play through the provider', (
    tester,
  ) async {
    final backend = _Recorder();
    final haptics = KHapticController(
      enabled: true,
      backend: backend,
      minInterval: Duration.zero,
    );
    addTearDown(haptics.dispose);
    var on = false;
    var mode = ThemeMode.light;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KHapticsProvider(
          controller: haptics,
          child: Scaffold(
            body: Column(
              children: [
                KSwitch(
                  value: on,
                  label: 'Wi-Fi',
                  onChanged: (value) => on = value,
                ),
                KThemeSwitcher(value: mode, onChanged: (value) => mode = value),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Wi-Fi'));
    await tester.tap(find.byType(KThemeSwitcher));
    await tester.pump();
    expect(on, isTrue);
    expect(mode, ThemeMode.dark);
    expect(backend.cues, [KHapticCue.light, KHapticCue.selection]);
  });
}
