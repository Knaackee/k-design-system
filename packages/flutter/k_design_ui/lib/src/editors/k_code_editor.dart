import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/re_highlight.dart' show Mode;
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/typescript.dart';

import '../actions/k_icon_button.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import 'k_editor_search_panel.dart';
import 'k_editor_types.dart';

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
    super.key,
  });

  final String value;
  final void Function(String value, KEditorTransaction transaction)? onChanged;
  final ValueChanged<KEditorSelection>? onSelectionChanged;
  final KCodeLanguage language;
  final bool readOnly;
  final String? placeholder;
  final bool showLineNumbers;
  final bool lineWrapping;
  final bool showSearchButton;
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

  @override
  State<KCodeEditor> createState() => KCodeEditorState();
}

class KCodeEditorState extends State<KCodeEditor> {
  late CodeLineEditingController _controller;
  late CodeFindController _findController;
  late FocusNode _focusNode;
  KEditorSelection _selection = const KEditorSelection(anchor: 0, head: 0);
  bool _searchOpen = false;
  bool _applyingExternal = false;

  String get value => _controller.text;
  KEditorSelection get selection => _selection;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController(
      codeLines: CodeLines.fromText(_effectiveValue),
      spanBuilder: _buildCollaborativeTextSpan,
    );
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

  @override
  void didUpdateWidget(covariant KCodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collaborationAdapter != widget.collaborationAdapter) {
      oldWidget.collaborationAdapter?.snapshot.removeListener(
        _handleCollaboration,
      );
      widget.collaborationAdapter?.snapshot.addListener(_handleCollaboration);
    }
    if (_effectiveValue != _controller.text) {
      _replaceExternalValue(_effectiveValue);
    } else if (oldWidget.remoteSelections != widget.remoteSelections) {
      _controller.forceRepaint();
    }
  }

  @override
  void dispose() {
    widget.collaborationAdapter?.snapshot.removeListener(_handleCollaboration);
    _controller.removeListener(_handleController);
    _controller.dispose();
    _findController.dispose();
    _focusNode
      ..removeListener(_handleFocus)
      ..dispose();
    super.dispose();
  }

  void focus() => _focusNode.requestFocus();

  void undo() => _controller.undo();

  void redo() => _controller.redo();

  void replaceRange(
    int from,
    int to,
    String insert, {
    KEditorSelection? selection,
  }) {
    final source = _controller.text;
    final safeFrom = from.clamp(0, source.length);
    final safeTo = to.clamp(safeFrom, source.length);
    final next = source.replaceRange(safeFrom, safeTo, insert);
    final nextSelection =
        selection ??
        KEditorSelection(
          anchor: safeFrom + insert.length,
          head: safeFrom + insert.length,
        );
    _controller.value = _editingValue(next, nextSelection);
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
    if (snapshot.value != _controller.text) {
      _replaceExternalValue(snapshot.value, snapshot.selection);
    } else if (mounted) {
      _controller.forceRepaint();
      setState(() {});
    }
  }

  TextSpan _buildCollaborativeTextSpan({
    required BuildContext context,
    required int index,
    required CodeLine codeLine,
    required TextSpan textSpan,
    required TextStyle style,
  }) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final selections = _effectiveRemoteSelections;
    if (selections.isEmpty) return textSpan;

    var lineStart = 0;
    for (var line = 0; line < index; line++) {
      lineStart += _controller.codeLines[line].length + 1;
    }
    final lineEnd = lineStart + codeLine.text.length;
    final relevant = selections
        .where(
          (selection) => selection.isCollapsed
              ? selection.start >= lineStart && selection.start <= lineEnd
              : selection.end > lineStart && selection.start < lineEnd,
        )
        .toList(growable: false);
    if (relevant.isEmpty) return textSpan;

    InlineSpan caret(KRemoteSelection selection) => WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Tooltip(
        message: selection.participant.name,
        child: Semantics(
          label: '${selection.participant.name} cursor',
          child: Container(
            width: t.borderWidthStrong,
            height: t.fontBodyLineHeight,
            color: selection.participant.color,
          ),
        ),
      ),
    );

    if (codeLine.text.isEmpty) {
      return TextSpan(
        style: style,
        children: [
          for (final selection in relevant.where(
            (selection) => selection.isCollapsed,
          ))
            caret(selection),
        ],
      );
    }

    final runs = <_StyledRun>[];
    _flattenSpan(textSpan, style, runs);
    final children = <InlineSpan>[];
    var localOffset = 0;
    for (final run in runs) {
      final runStart = localOffset;
      final runEnd = runStart + run.text.length;
      final cuts = <int>{runStart, runEnd};
      for (final selection in relevant) {
        cuts
          ..add((selection.start - lineStart).clamp(runStart, runEnd))
          ..add((selection.end - lineStart).clamp(runStart, runEnd));
      }
      final boundaries = cuts.toList()..sort();
      for (var part = 0; part < boundaries.length; part++) {
        final from = boundaries[part];
        for (final selection in relevant.where(
          (selection) =>
              selection.isCollapsed && selection.start - lineStart == from,
        )) {
          children.add(caret(selection));
        }
        if (part == boundaries.length - 1) break;
        final to = boundaries[part + 1];
        if (to <= from) continue;
        final absolute = lineStart + from;
        KRemoteSelection? active;
        for (final selection in relevant) {
          if (!selection.isCollapsed &&
              selection.start <= absolute &&
              selection.end > absolute) {
            active = selection;
            break;
          }
        }
        children.add(
          TextSpan(
            text: run.text.substring(from - runStart, to - runStart),
            style: active == null
                ? run.style
                : run.style.copyWith(
                    backgroundColor: active.participant.color.withValues(
                      alpha: t.opacityMedium,
                    ),
                  ),
          ),
        );
      }
      localOffset = runEnd;
    }
    return TextSpan(style: style, children: children);
  }

  void _replaceExternalValue(String next, [KEditorSelection? nextSelection]) {
    _applyingExternal = true;
    _controller.value = _editingValue(
      next,
      nextSelection ?? _clampSelection(_selection, next.length),
    );
    _applyingExternal = false;
  }

  void _handleController() {
    final nextSelection = _globalSelection(_controller);
    if (nextSelection != _selection) {
      _selection = nextSelection;
      widget.onSelectionChanged?.call(nextSelection);
    }
  }

  void _handleChanged(CodeLineEditingValue _) {
    if (_applyingExternal) return;
    _emitLocalTransaction();
  }

  void _emitLocalTransaction() {
    final transaction = KEditorTransaction(
      value: _controller.text,
      selection: _selection,
      origin: KEditorTransactionOrigin.local,
    );
    widget.onChanged?.call(transaction.value, transaction);
    widget.collaborationAdapter?.applyLocalTransaction(transaction);
  }

  @override
  Widget build(BuildContext context) {
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
                color: t.colorSurfaceCanvas,
                border: Border.all(color: t.colorBorderDefault),
                borderRadius: BorderRadius.circular(t.radiusCard),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(t.radiusCard),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _withAutocomplete(
                        CodeEditor(
                          controller: _controller,
                          findController: _findController,
                          focusNode: _focusNode,
                          onChanged: _handleChanged,
                          readOnly: widget.readOnly,
                          wordWrap: widget.lineWrapping,
                          hint: widget.placeholder,
                          autofocus: false,
                          padding: EdgeInsets.fromLTRB(
                            t.spaceMediumInset,
                            widget.showSearchButton
                                ? t.sizeHitTarget + t.spaceSmallInset
                                : t.spaceMediumInset,
                            t.spaceMediumInset,
                            widget.diagnostics.isEmpty
                                ? t.spaceMediumInset
                                : t.sizeHitTarget,
                          ),
                          style: CodeEditorStyle(
                            fontFamily: widget.fontFamily,
                            fontFamilyFallback: widget.fontFamilyFallback,
                            fontSize: t.fontBodySize,
                            fontHeight: t.fontRelaxedHeight,
                            textColor: t.colorTextPrimary,
                            hintTextColor: t.colorTextMuted,
                            backgroundColor: t.colorSurfaceCanvas,
                            cursorColor: t.colorBorderFocus,
                            selectionColor: t.colorBrandPrimaryBackground,
                            highlightColor: t.colorBrandSecondaryBackground,
                            codeTheme: _codeTheme(t, widget.language),
                          ),
                          indicatorBuilder: widget.showLineNumbers
                              ? (context, editing, chunk, notifier) =>
                                    DefaultCodeLineNumber(
                                      controller: editing,
                                      notifier: notifier,
                                      textStyle: TextStyle(
                                        color: t.colorTextMuted,
                                        fontFamily: widget.fontFamily,
                                        fontFamilyFallback:
                                            widget.fontFamilyFallback,
                                        fontSize: t.fontCaptionSize,
                                      ),
                                    )
                              : null,
                          leadingDivider: widget.showLineNumbers
                              ? VerticalDivider(
                                  width: t.spaceSmallInset,
                                  color: t.colorBorderDefault,
                                )
                              : null,
                          border: null,
                          borderRadius: BorderRadius.circular(t.radiusCard),
                        ),
                      ),
                    ),
                    if (widget.showSearchButton)
                      PositionedDirectional(
                        top: t.spaceControlGap,
                        end: widget.searchButtonEndInset ?? t.spaceControlGap,
                        child: KIconButton(
                          label: widget.labels.search,
                          icon: KIconName.search,
                          selected: _searchOpen,
                          onPressed: () {
                            setState(() => _searchOpen = !_searchOpen);
                            if (!_searchOpen) {
                              _findController.close();
                              focus();
                            }
                          },
                        ),
                      ),
                    if (_searchOpen)
                      PositionedDirectional(
                        bottom: widget.diagnostics.isEmpty
                            ? 0
                            : t.sizeHitTarget,
                        end: 0,
                        start: 0,
                        child: KEditorSearchPanel(
                          controller: _findController,
                          labels: widget.labels,
                          readOnly: widget.readOnly,
                          onClose: () {
                            setState(() => _searchOpen = false);
                            focus();
                          },
                        ),
                      ),
                    if (widget.diagnostics.isNotEmpty)
                      PositionedDirectional(
                        start: 0,
                        end: 0,
                        bottom: 0,
                        child: _DiagnosticBar(items: widget.diagnostics),
                      ),
                    if (_effectiveRemoteSelections.isNotEmpty)
                      PositionedDirectional(
                        start: t.spaceSmallInset,
                        bottom: widget.diagnostics.isEmpty
                            ? t.spaceSmallInset
                            : t.sizeHitTarget,
                        child: _PresenceBar(
                          selections: _effectiveRemoteSelections,
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

class _StyledRun {
  const _StyledRun(this.text, this.style);
  final String text;
  final TextStyle style;
}

void _flattenSpan(TextSpan span, TextStyle inherited, List<_StyledRun> output) {
  final effective = inherited.merge(span.style);
  if (span.text case final text? when text.isNotEmpty) {
    output.add(_StyledRun(text, effective));
  }
  for (final child in span.children ?? const <InlineSpan>[]) {
    if (child is TextSpan) _flattenSpan(child, effective, output);
  }
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
  const _PresenceBar({required this.selections});
  final List<KRemoteSelection> selections;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Wrap(
      spacing: t.spaceTight,
      children: [
        for (final selection in selections)
          Tooltip(
            message: selection.participant.name,
            child: Container(
              width: t.sizeIndicatorSmall,
              height: t.sizeIndicatorSmall,
              decoration: BoxDecoration(
                color: selection.participant.color,
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
      result += controller.codeLines[index].length + 1;
    }
    return result + position.offset;
  }

  return KEditorSelection(
    anchor: offset(controller.selection.base),
    head: offset(controller.selection.extent),
  );
}

CodeHighlightTheme? _codeTheme(KDesignTokens t, KCodeLanguage language) {
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
