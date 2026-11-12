import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/re_highlight.dart' show Mode;
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/typescript.dart';

import '../actions/k_icon_button.dart';
import '../forms/k_dictation_action.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import 'k_editor_search_panel.dart';
import 'k_code_remote_carets.dart';
import 'k_code_source_map.dart';
import 'k_editor_types.dart';
import 'k_markdown_dictation_overlay.dart';

class KCodeEditor extends StatefulWidget {
  const KCodeEditor({
    required this.value,
    this.onChanged,
    this.onSelectionChanged,
    this.language = KCodeLanguage.plain,
    this.readOnly = false,
    this.placeholder,
    this.showLineNumbers = false,
    this.lineWrapping = false,
    this.showSearchButton = true,
    this.contentMaxWidth,
    this.embedded = false,
    this.prose = false,
    this.searchButtonEndInset,
    this.fontFamily = 'packages/k_design_ui/KDesignMono',
    this.fontFamilyFallback = const [
      'Cascadia Mono',
      'Consolas',
      'Roboto Mono',
      'monospace',
    ],
    this.labels = const KEditorLabels(),
    this.completions = const [],
    this.onCompletionSelected,
    this.diagnostics = const [],
    this.remoteSelections = const [],
    this.collaborationAdapter,
    this.semanticLabel = 'Code editor',
    this.minHeight = 280,
    this.onFocus,
    this.onBlur,
    this.dictationState,
    this.dictationOffset,
    super.key,
  });

  final String value;

  /// Observes local edits and incoming document snapshots. External [value]
  /// replacements and presence-only updates do not emit transactions.
  final void Function(String value, KEditorTransaction transaction)? onChanged;
  final ValueChanged<KEditorSelection>? onSelectionChanged;
  final KCodeLanguage language;
  final bool readOnly;
  final String? placeholder;
  final bool showLineNumbers;
  final bool lineWrapping;
  final bool showSearchButton;
  final double? contentMaxWidth;

  /// Flat, compact editor inside a workspace that owns its toolbar.
  final bool embedded;

  /// Body typography and a transparent surface for composed prose fields.
  final bool prose;
  final double? searchButtonEndInset;
  final String? fontFamily;
  final List<String>? fontFamilyFallback;
  final KEditorLabels labels;
  final List<KCodeCompletion> completions;
  final ValueChanged<KCodeCompletion>? onCompletionSelected;
  final List<KCodeDiagnostic> diagnostics;
  final List<KRemoteSelection> remoteSelections;
  final KEditorCollaborationAdapter? collaborationAdapter;
  final String semanticLabel;
  final double minHeight;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;

  /// Visual-only insertion anchor. The host maps this offset through its CRDT.
  final KDictationState? dictationState;
  final int? dictationOffset;

  @override
  State<KCodeEditor> createState() => KCodeEditorState();
}

class KCodeEditorState extends State<KCodeEditor> {
  late CodeLineEditingController _controller;
  late CodeFindController _findController;
  late FocusNode _focusNode;
  KEditorSelection _selection = const KEditorSelection(anchor: 0, head: 0);
  late KEditorSelection _lastNotifiedSelection;
  KEditorSelection? _snapshotSelection;
  bool _searchOpen = false;
  bool _applyingExternal = false;
  late String _lastControllerText;
  late KCodeSourceMap _source;
  final _remoteScroll = CodeScrollController();
  final _paragraphs = ValueNotifier<CodeIndicatorValue?>(null);
  final _indicatorKey = GlobalKey();

  String get value => _source.raw;
  KEditorSelection get selection => _selection;

  @override
  void initState() {
    super.initState();
    _source = KCodeSourceMap(_effectiveValue);
    _controller = CodeLineEditingController(
      codeLines: CodeLines.fromText(_source.rendered),
    );
    _snapshotSelection = widget.collaborationAdapter?.snapshot.value.selection;
    if (_snapshotSelection case final selection?) {
      _replaceValue(_source.raw, selection);
      _controller.clearHistory();
    }
    _lastNotifiedSelection = _selection;
    _lastControllerText = _controller.text;
    _findController = CodeFindController(_controller);
    _focusNode = FocusNode()..addListener(_handleFocus);
    _controller.addListener(_handleController);
    widget.collaborationAdapter?.snapshot.addListener(_handleCollaboration);
  }

  String get _effectiveValue =>
      widget.collaborationAdapter?.snapshot.value.value ?? widget.value;

  List<KRemoteSelection> get _effectiveRemoteSelections =>
      widget.collaborationAdapter?.snapshot.value.remoteSelections ??
      widget.remoteSelections;

  List<KEditorParticipant> get _effectiveParticipants {
    final participants =
        widget.collaborationAdapter?.snapshot.value.participants;
    return participants?.isNotEmpty == true
        ? participants!
        : _effectiveRemoteSelections
              .map((selection) => selection.participant)
              .toList();
  }

  @override
  void didUpdateWidget(covariant KCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final adapterChanged =
        oldWidget.collaborationAdapter != widget.collaborationAdapter;
    if (adapterChanged) {
      oldWidget.collaborationAdapter?.snapshot.removeListener(
        _handleCollaboration,
      );
      widget.collaborationAdapter?.snapshot.addListener(_handleCollaboration);
      _snapshotSelection =
          widget.collaborationAdapter?.snapshot.value.selection;
    }
    if (_effectiveValue != _source.raw) {
      _replaceSnapshot(_effectiveValue, _snapshotSelection);
    } else if (adapterChanged && _snapshotSelection != null) {
      _replaceSnapshot(_effectiveValue, _snapshotSelection);
    } else if (oldWidget.remoteSelections != widget.remoteSelections) {
      _controller.forceRepaint();
    }
    if (adapterChanged) _controller.clearHistory();
  }

  @override
  void dispose() {
    widget.collaborationAdapter?.snapshot.removeListener(_handleCollaboration);
    _controller.removeListener(_handleController);
    _controller.dispose();
    _findController.dispose();
    _remoteScroll.dispose();
    _paragraphs.dispose();
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  void focus() => _focusNode.requestFocus();

  /// Opens document search from a consumer-owned toolbar.
  void openSearch() => setState(() => _searchOpen = true);

  void undo() {
    if (!widget.readOnly) _controller.undo();
  }

  void redo() {
    if (!widget.readOnly) _controller.redo();
  }

  /// Changes the selection without editing the document or requesting focus.
  void setSelection(KEditorSelection selection) {
    if (_selection == selection) return;
    _replaceValue(_source.raw, selection);
    _notifySelection();
  }

  void replaceRange(
    int from,
    int to,
    String insert, {
    KEditorSelection? selection,
  }) {
    if (widget.readOnly) return;
    final source = _source.raw;
    final safeFrom = from.clamp(0, source.length);
    final safeTo = to.clamp(safeFrom, source.length);
    final next = source.replaceRange(safeFrom, safeTo, insert);
    final nextSelection =
        selection ??
        KEditorSelection(
          anchor: safeFrom + insert.length,
          head: safeFrom + insert.length,
        );
    if (next != source) {
      _controller.runRevocableOp(() => _replaceValue(next, nextSelection));
      _emitLocalTransaction();
    } else {
      setSelection(nextSelection);
    }
    focus();
  }

  void _handleFocus() {
    if (_focusNode.hasFocus) {
      widget.onFocus?.call();
    } else {
      widget.onBlur?.call();
    }
  }

  void _handleCollaboration() {
    final snapshot = widget.collaborationAdapter?.snapshot.value;
    if (snapshot == null) return;
    final textChanged = snapshot.value != _source.raw;
    final selectionChanged = snapshot.selection != _snapshotSelection;
    _snapshotSelection = snapshot.selection;
    if (textChanged || selectionChanged && snapshot.selection != _selection) {
      _replaceSnapshot(snapshot.value, snapshot.selection);
    } else {
      _controller.forceRepaint();
    }
    if (mounted) setState(() {});
    if (textChanged) {
      widget.onChanged?.call(
        _source.raw,
        KEditorTransaction(
          value: _source.raw,
          selection: _selection,
          origin: KEditorTransactionOrigin.remote,
        ),
      );
    }
  }

  void _replaceSnapshot(String next, KEditorSelection? selection) {
    final textChanged = next != _source.raw;
    _replaceValue(next, selection ?? _selection);
    _lastNotifiedSelection = _selection;
    // re_editor stores entire values. Older undo entries can erase remote text.
    if (textChanged) _controller.clearHistory();
  }

  void _replaceValue(String next, KEditorSelection nextSelection) {
    _applyingExternal = true;
    _source.raw = next;
    final rawSelection = _clampSelection(nextSelection, next.length);
    _selection = rawSelection;
    _controller.value = _editingValue(
      _source.rendered,
      KEditorSelection(
        anchor: _source.toRendered(rawSelection.anchor),
        head: _source.toRendered(rawSelection.head),
      ),
    );
    _lastControllerText = _controller.text;
    _applyingExternal = false;
  }

  void _handleController() {
    final textChanged = _controller.text != _lastControllerText;
    if (!_applyingExternal && textChanged) {
      _source.acceptRendered(_controller.text);
    }
    final rendered = _globalSelection(_controller);
    final nextSelection = KEditorSelection(
      anchor: _source.toRaw(rendered.anchor),
      head: _source.toRaw(rendered.head),
    );
    if (nextSelection != _selection) {
      _selection = nextSelection;
      if (!_applyingExternal && !textChanged) {
        _notifySelection();
      }
    }
  }

  void _handleChanged(CodeLineEditingValue _) {
    if (_applyingExternal || _controller.text == _lastControllerText) return;
    _source.acceptRendered(_controller.text);
    _lastControllerText = _controller.text;
    final rendered = _globalSelection(_controller);
    _selection = KEditorSelection(
      anchor: _source.toRaw(rendered.anchor),
      head: _source.toRaw(rendered.head),
    );
    _emitLocalTransaction();
  }

  void _notifySelection() {
    if (_lastNotifiedSelection == _selection) return;
    _lastNotifiedSelection = _selection;
    widget.onSelectionChanged?.call(_selection);
  }

  void _emitLocalTransaction() {
    final transaction = KEditorTransaction(
      value: _source.raw,
      selection: _selection,
      origin: KEditorTransactionOrigin.local,
    );
    widget.onChanged?.call(transaction.value, transaction);
    _notifySelection();
    widget.collaborationAdapter?.applyLocalTransaction(transaction);
  }

  @override
  Widget build(BuildContext context) {
    final markdownGeometry = KMarkdownSourceGeometry.of(context);
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : widget.minHeight;
        return Semantics(
          label: widget.semanticLabel,
          textField: true,
          enabled: !widget.readOnly,
          focusable: true,
          readOnly: widget.readOnly,
          child: SizedBox(
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.prose ? Colors.transparent : t.colorSurfaceCanvas,
                border: widget.embedded
                    ? null
                    : Border.all(color: t.colorBorderDefault),
                borderRadius: BorderRadius.circular(
                  widget.embedded ? 0 : t.radiusCard,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  widget.embedded ? 0 : t.radiusCard,
                ),
                child: Column(
                  children: [
                    if (_searchOpen)
                      KEditorSearchPanel(
                        controller: _findController,
                        labels: widget.labels,
                        readOnly: widget.readOnly,
                        onClose: () {
                          setState(() => _searchOpen = false);
                          focus();
                        },
                      ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: widget.contentMaxWidth ?? double.infinity,
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: _withAutocomplete(
                                  CodeEditor(
                                    scrollController:
                                        markdownGeometry?.scrollController ??
                                        _remoteScroll,
                                    controller: _controller,
                                    findController: _findController,
                                    focusNode: _focusNode,
                                    onChanged: _handleChanged,
                                    readOnly: widget.readOnly,
                                    wordWrap: widget.lineWrapping,
                                    hint: widget.placeholder,
                                    autofocus: false,
                                    padding: widget.prose
                                        ? EdgeInsets.only(
                                            top: t.spaceControlGap,
                                            bottom:
                                                t.spaceControlGap +
                                                (markdownGeometry
                                                        ?.bottomInset ??
                                                    0),
                                          )
                                        : EdgeInsets.fromLTRB(
                                            widget.embedded
                                                ? t.spaceControlInsetInline + 6
                                                : t.spaceMediumInset,
                                            widget.showSearchButton
                                                ? t.sizeHitTarget +
                                                      t.spaceSmallInset
                                                : widget.embedded
                                                ? t.spaceControlInsetInline +
                                                      (widget.language ==
                                                              KCodeLanguage
                                                                  .markdown
                                                          ? 4
                                                          : 0)
                                                : t.spaceMediumInset,
                                            widget.embedded
                                                ? t.spaceControlInsetInline + 2
                                                : t.spaceMediumInset,
                                            (widget.diagnostics.isEmpty
                                                    ? widget.embedded
                                                          ? t.spaceControlInsetInline
                                                          : t.spaceMediumInset
                                                    : t.sizeHitTarget) +
                                                (markdownGeometry
                                                        ?.bottomInset ??
                                                    0),
                                          ),
                                    style: CodeEditorStyle(
                                      fontFamily: widget.fontFamily,
                                      fontFamilyFallback:
                                          widget.fontFamilyFallback,
                                      fontSize: widget.prose
                                          ? MediaQuery.textScalerOf(context)
                                                .clamp(maxScaleFactor: 3)
                                                .scale(t.fontControlSize)
                                          : widget.embedded
                                          ? t.fontBodySmallSize
                                          : t.fontBodySize,
                                      fontHeight: widget.embedded
                                          ? t.fontBodySmallLineHeight /
                                                t.fontBodySmallSize
                                          : t.fontRelaxedHeight,
                                      textColor: t.colorTextPrimary,
                                      hintTextColor: t.colorTextMuted,
                                      backgroundColor: widget.prose
                                          ? Colors.transparent
                                          : t.colorSurfaceCanvas,
                                      cursorColor: t.colorBorderFocus,
                                      selectionColor:
                                          t.colorBrandPrimaryBackground,
                                      highlightColor:
                                          t.colorBrandSecondaryBackground,
                                      codeTheme: _codeTheme(
                                        t,
                                        widget.language,
                                        embedded: widget.embedded,
                                      ),
                                    ),
                                    indicatorBuilder:
                                        (
                                          context,
                                          editing,
                                          chunk,
                                          notifier,
                                        ) => KCodeParagraphCapture(
                                          key: _indicatorKey,
                                          source: notifier,
                                          target: _paragraphs,
                                          child: widget.showLineNumbers
                                              ? DefaultCodeLineNumber(
                                                  controller: editing,
                                                  notifier: notifier,
                                                  textStyle: TextStyle(
                                                    color: t.colorTextMuted,
                                                    fontFamily:
                                                        widget.fontFamily,
                                                    fontFamilyFallback: widget
                                                        .fontFamilyFallback,
                                                    fontSize: t.fontCaptionSize,
                                                  ),
                                                )
                                              : markdownGeometry?.capture(
                                                      notifier,
                                                    ) ??
                                                    const SizedBox.shrink(),
                                        ),
                                    leadingDivider: widget.showLineNumbers
                                        ? VerticalDivider(
                                            width: t.spaceSmallInset,
                                            color: t.colorBorderDefault,
                                          )
                                        : null,
                                    border: null,
                                    borderRadius: BorderRadius.circular(
                                      t.radiusCard,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: KCodeRemoteCarets(
                                  paragraphs: _paragraphs,
                                  scrollController:
                                      markdownGeometry?.scrollController ??
                                      _remoteScroll,
                                  selections: _effectiveRemoteSelections,
                                  source: _source.raw,
                                  indicatorKey: _indicatorKey,
                                  dividerWidth: widget.showLineNumbers
                                      ? t.spaceSmallInset
                                      : 0,
                                  width: t.borderWidthStrong,
                                ),
                              ),
                              if (!widget.readOnly &&
                                  widget.dictationOffset != null &&
                                  (widget.dictationState ==
                                          KDictationState.recording ||
                                      widget.dictationState ==
                                          KDictationState.processing))
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: KMarkdownDictationOverlay(
                                      scrollController:
                                          markdownGeometry?.scrollController ??
                                          _remoteScroll,
                                      paragraphs: _paragraphs,
                                      source: _source.raw,
                                      offset: widget.dictationOffset!,
                                      state: widget.dictationState!,
                                    ),
                                  ),
                                ),
                              if (widget.showSearchButton)
                                PositionedDirectional(
                                  top: t.spaceControlGap,
                                  end:
                                      widget.searchButtonEndInset ??
                                      t.spaceControlGap,
                                  child: KIconButton(
                                    label: widget.labels.search,
                                    icon: KIconName.search,
                                    selected: _searchOpen,
                                    onPressed: () {
                                      setState(
                                        () => _searchOpen = !_searchOpen,
                                      );
                                      if (!_searchOpen) {
                                        _findController.close();
                                        focus();
                                      }
                                    },
                                  ),
                                ),
                              if (widget.diagnostics.isNotEmpty)
                                PositionedDirectional(
                                  start: 0,
                                  end: 0,
                                  bottom: 0,
                                  child: _DiagnosticBar(
                                    items: widget.diagnostics,
                                  ),
                                ),
                              if (_effectiveParticipants.isNotEmpty)
                                PositionedDirectional(
                                  start: t.spaceSmallInset,
                                  bottom: widget.diagnostics.isEmpty
                                      ? t.spaceSmallInset
                                      : t.sizeHitTarget,
                                  child: _PresenceBar(
                                    participants: _effectiveParticipants,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _withAutocomplete(Widget editor) {
    if (widget.completions.isEmpty || widget.readOnly) return editor;
    final prompts = [
      for (final completion in widget.completions)
        CodeFieldPrompt(
          word: completion.label,
          type: completion.detail ?? completion.type.name,
          customAutocomplete: CodeAutocompleteResult.fromWord(
            completion.apply ?? completion.label,
          ),
        ),
    ];
    return CodeAutocomplete(
      promptsBuilder: DefaultCodeAutocompletePromptsBuilder(
        language: _highlightMode(widget.language),
        directPrompts: prompts,
      ),
      viewBuilder: (context, notifier, onSelected) => _CompletionPanel(
        notifier: notifier,
        completions: widget.completions,
        maxWidth: Theme.of(
          context,
        ).extension<KDesignTokens>()!.componentPopoverMaxWidth,
        maxHeight: Theme.of(
          context,
        ).extension<KDesignTokens>()!.componentContextMenuWidth,
        onSelected: (prompt) {
          widget.onCompletionSelected?.call(
            widget.completions.firstWhere(
              (completion) => completion.label == prompt.word,
            ),
          );
          onSelected(prompt.autocomplete);
        },
      ),
      child: editor,
    );
  }
}

class _CompletionPanel extends StatelessWidget implements PreferredSizeWidget {
  const _CompletionPanel({
    required this.notifier,
    required this.completions,
    required this.maxWidth,
    required this.maxHeight,
    required this.onSelected,
  });

  final ValueNotifier<CodeAutocompleteEditingValue> notifier;
  final List<KCodeCompletion> completions;
  final double maxWidth;
  final double maxHeight;
  final ValueChanged<CodePrompt> onSelected;

  @override
  Size get preferredSize => Size(maxWidth, maxHeight);

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: notifier,
    builder: (context, value, _) {
      final t = Theme.of(context).extension<KDesignTokens>()!;
      return Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          padding: EdgeInsets.all(t.spaceTight),
          decoration: BoxDecoration(
            color: t.colorSurfaceRaised,
            border: Border.all(color: t.colorBorderDefault),
            borderRadius: BorderRadius.circular(t.radiusOverlay),
            boxShadow: t.elevationPopover,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: value.prompts.length,
            itemBuilder: (context, index) {
              final prompt = value.prompts[index];
              final completion = completions.firstWhere(
                (item) => item.label == prompt.word,
              );
              return KButton(
                label: completion.detail == null
                    ? completion.label
                    : '${completion.label}  ${completion.detail}',
                variant: index == value.index
                    ? KButtonVariant.primary
                    : KButtonVariant.ghost,
                fullWidth: true,
                onPressed: () => onSelected(prompt),
              );
            },
          ),
        ),
      );
    },
  );
}

class _DiagnosticBar extends StatelessWidget {
  const _DiagnosticBar({required this.items});
  final List<KCodeDiagnostic> items;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final first = items.first;
    final color = switch (first.severity) {
      KCodeDiagnosticSeverity.info => t.colorStatusInfoForeground,
      KCodeDiagnosticSeverity.warning => t.colorStatusWarningForeground,
      KCodeDiagnosticSeverity.error => t.colorStatusErrorForeground,
    };
    return Container(
      color: t.colorSurfaceRaised,
      padding: EdgeInsets.symmetric(
        horizontal: t.spaceSmallInset,
        vertical: t.spaceTight,
      ),
      child: Row(
        children: [
          KIcon(KIconName.circleAlert, size: t.sizeIconDefault, color: color),
          SizedBox(width: t.spaceControlGap),
          Expanded(
            child: Text(
              first.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: t.fontCaptionSize),
            ),
          ),
          if (items.length > 1)
            Text('+${items.length - 1}', style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _PresenceBar extends StatelessWidget {
  const _PresenceBar({required this.participants});
  final List<KEditorParticipant> participants;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Wrap(
      spacing: t.spaceTight,
      children: [
        for (final participant in participants)
          Tooltip(
            message: participant.name,
            child: Container(
              width: t.sizeIndicatorSmall,
              height: t.sizeIndicatorSmall,
              decoration: BoxDecoration(
                color: participant.color,
                shape: BoxShape.circle,
                border: Border.all(color: t.colorSurfaceCanvas),
              ),
            ),
          ),
      ],
    );
  }
}

KEditorSelection _clampSelection(KEditorSelection value, int length) =>
    KEditorSelection(
      anchor: value.anchor.clamp(0, length),
      head: value.head.clamp(0, length),
    );

CodeLineEditingValue _editingValue(String text, KEditorSelection selection) {
  final lines = text.split('\n');
  CodeLinePosition position(int offset) {
    var remaining = offset.clamp(0, text.length);
    for (var index = 0; index < lines.length; index++) {
      if (remaining <= lines[index].length) {
        return CodeLinePosition(index: index, offset: remaining);
      }
      remaining -= lines[index].length + 1;
    }
    return CodeLinePosition(index: lines.length - 1, offset: lines.last.length);
  }

  final anchor = position(selection.anchor);
  final head = position(selection.head);
  return CodeLineEditingValue(
    codeLines: CodeLines.fromText(text),
    selection: CodeLineSelection(
      baseIndex: anchor.index,
      baseOffset: anchor.offset,
      extentIndex: head.index,
      extentOffset: head.offset,
    ),
  );
}

KEditorSelection _globalSelection(CodeLineEditingController controller) {
  int offset(CodeLinePosition position) {
    var result = 0;
    for (var index = 0; index < position.index; index++) {
      result +=
          controller.codeLines[index].asString(0, TextLineBreak.lf).length + 1;
    }
    return result + position.offset;
  }

  return KEditorSelection(
    anchor: offset(controller.selection.base),
    head: offset(controller.selection.extent),
  );
}

CodeHighlightTheme? _codeTheme(
  KDesignTokens t,
  KCodeLanguage language, {
  bool embedded = false,
}) {
  final mode = _highlightMode(language);
  if (mode == null) return null;
  return CodeHighlightTheme(
    languages: {language.name: CodeHighlightThemeMode(mode: mode)},
    theme: {
      'comment': TextStyle(color: t.colorSyntaxComment),
      'quote': TextStyle(color: t.colorSyntaxComment),
      'keyword': TextStyle(color: t.colorSyntaxKeyword),
      'selector-tag': TextStyle(color: t.colorSyntaxKeyword),
      'string': TextStyle(color: t.colorSyntaxString),
      'attribute': TextStyle(color: t.colorSyntaxString),
      'number': TextStyle(color: t.colorSyntaxNumber),
      'literal': TextStyle(color: t.colorSyntaxNumber),
      'title': TextStyle(
        color: t.colorSyntaxHeading,
        fontWeight: t.fontHeadingWeight,
      ),
      'section': TextStyle(
        color: t.colorSyntaxHeading,
        fontWeight: t.fontHeadingWeight,
        fontSize: embedded ? t.fontBodySmallSize * 1.2 : null,
      ),
      'bullet': TextStyle(color: t.colorSyntaxMarkup),
      'meta': TextStyle(color: t.colorSyntaxMarkup),
      'link': TextStyle(color: t.colorSyntaxLink),
      'code': TextStyle(color: t.colorSyntaxCode),
      'symbol': TextStyle(color: t.colorSyntaxSymbol),
      'operator': TextStyle(color: t.colorSyntaxSymbol),
    },
  );
}

Mode? _highlightMode(KCodeLanguage language) => switch (language) {
  KCodeLanguage.javascript => langJavascript,
  KCodeLanguage.typescript => langTypescript,
  KCodeLanguage.json => langJson,
  KCodeLanguage.markdown => langMarkdown,
  KCodeLanguage.plain => null,
};
