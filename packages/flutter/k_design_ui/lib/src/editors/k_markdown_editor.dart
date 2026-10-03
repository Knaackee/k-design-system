import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:re_editor/re_editor.dart';

import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';
import '../forms/k_dictation_action.dart';
import 'k_code_editor.dart';
import 'k_editor_format_bar.dart';
import 'k_editor_types.dart';
import 'k_markdown_dictation_overlay.dart';
import 'k_markdown_source_formatting.dart';

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
    this.remoteSelections = const [],
    this.collaborationAdapter,
    this.semanticLabel = 'Markdown editor',
    this.onLinkRequested,
    this.minHeight = 280,
    this.formatBarMinimumItemExtent,
    this.dictationState,
    this.dictationOffset,
    this.dictationLabel = 'Dictate',
    this.onDictationPressed,
    super.key,
  });

  final String markdown;
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
  final List<KRemoteSelection> remoteSelections;
  final KEditorCollaborationAdapter? collaborationAdapter;
  final String semanticLabel;
  final KEditorLinkRequest? onLinkRequested;
  final double minHeight;

  /// Optional minimum size for every formatting action. When omitted, the
  /// format bar resolves a density- and input-mode-aware value from tokens.
  final double? formatBarMinimumItemExtent;

  /// Consumer-owned speech state. Omit to hide the dictation action.
  final KDictationState? dictationState;

  /// Saved insertion offset, which a collaboration host can map after edits.
  final int? dictationOffset;
  final String dictationLabel;
  final VoidCallback? onDictationPressed;

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
  KEditorSelection _selection = const KEditorSelection(anchor: 0, head: 0);

  KEditorMode get _mode => widget.mode ?? _internalMode;
  String get _effectiveDraft =>
      widget.collaborationAdapter?.snapshot.value.value ?? _draft;

  KEditorSelection get selection => _selection;

  /// Inserts a completed result through the source editor's undo/CRDT path.
  /// A collaborative host can supply its mapped saved selection.
  void insertDictation(String text, {KEditorSelection? selection}) {
    if (widget.readOnly || _mode != KEditorMode.source || text.isEmpty) return;
    final target = selection ?? _dictationSelection ?? _selection;
    _editorKey.currentState?.replaceRange(target.start, target.end, text);
    _dictationSelection = null;
  }

  void _dictate() {
    if (widget.dictationState != KDictationState.recording) {
      _dictationSelection = _selection;
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
    if (oldWidget.collaborationAdapter != widget.collaborationAdapter) {
      oldWidget.collaborationAdapter?.snapshot.removeListener(
        _handleCollaboration,
      );
      widget.collaborationAdapter?.snapshot.addListener(_handleCollaboration);
    }
    if (widget.markdown != oldWidget.markdown && widget.markdown != _draft) {
      _draft = widget.markdown;
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
    if (widget.mode == null) setState(() => _internalMode = mode);
    widget.onModeChanged?.call(mode);
  }

  void _changeSource(String value, KEditorTransaction transaction) {
    setState(() => _draft = value);
    widget.onChanged?.call(value, transaction);
  }

  void _updateSelection(KEditorSelection value) {
    setState(() => _selection = value);
    widget.onSelectionChanged?.call(value);
  }

  Future<void> _applyFormat(KMarkdownFormatAction action) async {
    if (widget.readOnly) return;
    if (action == KMarkdownFormatAction.undo) {
      _editorKey.currentState?.undo();
      return;
    }
    if (action == KMarkdownFormatAction.redo) {
      _editorKey.currentState?.redo();
      return;
    }
    String? href;
    if (action == KMarkdownFormatAction.link) {
      href = widget.onLinkRequested == null
          ? 'https://'
          : await widget.onLinkRequested!.call(_selection);
      if (!mounted || href == null) return;
    }
    final change = kMarkdownSourceChange(
      _effectiveDraft,
      _selection,
      action,
      href: href,
    );
    _editorKey.currentState?.replaceRange(
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
        final compact = constraints.maxWidth < 600;
        final editing = _mode == KEditorMode.source;
        return Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  if (widget.showFixedToolbar &&
                      editing &&
                      !widget.readOnly &&
                      !compact &&
                      widget.dictationState == null)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.colorSurfaceRaised,
                        border: Border(
                          bottom: BorderSide(color: t.colorBorderDefault),
                        ),
                      ),
                      child: KEditorFormatBar(
                        labels: widget.labels,
                        actions: widget.formatActions,
                        onAction: _applyFormat,
                        minimumItemExtent: widget.formatBarMinimumItemExtent,
                      ),
                    ),
                  Expanded(
                    child: editing
                        ? KMarkdownSourceGeometry(
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
                                    showSearchButton: true,
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
                                            _selection.start,
                                        state: widget.dictationState!,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : _MarkdownPreview(
                            markdown: _effectiveDraft,
                            semanticLabel: '${widget.semanticLabel} preview',
                            topInset: widget.showModeSwitcher
                                ? t.sizeHitTarget + t.spaceSmallInset
                                : t.spaceMediumInset,
                          ),
                  ),
                  if ((widget.showFixedToolbar ||
                          widget.dictationState != null) &&
                      editing &&
                      !widget.readOnly &&
                      (compact || widget.dictationState != null))
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
                          minimumItemExtent: widget.formatBarMinimumItemExtent,
                          trailingAction: widget.dictationState == null
                              ? null
                              : KDictationAction(
                                  state: widget.dictationState!,
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
                child: KIconButton(
                  label: editing ? widget.labels.read : widget.labels.source,
                  icon: editing ? KIconName.eye : KIconName.pen,
                  selected: !editing,
                  onPressed: () => _changeMode(
                    editing ? KEditorMode.read : KEditorMode.source,
                  ),
                ),
              ),
            if (widget.showFloatingToolbar &&
                editing &&
                !widget.readOnly &&
                !_selection.isCollapsed)
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
        );
      },
    );
  }
}

class _MarkdownPreview extends StatelessWidget {
  const _MarkdownPreview({
    required this.markdown,
    required this.semanticLabel,
    required this.topInset,
  });

  final String markdown;
  final String semanticLabel;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      label: semanticLabel,
      readOnly: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.colorSurfaceCanvas,
          border: Border.all(color: t.colorBorderDefault),
          borderRadius: BorderRadius.circular(t.radiusCard),
        ),
        child: Markdown(
          data: markdown,
          selectable: true,
          padding: EdgeInsets.fromLTRB(
            t.spaceMediumInset,
            topInset,
            t.spaceMediumInset,
            t.spaceMediumInset,
          ),
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: TextStyle(
              color: t.colorTextPrimary,
              fontFamily: t.fontFamily,
              fontSize: t.fontBodySize,
              height: t.fontBodyLineHeight / t.fontBodySize,
            ),
            h1: TextStyle(
              color: t.colorSyntaxHeading,
              fontFamily: t.fontFamily,
              fontSize: t.fontHeading2Size,
              fontWeight: t.fontHeadingWeight,
            ),
            h2: TextStyle(
              color: t.colorSyntaxHeading,
              fontFamily: t.fontFamily,
              fontSize: t.fontHeading3Size,
              fontWeight: t.fontHeadingWeight,
            ),
            code: TextStyle(
              color: t.colorSyntaxCode,
              backgroundColor: t.colorSurfaceSubtle,
              fontFamily: 'monospace',
            ),
            blockquoteDecoration: BoxDecoration(
              color: t.colorSurfaceSubtle,
              border: Border(
                left: BorderSide(
                  color: t.colorSyntaxMarkup,
                  width: t.borderWidthStrong,
                ),
              ),
            ),
            a: TextStyle(color: t.colorSyntaxLink),
          ),
        ),
      ),
    );
  }
}
