import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class ChatComposerFixture extends StatefulWidget {
  const ChatComposerFixture({this.mobile = false, super.key});
  final bool mobile;
  @override
  State<ChatComposerFixture> createState() => _ChatComposerFixtureState();
}

class _ChatComposerFixtureState extends State<ChatComposerFixture> {
  String value = 'Check both platforms';
  bool voiceActive = false;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: widget.mobile ? 360 : 800,
      child: SingleChildScrollView(
        child: KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.section,
          children: [
            KChatComposer(
              value: value,
              onValueChanged: (next) => setState(() => value = next),
              onSubmit: (_) {},
              onAttach: () {},
              voiceActive: voiceActive,
              onVoiceInput: () => setState(() => voiceActive = !voiceActive),
            ),
            KChatComposer(
              value: 'Recording',
              onValueChanged: (_) {},
              onSubmit: (_) {},
              onAttach: () {},
              voiceActive: true,
              voiceAudioLevel: 0.5,
              onVoiceInput: () {},
            ),
            KChatComposer(
              value: 'Unavailable',
              disabled: true,
              onValueChanged: (_) {},
              onSubmit: (_) {},
              onVoiceInput: () {},
            ),
            KChatComposer(
              value: '',
              runState: KChatRunState.streaming,
              onValueChanged: (_) {},
              onSubmit: (_) {},
              onStop: () {},
              onVoiceInput: () {},
            ),
            for (final state in [
              KDictationState.processing,
              KDictationState.unavailable,
              KDictationState.error,
            ])
              KChatComposer(
                value: state.name,
                voiceState: state,
                onValueChanged: (_) {},
                onSubmit: (_) {},
                onVoiceInput: () {},
              ),
            KChatComposer(
              value: 'Voice omitted',
              onValueChanged: (_) {},
              onSubmit: (_) {},
            ),
          ],
        ),
      ),
    ),
  );
}
