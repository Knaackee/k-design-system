import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class DictationFixture extends StatefulWidget {
  const DictationFixture({super.key});

  @override
  State<DictationFixture> createState() => _DictationFixtureState();
}

class _DictationFixtureState extends State<DictationFixture> {
  final title = TextEditingController(text: 'Inspect the roof');
  KDictationState state = KDictationState.ready;

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

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
    return SingleChildScrollView(
      child: KContainer(
        child: KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.section,
          children: [
            KField(
              label: 'Title',
              child: KInput(
                controller: title,
                dictationState: state,
                dictationOffset: 8,
                clearable: true,
                trailingAction: action,
              ),
            ),
            KField(
              label: 'Notes',
              child: KTextarea(
                dictationState: state,
                dictationOffset: 0,
                placeholder: 'Describe the next steps…',
                trailingAction: action,
              ),
            ),
            for (final status in KDictationState.values)
              KField(
                label: status.name,
                child: KInput(
                  dictationState: status,
                  dictationOffset: 0,
                  trailingAction: KDictationAction(
                    state: status,
                    label: 'Dictation ${status.name}',
                    onPressed: () {},
                  ),
                ),
              ),
            KField(
              label: 'Read only',
              child: KInput(readOnly: true, trailingAction: action),
            ),
            KField(
              label: 'Unavailable',
              child: KTextarea(enabled: false, trailingAction: action),
            ),
          ],
        ),
      ),
    );
  }
}
