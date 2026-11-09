import 'package:flutter/material.dart';
import '../markdown/k_markdown_preview.dart';
import '../markdown/k_markdown_options.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:re_editor/re_editor.dart';

import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';
import '../forms/k_dictation_action.dart';
import 'k_code_editor.dart';
import 'k_editor_format_bar.dart';
import 'k_editor_types.dart';
import 'k_markdown_dictation_overlay.dart';
import 'k_markdown_link_dialog.dart';
import 'k_markdown_source_formatting.dart';

part 'k_markdown_editor_preview.dart';

typedef KEditorLinkRequest =
    Future<String?> Function(KEditorSelection selection);

class KMarkdownEditor extends StatefulWidget {
  const KMarkdownEditor({
    required this.markdown,
    this.onChanged,
    this.mode,
    this.defaultMode = KEditorMode.source,
    this.onModeChanged,
    this.onSelectionChanged,
    this.readOnly = false,
    this.placeholder = 'Write something…',
    this.labels = const KEditorLabels(),
    this.formatActions = kDefaultMarkdownFormatActions,
    this.showFixedToolbar = true,
    this.showFloatingToolbar = true,
    this.showModeSwitcher = true,
    this.showSearchButton = true,
    this.contentMaxWidth,
    this.remoteSelections = const [],
    this.collaborationAdapter,
    this.semanticLabel = 'Markdown editor',
    this.onLinkRequested,
    this.imageBuilder,
    this.onLinkPressed,
    this.markdownOptions = const KMarkdownOptions(),
    this.minHeight = 280,
    this.formatBarMinimumItemExtent,
    this.dictationState,
    this.dictationAudioLevel,
    this.dictationOffset,
    this.dictationLabel = 'Dictate',
    this.onDictationPressed,
    this.onFocus,
    this.onBlur,
    super.key,
  });

  final String markdown;

  /// Observes local edits and incoming document snapshots. Inspect the
  /// transaction origin when forwarding edits to an external system.
  final void Function(String value, KEditorTransaction transaction)? onChanged;
  final KEditorMode? mode;
  final KEditorMode defaultMode;
  final ValueChanged<KEditorMode>? onModeChanged;
  final ValueChanged<KEditorSelection>? onSelectionChanged;
  final bool readOnly;
  final String placeholder;
  final KEditorLabels labels;
  final List<KMarkdownFormatAction> formatActions;
  final bool showFixedToolbar;
  final bool showFloatingToolbar;
  final bool showModeSwitcher;
  final bool showSearchButton;
  final double? contentMaxWidth;
  final List<KRemoteSelection> remoteSelections;
  final KEditorCollaborationAdapter? collaborationAdapter;
  final String semanticLabel;

  /// Overrides the built-in link form. Return null to cancel insertion.
  final KEditorLinkRequest? onLinkRequested;

  /// Host-owned resolution of relative or protected Markdown images.
  final Widget Function(Uri uri, String? alt, String? title)? imageBuilder;
  final ValueChanged<String>? onLinkPressed;
  final KMarkdownOptions markdownOptions;
  final double minHeight;

  /// Optional minimum size for every formatting action. When omitted, the
  /// format bar resolves a density- and input-mode-aware value from tokens.
  final double? formatBarMinimumItemExtent;

  /// Consumer-owned speech state. Omit to hide the dictation action.
  final KDictationState? dictationState;

  /// Normalized genuine microphone level for the shared dictation action.
  final double? dictationAudioLevel;

  /// Saved insertion offset, which a collaboration host can map after edits.
  final int? dictationOffset;
  final String dictationLabel;
  final VoidCallback? onDictationPressed;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;

  @override
  State<KMarkdownEditor> createState() => KMarkdownEditorState();
}

class KMarkdownEditorState extends State<KMarkdownEditor> {
  final _editorKey = GlobalKey<KCodeEditorState>();
  final _scrollController = CodeScrollController();
  final _paragraphs = ValueNotifier<CodeIndicatorValue?>(null);
  KEditorSelection? _dictationSelection;
  late KEditorMode _internalMode;
  late String _draft;
  bool _linkPending = false;
  (String, KEditorSelection)? _previewSelection;

  KEditorMode get _mode => widget.mode ?? _internalMode;
  String get _effectiveDraft =>
      widget.collaborationAdapter?.snapshot.value.value ?? _draft;

  /// The mounted K source editor for consumer-owned toolbars and commands.
  KCodeEditorState? get sourceEditor => _editorKey.currentState;

  KEditorSelection get selection =>
      sourceEditor?.selection ??
      widget.collaborationAdapter?.snapshot.value.selection ??
      const KEditorSelection(anchor: 0, head: 0);

  void openSearch() => sourceEditor?.openSearch();

  /// Inserts a completed result through the source editor's undo/CRDT path.
  /// A collaborative host can supply its mapped saved selection.
  bool insertDictation(String text, {KEditorSelection? selection}) {
    if (widget.readOnly || _mode != KEditorMode.source || text.isEmpty) {
      return false;
    }
    final target = selection ?? _dictationSelection ?? this.selection;
    final editor = _editorKey.currentState;
    if (editor == null) return false;
    editor.replaceRange(target.start, target.end, text);
    _dictationSelection = null;
    return true;
  }

  void _dictate() {
    if (widget.dictationState != KDictationState.recording) {
      _dictationSelection = selection;
    }
    widget.onDictationPressed?.call();
  }

  @override
  void initState() {
    super.initState();
    _internalMode = widget.defaultMode;
    _draft = widget.markdown;
    widget.collaborationAdapter?.snapshot.addListener(_handleCollaboration);
  }

  @override
  void didUpdateWidget(covariant KMarkdownEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.mode ?? _internalMode) != _mode) {
      _switchSourceVisibility(_mode);
    }
    if (oldWidget.collaborationAdapter != widget.collaborationAdapter) {
      _previewSelection = null;
      oldWidget.collaborationAdapter?.snapshot.removeListener(
        _handleCollaboration,
      );
      widget.collaborationAdapter?.snapshot.addListener(_handleCollaboration);
    }
    if (widget.markdown != oldWidget.markdown && widget.markdown != _draft) {
      _draft = widget.markdown;
    }
    if (widget.dictationState != oldWidget.dictationState &&
        (widget.dictationState == KDictationState.ready ||
            widget.dictationState == null)) {
      _dictationSelection = null;
    }
  }

  @override
  void dispose() {
    widget.collaborationAdapter?.snapshot.removeListener(_handleCollaboration);
    _scrollController.verticalScroller.dispose();
    _scrollController.horizontalScroller.dispose();
    _scrollController.dispose();
    _paragraphs.dispose();
    super.dispose();
  }

  void _handleCollaboration() {
    if (mounted) setState(() {});
  }

  void _changeMode(KEditorMode mode) {
    if (widget.mode == null) {
      _switchSourceVisibility(mode);
      setState(() => _internalMode = mode);
    }
    widget.onModeChanged?.call(mode);
  }

  void _switchSourceVisibility(KEditorMode next) {
    final editor = sourceEditor;
    if (editor == null || widget.collaborationAdapter != null) return;
    if (next == KEditorMode.read) {
      _previewSelection = (editor.value, editor.selection);
    } else if (_previewSelection case final saved?) {
      _previewSelection = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _mode == KEditorMode.source &&
            editor.value == saved.$1) {
          editor.setSelection(saved.$2);
        }
      });
    }
  }

  void _changeSource(String value, KEditorTransaction transaction) {
    setState(() => _draft = value);
    widget.onChanged?.call(value, transaction);
  }

  void _updateSelection(KEditorSelection value) {
    setState(() {});
    widget.onSelectionChanged?.call(value);
  }

  Future<void> _applyFormat(KMarkdownFormatAction action) async {
    final editor = _editorKey.currentState;
    if (widget.readOnly || _mode != KEditorMode.source || editor == null) {
      return;
    }
    if (action == KMarkdownFormatAction.undo) {
      editor.undo();
      return;
    }
    if (action == KMarkdownFormatAction.redo) {
      editor.redo();
      return;
    }
    final source = editor.value;
    final target = editor.selection;
    String? href;
    if (action == KMarkdownFormatAction.link) {
      if (_linkPending) return;
      _linkPending = true;
      final request = widget.onLinkRequested;
      final adapter = widget.collaborationAdapter;
      String? result;
      try {
        result = await (request == null
            ? showKMarkdownLinkDialog(context, widget.labels)
            : request(target));
      } finally {
        _linkPending = false;
      }
      if (!mounted ||
          widget.readOnly ||
          _mode != KEditorMode.source ||
          adapter != widget.collaborationAdapter ||
          source != editor.value) {
        return;
      }
      if (result == null) {
        // Mobile editors collapse a selection when the modal takes focus.
        if (request == null) {
          editor.replaceRange(
            target.start,
            target.start,
            '',
            selection: target,
          );
        }
        return;
      }
      href = kMarkdownLinkUrl(result);
      if (href == null) return;
    }
    final change = kMarkdownSourceChange(source, target, action, href: href);
    editor.replaceRange(
      change.from,
      change.to,
      change.insert,
      selection: change.selection,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    return LayoutBuilder(
      builder: (context, constraints) {
        final editing = _mode == KEditorMode.source;
        return SizedBox(
          height: constraints.hasBoundedHeight
              ? constraints.maxHeight
              : widget.minHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      child: IndexedStack(
                        index: editing ? 0 : 1,
                        sizing: StackFit.expand,
                        children: [
                          ExcludeFocus(
                            excluding: !editing,
                            child: KMarkdownSourceGeometry(
                              scrollController: _scrollController,
                              paragraphs: _paragraphs,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: KCodeEditor(
                                      key: _editorKey,
                                      value: _effectiveDraft,
                                      onChanged: _changeSource,
                                      onSelectionChanged: _updateSelection,
                                      language: KCodeLanguage.markdown,
                                      readOnly: widget.readOnly,
                                      placeholder: widget.placeholder,
                                      showLineNumbers: false,
                                      lineWrapping: true,
                                      showSearchButton: widget.showSearchButton,
                                      contentMaxWidth: widget.contentMaxWidth,
                                      searchButtonEndInset:
                                          widget.showModeSwitcher
                                          ? t.sizeHitTarget +
                                                t.spaceControlGap * 2
                                          : null,
                                      labels: widget.labels,
                                      remoteSelections: widget.remoteSelections,
                                      collaborationAdapter:
                                          widget.collaborationAdapter,
                                      semanticLabel: widget.semanticLabel,
                                      minHeight: widget.minHeight,
                                      onFocus: widget.onFocus,
                                      onBlur: widget.onBlur,
                                    ),
                                  ),
                                  if (!widget.readOnly &&
                                      (widget.dictationState ==
                                              KDictationState.recording ||
                                          widget.dictationState ==
                                              KDictationState.processing))
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: KMarkdownDictationOverlay(
                                          scrollController: _scrollController,
                                          paragraphs: _paragraphs,
                                          source: _effectiveDraft,
                                          offset:
                                              widget.dictationOffset ??
                                              _dictationSelection?.start ??
                                              selection.start,
                                          state: widget.dictationState!,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          _MarkdownPreview(
                            markdown: _effectiveDraft,
                            semanticLabel: '${widget.semanticLabel} preview',
                            contentMaxWidth: widget.contentMaxWidth,
                            imageBuilder: widget.imageBuilder,
                            markdownOptions: widget.markdownOptions,
                            onLinkPressed: widget.onLinkPressed,
                            topInset: widget.showModeSwitcher
                                ? t.sizeHitTarget + t.spaceSmallInset
                                : t.spaceMediumInset,
                          ),
                        ],
                      ),
                    ),
                    if ((widget.showFixedToolbar ||
                            widget.dictationState != null) &&
                        editing &&
                        !widget.readOnly)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            t.spaceControlGap,
                            t.spaceControlGap,
                            t.spaceControlGap,
                            t.spaceControlGap,
                          ),
                          child: KEditorFormatBar(
                            labels: widget.labels,
                            actions: widget.showFixedToolbar
                                ? widget.formatActions
                                : const [],
                            onAction: _applyFormat,
                            floating: true,
                            minimumItemExtent:
                                widget.formatBarMinimumItemExtent,
                            leadingAction: widget.dictationState == null
                                ? null
                                : KDictationAction(
                                    state: widget.dictationState!,
                                    audioLevel: widget.dictationAudioLevel,
                                    label: widget.dictationLabel,
                                    onPressed: widget.onDictationPressed == null
                                        ? null
                                        : _dictate,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.showModeSwitcher)
                PositionedDirectional(
                  top: t.spaceControlGap,
                  end: t.spaceControlGap,
                  child: CodeEditorTapRegion(
                    child: KIconButton(
                      label: editing
                          ? widget.labels.read
                          : widget.labels.source,
                      icon: editing ? KIconName.eye : KIconName.pen,
                      selected: !editing,
                      onPressed: () => _changeMode(
                        editing ? KEditorMode.read : KEditorMode.source,
                      ),
                    ),
                  ),
                ),
              if (widget.showFloatingToolbar &&
                  editing &&
                  !widget.readOnly &&
                  !selection.isCollapsed)
                PositionedDirectional(
                  top: t.sizeHitTarget + t.spaceSmallInset,
                  start: t.spaceSmallInset,
                  end: t.spaceSmallInset,
                  child: Align(
                    alignment: AlignmentDirectional.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: t.componentBottomSheetMaxWidth,
                      ),
                      child: KEditorFormatBar(
                        labels: widget.labels,
                        actions: widget.formatActions,
                        onAction: _applyFormat,
                        floating: true,
                        minimumItemExtent: widget.formatBarMinimumItemExtent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
