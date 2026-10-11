import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:re_editor/re_editor.dart';

import '../actions/k_icon_button.dart';
import '../forms/k_input.dart';
import '../primitives/k_icon.dart';
import 'k_editor_types.dart';

class KEditorSearchPanel extends StatefulWidget {
  const KEditorSearchPanel({
    required this.controller,
    required this.labels,
    required this.onClose,
    this.readOnly = false,
    super.key,
  });

  final CodeFindController controller;
  final KEditorLabels labels;
  final VoidCallback onClose;
  final bool readOnly;

  @override
  State<KEditorSearchPanel> createState() => _KEditorSearchPanelState();
}

class _KEditorSearchPanelState extends State<KEditorSearchPanel> {
  late final TextEditingController _query;
  bool _wholeWord = false;
  bool _regex = false;

  void _syncQuery() {
    final controller = widget.controller;
    final useRegex = _regex || _wholeWord;
    if ((controller.value?.option.regex ?? false) != useRegex) {
      controller.toggleRegex();
    }
    final text = _query.text;
    controller.findInputController.text = _wholeWord && text.isNotEmpty
        ? r'\b(?:' + (_regex ? text : RegExp.escape(text)) + r')\b'
        : text;
  }

  @override
  void initState() {
    super.initState();
    _regex = widget.controller.value?.option.regex ?? false;
    _query = TextEditingController(
      text: widget.controller.findInputController.text,
    );
    _query.addListener(_syncQuery);
    widget.controller.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.findMode();
      widget.controller.focusOnFindInput();
    });
  }

  @override
  void didUpdateWidget(covariant KEditorSearchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller.removeListener(_refresh);
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    _query.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _close() {
    widget.controller.findInputController.text = _query.text;
    widget.controller.close();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final value = widget.controller.value ?? const CodeFindValue.empty();
    final matches = value.result?.matches.length ?? 0;

    final count = matches == 0
        ? widget.labels.noResults
        : '${(value.result?.index ?? -1) + 1} / $matches';
    Widget options() => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KIconButton(
          icon: KIconName.caseSensitive,
          label: widget.labels.searchMatchCase,
          selected: value.option.caseSensitive,
          onPressed: widget.controller.toggleCaseSensitive,
        ),
        KIconButton(
          icon: KIconName.wholeWord,
          label: widget.labels.searchWholeWord,
          selected: _wholeWord,
          onPressed: () {
            setState(() => _wholeWord = !_wholeWord);
            _syncQuery();
          },
        ),
        KIconButton(
          icon: KIconName.regex,
          label: widget.labels.searchRegexp,
          selected: _regex,
          onPressed: () {
            setState(() => _regex = !_regex);
            _syncQuery();
          },
        ),
      ],
    );
    Widget line(Widget input, List<Widget> actions, bool compact) {
      final controls = Row(mainAxisSize: MainAxisSize.min, children: actions);
      return compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                input,
                Align(alignment: Alignment.centerRight, child: controls),
              ],
            )
          : Row(
              spacing: t.spaceControlGap,
              children: [
                Expanded(child: input),
                controls,
              ],
            );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(t.spaceSmallInset),
      decoration: BoxDecoration(
        color: t.colorSurfaceRaised,
        border: Border(bottom: BorderSide(color: t.colorBorderDefault)),
      ),
      child: LayoutBuilder(
        builder: (context, bounds) {
          final compact = bounds.maxWidth < 500;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: t.spaceTight,
            children: [
              if (!widget.readOnly)
                KIconButton(
                  icon: value.replaceMode
                      ? KIconName.chevronDown
                      : KIconName.chevronRight,
                  label: widget.labels.searchShowReplace,
                  selected: value.replaceMode,
                  onPressed: widget.controller.toggleMode,
                ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: t.spaceTight,
                  children: [
                    line(
                      KInput(
                        controller: _query,
                        focusNode: widget.controller.findInputFocusNode,
                        placeholder: widget.labels.searchFind,
                        label: widget.labels.searchFind,
                        trailingAction: options(),
                        trailingActionWidth:
                            3 *
                            (t.sizeControl > t.sizeHitTarget
                                ? t.sizeControl
                                : t.sizeHitTarget),
                        onSubmitted: (_) => widget.controller.nextMatch(),
                      ),
                      [
                        SizedBox(
                          width: t.componentEditorSearchCounterWidth,
                          child: Text(
                            count,
                            style: TextStyle(
                              color: t.colorTextMuted,
                              fontFamily: t.fontFamily,
                              fontSize: t.fontCaptionSize,
                            ),
                          ),
                        ),
                        KIconButton(
                          icon: KIconName.arrowUp,
                          label: widget.labels.searchPrevious,
                          onPressed: matches == 0
                              ? null
                              : widget.controller.previousMatch,
                        ),
                        KIconButton(
                          icon: KIconName.arrowDown,
                          label: widget.labels.searchNext,
                          onPressed: matches == 0
                              ? null
                              : widget.controller.nextMatch,
                        ),
                        KIconButton(
                          icon: KIconName.x,
                          label: widget.labels.searchClose,
                          onPressed: _close,
                        ),
                      ],
                      compact,
                    ),
                    if (value.replaceMode && !widget.readOnly)
                      line(
                        KInput(
                          controller: widget.controller.replaceInputController,
                          focusNode: widget.controller.replaceInputFocusNode,
                          placeholder: widget.labels.searchReplace,
                          label: widget.labels.searchReplace,
                          onSubmitted: (_) => widget.controller.replaceMatch(),
                        ),
                        [
                          KIconButton(
                            icon: KIconName.replace,
                            label: widget.labels.searchReplace,
                            onPressed: matches == 0
                                ? null
                                : widget.controller.replaceMatch,
                          ),
                          KIconButton(
                            icon: KIconName.replaceAll,
                            label: widget.labels.searchReplaceAll,
                            onPressed: matches == 0
                                ? null
                                : widget.controller.replaceAllMatches,
                          ),
                        ],
                        compact,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
