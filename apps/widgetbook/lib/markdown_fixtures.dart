import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

/// Keeps editor overlays inside the gallery's active viewport.
class MarkdownEditorDemoViewport extends StatelessWidget {
  const MarkdownEditorDemoViewport({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => MediaQuery(
      data: MediaQuery.of(context).copyWith(size: bounds.biggest),
      child: Navigator(
        pages: [MaterialPage<void>(child: child)],
        onDidRemovePage: (_) {},
      ),
    ),
  );
}

class MarkdownFixture extends StatefulWidget {
  const MarkdownFixture({
    this.fixture = 'basic',
    this.chat = false,
    this.preview = false,
    super.key,
  });
  final String fixture;
  final bool chat;
  final bool preview;
  @override
  State<MarkdownFixture> createState() => _MarkdownFixtureState();
}

class _MarkdownFixtureState extends State<MarkdownFixture> {
  static const _alertLabels = {
    'NOTE': 'Hinweis',
    'TIP': 'Tipp',
    'IMPORTANT': 'Wichtig',
    'WARNING': 'Warnung',
    'CAUTION': 'Vorsicht',
  };
  late Future<String> _content;
  String _event = '';
  String _previewState = 'ready';
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _content = rootBundle.loadString(
      '../../fixtures/markdown/${widget.fixture}.md',
    );
  }

  @override
  void didUpdateWidget(MarkdownFixture oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fixture != widget.fixture) _load();
  }

  void _link(Uri uri) => setState(() => _event = 'Link ausgewählt: $uri');
  Future<void> _copy(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) setState(() => _event = 'In die Zwischenablage kopiert.');
    } catch (_) {
      if (mounted) {
        setState(() => _event = 'Die Zwischenablage ist hier nicht verfügbar.');
      }
    }
  }

  Widget _image(Uri uri, String? alt, String? title) =>
      uri.toString() == './project-preview.png'
      ? Image.asset('assets/image-cropper/jordan.png', semanticLabel: alt)
      : KText('${alt ?? ''}: Bild nicht verfügbar');
  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _content,
    builder: (context, snapshot) => KPage(
      children: [
        if (snapshot.hasError)
          const KText('Markdown konnte nicht geladen werden.')
        else if (!snapshot.hasData)
          const KText('Lädt …')
        else if (widget.preview) ...[
          KInline(
            gap: KLayoutGap.action,
            wrap: true,
            children: [
              for (final entry in const {
                'ready': 'Dokument',
                'loading': 'Laden',
                'empty': 'Leer',
              }.entries)
                KButton(
                  label: entry.value,
                  variant: KButtonVariant.secondary,
                  onPressed: () => setState(() => _previewState = entry.key),
                ),
            ],
          ),
          KMarkdownPreview(
            content: _previewState == 'empty' ? '' : snapshot.data!,
            loading: _previewState == 'loading',
            loadingContent: const KText('Dokument wird geladen …'),
            emptyContent: const KText('Dieses Dokument ist leer.'),
            contentMaxWidth: Theme.of(
              context,
            ).extension<KDesignTokens>()!.layoutFormWidth,
            semanticLabel: 'Dokumentvorschau',
            copyLabel: 'Kopieren',
            tableLabel: 'Tabelle',
            completedTaskLabel: 'Erledigt',
            incompleteTaskLabel: 'Offen',
            alertLabels: _alertLabels,
            onCopy: _copy,
            onLinkActivate: _link,
            imageBuilder: _image,
          ),
        ] else
          KMarkdownRenderer(
            content: snapshot.data!,
            profile: widget.chat
                ? KMarkdownProfile.chat
                : KMarkdownProfile.document,
            copyLabel: 'Kopieren',
            tableLabel: 'Tabelle',
            completedTaskLabel: 'Erledigt',
            incompleteTaskLabel: 'Offen',
            alertLabels: _alertLabels,
            onCopy: _copy,
            onLinkActivate: _link,
            imageBuilder: _image,
          ),
        KText(_event, variant: KTextVariant.caption),
      ],
    ),
  );
}

/// Exercises the real editor/chat wrappers against the same canonical document.
class MarkdownIntegrationFixture extends StatefulWidget {
  const MarkdownIntegrationFixture({this.chat = false, super.key});
  final bool chat;
  @override
  State<MarkdownIntegrationFixture> createState() =>
      _MarkdownIntegrationFixtureState();
}

class _MarkdownIntegrationFixtureState
    extends State<MarkdownIntegrationFixture> {
  String? _content;
  String _event = '';
  @override
  void initState() {
    super.initState();
    rootBundle.loadString('../../fixtures/markdown/basic.md').then((value) {
      if (mounted) setState(() => _content = value);
    });
  }

  Future<void> _copy(String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (mounted) setState(() => _event = 'In die Zwischenablage kopiert.');
    } catch (_) {
      if (mounted) {
        setState(() => _event = 'Die Zwischenablage ist hier nicht verfügbar.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_content == null) return const KPage(children: [KText('Lädt …')]);
    final options = KMarkdownOptions(
      copyLabel: 'Kopieren',
      tableLabel: 'Tabelle',
      completedTaskLabel: 'Erledigt',
      incompleteTaskLabel: 'Offen',
      alertLabels: _MarkdownFixtureState._alertLabels,
      onCopy: _copy,
      onLinkActivate: (uri) => setState(() => _event = 'Link ausgewählt: $uri'),
    );
    return Column(
      children: [
        Expanded(
          child: widget.chat
              ? KChatConversation(
                  metadataMode: KChatMessageMetadataMode.hidden,
                  labels: const KChatLabels(
                    assistant: 'Assistent',
                    newContent: 'Zu neuesten Nachrichten',
                  ),
                  markdownOptions: options,
                  userMarkdownAllowedElements: const {'p'},
                  formatTimestamp: (value) =>
                      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
                  messages: [
                    KChatMessageValue(
                      id: 'user',
                      role: KChatRole.user,
                      timestamp: DateTime(2026, 11, 9, 9, 41),
                      parts: const [
                        KChatTextPart(
                          id: 'request',
                          text:
                              '# Bitte zeige mir den aktuellen Stand.\n\n**Danke!**',
                        ),
                      ],
                    ),
                    KChatMessageValue(
                      id: 'assistant',
                      role: KChatRole.assistant,
                      timestamp: DateTime(2026, 11, 9, 9, 42),
                      parts: [KChatTextPart(id: 'response', text: _content!)],
                    ),
                  ],
                )
              : KMarkdownEditor(
                  markdown: _content!,
                  defaultMode: KEditorMode.read,
                  markdownOptions: options,
                  semanticLabel: 'Markdown bearbeiten',
                  labels: const KEditorLabels(
                    read: 'Vorschau',
                    search: 'Suchen',
                    searchFind: 'Suchbegriff',
                    searchReplace: 'Ersetzen',
                    linkDialogTitle: 'Link einfügen',
                    linkUrl: 'Link-Adresse',
                    linkCancel: 'Abbrechen',
                    linkSubmit: 'Einfügen',
                    linkInvalidUrl: 'Gib eine gültige Link-Adresse ein.',
                    linkClose: 'Schließen',
                  ),
                  onChanged: (value, _) => setState(() => _content = value),
                ),
        ),
        KText(_event, variant: KTextVariant.caption),
      ],
    );
  }
}

class MarkdownStreamingFixture extends StatefulWidget {
  const MarkdownStreamingFixture({super.key});

  @override
  State<MarkdownStreamingFixture> createState() =>
      _MarkdownStreamingFixtureState();
}

class _MarkdownStreamingFixtureState extends State<MarkdownStreamingFixture> {
  late final _sequence = rootBundle
      .loadString('../../fixtures/markdown/streaming-sequence.json')
      .then(
        (value) => (jsonDecode(value) as List).cast<Map<String, dynamic>>(),
      );
  int _step = 0;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _sequence,
    builder: (context, snapshot) {
      final sequence = snapshot.data;
      if (sequence == null) {
        return KPage(
          children: [
            KText(
              snapshot.hasError
                  ? 'Streaming-Demo konnte nicht geladen werden.'
                  : 'Lädt …',
            ),
          ],
        );
      }
      final frame = sequence[_step];
      final tokens = Theme.of(context).extension<KDesignTokens>()!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(tokens.spaceLayoutGutter),
            child: KInline(
              gap: KLayoutGap.action,
              align: KLayoutAlign.center,
              wrap: true,
              children: [
                KButton(
                  label: 'Zurücksetzen',
                  variant: KButtonVariant.secondary,
                  onPressed: _step == 0
                      ? null
                      : () => setState(() => _step = 0),
                ),
                KButton(
                  label: 'Nächster Schritt',
                  onPressed: _step == sequence.length - 1
                      ? null
                      : () => setState(() => _step++),
                ),
                KText(
                  '${_step + 1} / ${sequence.length}',
                  variant: KTextVariant.caption,
                ),
              ],
            ),
          ),
          Expanded(
            child: KChatConversation(
              metadataMode: KChatMessageMetadataMode.hidden,
              labels: const KChatLabels(
                assistant: 'Assistent',
                newContent: 'Zu neuesten Nachrichten',
              ),
              markdownOptions: const KMarkdownOptions(tableLabel: 'Tabelle'),
              messages: [
                KChatMessageValue(
                  id: 'streaming-answer',
                  role: KChatRole.assistant,
                  parts: [
                    KChatTextPart(
                      id: 'answer-text',
                      text: frame['content'] as String,
                      streaming: frame['streaming'] as bool,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
