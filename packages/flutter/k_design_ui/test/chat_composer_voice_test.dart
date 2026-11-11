import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('dense tablet composer matches the Web control icon role', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(configuration: KDesignConfiguration.dashboard),
        home: Scaffold(
          body: KChatComposer(
            value: '',
            onValueChanged: (_) {},
            onSubmit: (_) {},
            onStartCall: () {},
          ),
        ),
      ),
    );
    final scope = tester.widget<KIconSizeScope>(find.byType(KIconSizeScope));
    expect(scope.size, 16);
    expect(tester.takeException(), isNull);
  });

  Widget screen({
    String value = 'Host draft',
    KDictationState state = KDictationState.recording,
    VoidCallback? onVoiceInput,
    VoidCallback? onCancel,
    VoidCallback? onSend,
    VoidCallback? onStartCall,
  }) => MaterialApp(
    theme: kDesignTheme(),
    home: Scaffold(
      body: KChatComposer(
        value: value,
        onValueChanged: (_) {},
        onSubmit: (_) {},
        voiceState: state,
        onVoiceInput: onVoiceInput ?? () {},
        voiceCapture: KChatVoiceCapture(
          samples: const [0, .5, double.nan, 4],
          error: 'Not recognized',
          onCancel: onCancel ?? () {},
          onSend: onSend ?? () {},
        ),
        onStartCall: onStartCall,
      ),
    ),
  );

  testWidgets('recording replaces input and preserves host draft on cancel', (
    tester,
  ) async {
    var cancelled = 0;
    var stopped = 0;
    var sent = 0;
    await tester.pumpWidget(
      screen(
        onCancel: () => cancelled++,
        onVoiceInput: () => stopped++,
        onSend: () => sent++,
      ),
    );

    expect(find.byType(TextField), findsNothing);
    expect(
      find.byKey(const ValueKey('k-chat-composer-voice-waveform')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('k-chat-composer-voice-waveform')))
          .width,
      greaterThan(100),
    );
    await tester.tap(find.byTooltip('Discard recording'));
    await tester.tap(find.byTooltip('Stop voice input'));
    await tester.tap(find.byTooltip('Transcribe and send'));
    expect((cancelled, stopped, sent), (1, 1, 1));

    await tester.pumpWidget(screen(state: KDictationState.ready));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Host draft',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('processing and error expose cancellable status and retry', (
    tester,
  ) async {
    var cancelled = 0;
    var retried = 0;
    await tester.pumpWidget(
      screen(
        state: KDictationState.processing,
        onCancel: () => cancelled++,
        onVoiceInput: () => retried++,
      ),
    );
    final statusCenter = tester.getCenter(
      find.byKey(const ValueKey('k-chat-composer-voice-processing')),
    );
    final cancelCenter = tester.getCenter(find.byTooltip('Discard recording'));
    expect(statusCenter.dy, closeTo(cancelCenter.dy, 1));
    expect(
      find.byKey(const ValueKey('k-chat-composer-voice-processing')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<KIconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is KIconButton && widget.label == 'Stop voice input',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<KIconButton>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is KIconButton &&
                  widget.label == 'Transcribe and send',
            ),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Discard recording'));
    expect(cancelled, 1);

    await tester.pumpWidget(
      screen(
        state: KDictationState.error,
        onCancel: () => cancelled++,
        onVoiceInput: () => retried++,
      ),
    );
    expect(find.text('Not recognized'), findsOneWidget);
    await tester.tap(find.byTooltip('Retry voice input'));
    expect(retried, 1);
  });

  testWidgets('empty idle composer offers call while a draft offers send', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      screen(
        value: '',
        state: KDictationState.ready,
        onStartCall: () => calls++,
      ),
    );
    expect(find.byTooltip('Start call'), findsOneWidget);
    await tester.tap(find.byTooltip('Start call'));
    expect(calls, 1);

    await tester.pumpWidget(
      screen(
        value: 'Draft',
        state: KDictationState.ready,
        onStartCall: () => calls++,
      ),
    );
    expect(find.byTooltip('Start call'), findsNothing);
    expect(find.byTooltip('Send message'), findsOneWidget);
  });
}
