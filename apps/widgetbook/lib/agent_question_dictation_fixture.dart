import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class AgentQuestionDictationFixture extends StatefulWidget {
  const AgentQuestionDictationFixture({super.key});

  @override
  State<AgentQuestionDictationFixture> createState() =>
      _AgentQuestionDictationFixtureState();
}

class _AgentQuestionDictationFixtureState
    extends State<AgentQuestionDictationFixture> {
  KDictationState state = KDictationState.ready;

  @override
  Widget build(BuildContext context) {
    final action = KDictationAction(
      state: state,
      label: state == KDictationState.recording
          ? 'Stop dictation'
          : 'Start dictation',
      onPressed: () => setState(() {
        state = state == KDictationState.recording
            ? KDictationState.ready
            : KDictationState.recording;
      }),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: KAgentQuestion(
          part: const KAgentQuestionPart(
            id: 'agent-ui-text-question-dictation',
            title: 'What should the agent remember?',
            description: 'The host owns recording and transcription.',
            kind: KAgentQuestionKind.text,
            state: KAgentResolutionState.pending,
            placeholder: 'Speak or type a note…',
            submitLabel: 'Save note',
          ),
          inputBuilder: (controller) => KInput(
            controller: controller,
            placeholder: 'Speak or type a note…',
            dictationState: state,
            trailingAction: action,
          ),
        ),
      ),
    );
  }
}
