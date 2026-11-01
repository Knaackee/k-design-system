import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

class FakeBackend implements KSoundBackend {
  final played = <KSoundCue>[];
  final volumes = <double>[];
  Completer<void>? gate;
  Completer<void>? preparation;
  final preparing = Completer<void>();
  bool fail = false;
  @override
  Future<void> play(
    KSoundCue cue,
    double volume, {
    required bool Function() isCurrent,
  }) async {
    if (!preparing.isCompleted) preparing.complete();
    await preparation?.future;
    if (!isCurrent()) return;
    if (fail) throw StateError('unavailable');
    played.add(cue);
    volumes.add(volume);
  }

  @override
  Future<void> stop() async {
    await gate?.future;
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('switchers share scoped sounds and respect mute', (tester) async {
    final backend = FakeBackend();
    final controller = KSoundController(enabled: true, backend: backend);
    await tester.pumpWidget(
      MaterialApp(
        home: KSoundProvider(
          controller: controller,
          child: Column(
            children: [
              KThemeSwitcher(value: ThemeMode.light, onChanged: (_) {}),
              KLanguageSwitcher(
                value: 'de',
                onChanged: (_) {},
                languages: const [
                  KLanguageOption(value: 'de', label: 'Deutsch'),
                  KLanguageOption(value: 'en', label: 'English'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    tester.widget<KIconButton>(find.byType(KIconButton).first).onPressed!();
    await tester.pumpAndSettle();
    expect(backend.played, [KSoundCue.switchCue]);
    final menu = tester.widget<KMenuButton>(find.byType(KMenuButton));
    menu.actions.last.onSelect!();
    await tester.pumpAndSettle();
    expect(backend.played, [KSoundCue.switchCue, KSoundCue.tap]);
    menu.actions.first.onSelect!();
    await tester.pumpAndSettle();
    expect(backend.played.length, 2);
    controller.setEnabled(false);
    menu.actions.last.onSelect!();
    await tester.pumpAndSettle();
    expect(backend.played.length, 2);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  for (final cancel in ['mute', 'background', 'dispose']) {
    test('cancels during asynchronous audio preparation: $cancel', () async {
      final backend = FakeBackend()..preparation = Completer<void>();
      final controller = KSoundController(enabled: true, backend: backend);
      final playing = controller.play(KSoundCue.complete);
      await backend.preparing.future;
      if (cancel == 'mute') controller.setEnabled(false);
      if (cancel == 'background') {
        controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      }
      if (cancel == 'dispose') controller.dispose();
      backend.preparation!.complete();
      await playing;
      expect(backend.played, isEmpty);
      if (cancel != 'dispose') controller.dispose();
    });
  }
  test('disabled default and event dedup', () async {
    final backend = FakeBackend();
    final controller = KSoundController(backend: backend);
    await controller.play(KSoundCue.tap);
    expect(backend.played, isEmpty);
    controller.setEnabled(true);
    await controller.play(KSoundCue.complete, eventId: 'import1');
    await controller.play(KSoundCue.complete, eventId: 'import1');
    expect(backend.played, [KSoundCue.complete]);
    expect(backend.volumes, [.25]);
    controller.dispose();
  });
  test('newer cue supersedes pending playback', () async {
    final backend = FakeBackend()..gate = Completer<void>();
    final controller = KSoundController(enabled: true, backend: backend);
    final first = controller.play(KSoundCue.tap);
    await Future<void>.delayed(Duration.zero);
    final second = controller.play(KSoundCue.swoosh);
    backend.gate!.complete();
    await Future.wait([first, second]);
    expect(backend.played, [KSoundCue.swoosh]);
    controller.dispose();
  });
  test('background, mute, volume bounds and contained failures', () async {
    final backend = FakeBackend();
    final controller = KSoundController(enabled: true, backend: backend);
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    await controller.play(KSoundCue.tap);
    expect(backend.played, isEmpty);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    backend.fail = true;
    await controller.play(KSoundCue.tap);
    backend.fail = false;
    controller.setVolume(2);
    await controller.play(KSoundCue.pop);
    expect(backend.volumes, [1.0]);
    controller.setEnabled(false);
    await controller.play(KSoundCue.drop);
    expect(backend.played, [KSoundCue.pop]);
    controller.dispose();
  });
}
