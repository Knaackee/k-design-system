import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
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

const _compactMarkdownSample = '''# A calmer workspace

## Goal
Help people collect research, decisions, and next actions in one place. A short note should be easy to start and comfortable to expand into a longer working document.

## The first release
- Capture an idea while it is still fresh.
- Add **context** and links to the original research.
- Share a clear next action with the team.

## Review checklist
- [x] Describe the problem in plain language.
- [ ] Try the small editor on a phone.
- [ ] Expand the document and finish the longer sections.
- [ ] Return to the original field with every edit intact.

## Notes from the team
> Keep the first interaction simple. Give longer thoughts room to grow.

The compact field belongs in a larger form. Expansion provides a focused writing space for reviewing the whole brief, adding details, and refining the wording.

## Next steps
Discuss the open questions on Friday, update the checklist, and prepare a concise summary for the next review.
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
    this.readOnly = false,
    this.compact = false,
    super.key,
  });

  final bool markdown;
  final bool mobile;
  final bool dictation;
  final bool readOnly;
  final bool compact;

  @override
  State<EditorFixture> createState() => _EditorFixtureState();
}

class _EditorFixtureState extends State<EditorFixture> {
  late String _value;
  KEditorMode _mode = KEditorMode.source;
  final _markdownKey = GlobalKey<KMarkdownEditorState>();
  KDictationState _dictationState = KDictationState.ready;
  int _dictationAttempt = 0;

  Future<void> _dictate() async {
    if (_dictationState == KDictationState.ready) {
      setState(() => _dictationState = KDictationState.recording);
      return;
    }
    setState(() => _dictationState = KDictationState.processing);
    final attempt = ++_dictationAttempt;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || attempt != _dictationAttempt) return;
    _markdownKey.currentState?.insertDictation('Dictated release update. ');
    setState(() => _dictationState = KDictationState.ready);
  }

  void _cancelDictation() {
    _dictationAttempt++;
    setState(() => _dictationState = KDictationState.ready);
  }

  @override
  void initState() {
    super.initState();
    _value = widget.markdown
        ? (widget.compact ? _compactMarkdownSample : _markdownSample)
        : _codeSample;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final dictationEnabled = widget.dictation;
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
          ? KStack(
              align: KLayoutAlign.stretch,
              children: [
                if (widget.compact) ...[
                  const KText(
                    'Markdown-Eingabefeld',
                    variant: KTextVariant.heading3,
                  ),
                  const KText(
                    'Kleines bearbeitbares Feld. Maximiert mit Formatleiste und simuliertem Diktat.',
                  ),
                ],
                if (!widget.compact &&
                    dictationEnabled &&
                    _dictationState != KDictationState.ready)
                  KButton(
                    label: 'Cancel dictation',
                    variant: KButtonVariant.secondary,
                    onPressed: _cancelDictation,
                  ),
                Flexible(
                  fit: widget.compact ? FlexFit.loose : FlexFit.tight,
                  child: SizedBox(
                    height: widget.compact ? t.sizeHitTarget * 4 : null,
                    child: KMarkdownEditor(
                      key: _markdownKey,
                      dictationState: dictationEnabled ? _dictationState : null,
                      dictationLabel:
                          _dictationState == KDictationState.recording
                          ? 'Finish dictation'
                          : _dictationState == KDictationState.processing
                          ? 'Processing dictation'
                          : 'Start dictation',
                      onDictationPressed: dictationEnabled ? _dictate : null,
                      showExpandButton: true,
                      showFixedToolbar: !widget.compact,
                      showFloatingToolbar: !widget.compact,
                      showModeSwitcher: !widget.compact,
                      showSearchButton: !widget.compact,
                      markdown: _value,
                      readOnly: widget.readOnly,
                      onChanged: (value, _) => setState(() => _value = value),
                      mode: _mode,
                      onModeChanged: (mode) => setState(() => _mode = mode),
                      imageBuilder: (uri, alt, title) =>
                          uri.toString() == 'assets/image-cropper/jordan.png'
                          ? Image.asset(uri.toString(), semanticLabel: alt)
                          : KText(alt ?? 'Image unavailable'),
                      semanticLabel: widget.mobile
                          ? 'Mobile Markdown editor'
                          : 'Markdown editor',
                    ),
                  ),
                ),
              ],
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

class EditorCollaborationFixture extends StatefulWidget {
  const EditorCollaborationFixture({super.key});

  @override
  State<EditorCollaborationFixture> createState() =>
      _EditorCollaborationFixtureState();
}

class _EditorCollaborationFixtureState
    extends State<EditorCollaborationFixture> {
  final _selections = [
    const KEditorSelection(anchor: 48, head: 48),
    const KEditorSelection(anchor: 20, head: 34),
  ];
  late final _adapters = [
    for (var index = 0; index < _selections.length; index++)
      _FixtureSnapshotAdapter((transaction) => _publish(index, transaction)),
  ];
  var _connected = true;
  var _document = _markdownSample;

  KEditorParticipant _participant(int index) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return index == 0
        ? KEditorParticipant(
            id: 'dennis',
            name: 'Dennis',
            color: t.colorBrandPrimaryAccent,
          )
        : KEditorParticipant(
            id: 'alex',
            name: 'Alex',
            color: t.colorBrandSecondaryAccent,
          );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(0);
    if (_connected) _sync(1);
  }

  void _sync(int index) {
    final peer = 1 - index;
    final participant = _participant(peer);
    _adapters[index].snapshot.value = KEditorCollaborationSnapshot(
      value: _document,
      selection: _selections[index],
      participants: _connected ? [participant] : const [],
      remoteSelections: _connected
          ? [
              KRemoteSelection(
                anchor: _selections[peer].anchor.clamp(0, _document.length),
                head: _selections[peer].head.clamp(0, _document.length),
                participant: participant,
              ),
            ]
          : const [],
    );
  }

  void _publish(int index, KEditorTransaction transaction) {
    _document = transaction.value;
    _selections[index] = transaction.selection;
    _sync(index);
    if (_connected) _sync(1 - index);
  }

  void _select(int index, KEditorSelection selection) {
    _selections[index] = selection;
    if (_connected) _sync(1 - index);
  }

  void _toggleConnection() {
    setState(() => _connected = !_connected);
    _sync(0);
    if (_connected) _sync(1);
  }

  @override
  void dispose() {
    for (final adapter in _adapters) {
      adapter.snapshot.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget editor(int index) {
      final participant = _participant(index);
      return KStack(
        align: KLayoutAlign.stretch,
        children: [
          KText(participant.name, variant: KTextVariant.heading3),
          KMarkdownEditor(
            markdown: _document,
            readOnly: index == 1 && !_connected,
            collaborationAdapter: _adapters[index],
            showFixedToolbar: false,
            onSelectionChanged: (selection) => _select(index, selection),
            semanticLabel: '${participant.name} Markdown editor',
          ),
        ],
      );
    }

    return KPage(
      children: [
        const KText(
          'Snapshot demo. Edits sync in this gallery. Reconnecting loads the latest shared text.',
        ),
        KButton(
          label: _connected ? 'Disconnect Alex' : 'Reconnect Alex',
          variant: KButtonVariant.secondary,
          onPressed: _toggleConnection,
        ),
        LayoutBuilder(
          builder: (context, constraints) =>
              kWindowClassForWidth(constraints.maxWidth) == KWindowClass.compact
              ? KStack(
                  gap: KLayoutGap.section,
                  align: KLayoutAlign.stretch,
                  children: [editor(0), editor(1)],
                )
              : KInline(
                  gap: KLayoutGap.section,
                  children: [
                    Expanded(child: editor(0)),
                    Expanded(child: editor(1)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _FixtureSnapshotAdapter implements KEditorCollaborationAdapter {
  _FixtureSnapshotAdapter(this._publish);

  final ValueChanged<KEditorTransaction> _publish;

  @override
  final ValueNotifier<KEditorCollaborationSnapshot> snapshot = ValueNotifier(
    const KEditorCollaborationSnapshot(value: ''),
  );

  @override
  void applyLocalTransaction(KEditorTransaction transaction) =>
      _publish(transaction);
}
