import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

const _markdownSample = '''# Collaborative release notes

Select text to open the **contextual format bar**. Preview renders the same collaborative Markdown document.

- [x] Prepare the component contract
- [ ] Review keyboard and touch behavior
- [ ] Connect the consumer's CRDT transport

| Surface | State |
| --- | --- |
| Preview | **Read only** |
| Source | Editable |

![Preview image](assets/image-cropper/jordan.png)

> Persistence, rooms and permissions stay with the consuming application.

`KMarkdownEditor` emits controlled document and selection events.

```ts
const releaseState = "ready";
```
''';

const _codeSample = '''type EditorParticipant = {
  id: string;
  name: string;
  color: string;
};

export function participantLabel(user: EditorParticipant) {
  return user.name.trim() || "Anonymous";
}
''';

class EditorFixture extends StatefulWidget {
  const EditorFixture({
    required this.markdown,
    this.mobile = false,
    this.dictation = false,
    super.key,
  });

  final bool markdown;
  final bool mobile;
  final bool dictation;

  @override
  State<EditorFixture> createState() => _EditorFixtureState();
}

class _EditorFixtureState extends State<EditorFixture> {
  late String _value;
  KEditorMode _mode = KEditorMode.source;
  final _markdownKey = GlobalKey<KMarkdownEditorState>();
  KDictationState _dictationState = KDictationState.ready;

  Future<void> _dictate() async {
    if (_dictationState == KDictationState.ready) {
      setState(() => _dictationState = KDictationState.recording);
      return;
    }
    setState(() => _dictationState = KDictationState.processing);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _markdownKey.currentState?.insertDictation('Dictated release update. ');
    setState(() => _dictationState = KDictationState.ready);
  }

  @override
  void initState() {
    super.initState();
    _value = widget.markdown ? _markdownSample : _codeSample;
  }

  @override
  Widget build(BuildContext context) {
    final fallbackStart = _value.indexOf('Anonymous');
    final diagnostics = !widget.mobile && fallbackStart >= 0
        ? [
            KCodeDiagnostic(
              from: fallbackStart,
              to: fallbackStart + 'Anonymous'.length,
              severity: KCodeDiagnosticSeverity.info,
              message: 'This fallback label can be configured by the consumer.',
            ),
          ]
        : const <KCodeDiagnostic>[];
    return SizedBox.expand(
      child: widget.markdown
          ? KMarkdownEditor(
              key: _markdownKey,
              dictationState: widget.dictation ? _dictationState : null,
              dictationLabel: _dictationState == KDictationState.recording
                  ? 'Finish dictation'
                  : 'Start dictation',
              onDictationPressed: widget.dictation ? _dictate : null,
              markdown: _value,
              onChanged: (value, _) => setState(() => _value = value),
              mode: _mode,
              onModeChanged: (mode) => setState(() => _mode = mode),
              showFixedToolbar: true,
              showFloatingToolbar: true,
              showModeSwitcher: true,
              semanticLabel: widget.mobile
                  ? 'Mobile Markdown editor'
                  : 'Markdown editor',
            )
          : KCodeEditor(
              value: _value,
              onChanged: (value, _) => setState(() => _value = value),
              language: KCodeLanguage.typescript,
              completions: const [
                KCodeCompletion(
                  label: 'participantLabel',
                  detail: 'Format a participant name',
                  type: KCodeCompletionType.function,
                ),
                KCodeCompletion(
                  label: 'EditorParticipant',
                  detail: 'Participant contract',
                  type: KCodeCompletionType.keyword,
                ),
              ],
              lineWrapping: widget.mobile,
              showLineNumbers: false,
              showSearchButton: true,
              diagnostics: diagnostics,
              semanticLabel: widget.mobile
                  ? 'Mobile code editor'
                  : 'Code editor',
            ),
    );
  }
}
