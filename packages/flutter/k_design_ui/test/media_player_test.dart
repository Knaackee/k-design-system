import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'controlled transport labels state and disables play when unavailable',
    (tester) async {
      var calls = 0;
      Future<void> render({bool playing = false, String? error}) =>
          tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
              home: Scaffold(
                body: KMediaPlayer(
                  name: 'Clip',
                  playing: playing,
                  position: const Duration(seconds: 42),
                  duration: const Duration(minutes: 3, seconds: 24),
                  volume: 1,
                  error: error,
                  onPlayPause: () => calls++,
                  onSeek: (_) {},
                  onVolume: (_) {},
                ),
              ),
            ),
          );
      await render();
      expect(find.text('0:42'), findsOneWidget);
      expect(find.text('3:24'), findsOneWidget);
      expect(calls, 0);
      await tester.tap(find.byTooltip('Abspielen'));
      expect(calls, 1);
      await render(playing: true);
      expect(find.byTooltip('Pausieren'), findsOneWidget);
      await render(error: 'Format nicht unterstützt');
      await tester.tap(find.byTooltip('Abspielen'));
      expect(calls, 1);
    },
  );
}
