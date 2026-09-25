import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:re_editor/re_editor.dart';

import '../actions/k_icon_button.dart';
import '../forms/k_checkbox.dart';
import '../forms/k_input.dart';
import '../primitives/k_button.dart';
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
  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _close() {
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
    final index = value.result?.index ?? -1;
    final resultLabel = matches == 0
        ? widget.labels.noResults
        : '${index + 1} / $matches';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(t.spaceSmallInset),
        decoration: BoxDecoration(
          color: t.colorSurfaceRaised,
          border: Border(top: BorderSide(color: t.colorBorderDefault)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: KSearchField(
                    controller: widget.controller.findInputController,
                    focusNode: widget.controller.findInputFocusNode,
                    placeholder: widget.labels.searchFind,
                    label: widget.labels.searchFind,
                  ),
                ),
                SizedBox(width: t.spaceControlGap),
                Text(
                  resultLabel,
                  style: TextStyle(
                    color: t.colorTextMuted,
                    fontFamily: t.fontFamily,
                    fontSize: t.fontCaptionSize,
                  ),
                ),
                KIconButton(
                  label: widget.labels.searchPrevious,
                  icon: KIconName.chevronUp,
                  onPressed: matches == 0
                      ? null
                      : widget.controller.previousMatch,
                ),
                KIconButton(
                  label: widget.labels.searchNext,
                  icon: KIconName.chevronDown,
                  onPressed: matches == 0 ? null : widget.controller.nextMatch,
                ),
                KIconButton(
                  label: widget.labels.searchClose,
                  icon: KIconName.x,
                  onPressed: _close,
                ),
              ],
            ),
            SizedBox(height: t.spaceControlGap),
            Wrap(
              spacing: t.spaceContentActionGap,
              runSpacing: t.spaceTight,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                KCheckbox(
                  label: widget.labels.searchMatchCase,
                  value: value.option.caseSensitive,
                  onChanged: (_) => widget.controller.toggleCaseSensitive(),
                ),
                KCheckbox(
                  label: widget.labels.searchRegexp,
                  value: value.option.regex,
                  onChanged: (_) => widget.controller.toggleRegex(),
                ),
                if (!widget.readOnly)
                  KButton(
                    label: widget.labels.searchShowReplace,
                    variant: value.replaceMode
                        ? KButtonVariant.primary
                        : KButtonVariant.ghost,
                    leading: const KIcon(KIconName.refreshCw),
                    onPressed: widget.controller.toggleMode,
                  ),
              ],
            ),
            if (value.replaceMode && !widget.readOnly) ...[
              SizedBox(height: t.spaceControlGap),
              KInput(
                controller: widget.controller.replaceInputController,
                focusNode: widget.controller.replaceInputFocusNode,
                placeholder: widget.labels.searchReplace,
                label: widget.labels.searchReplace,
              ),
              SizedBox(height: t.spaceControlGap),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: t.spaceControlGap,
                runSpacing: t.spaceControlGap,
                children: [
                  KButton(
                    label: widget.labels.searchReplace,
                    variant: KButtonVariant.secondary,
                    onPressed: matches == 0
                        ? null
                        : widget.controller.replaceMatch,
                  ),
                  KButton(
                    label: widget.labels.searchReplaceAll,
                    variant: KButtonVariant.secondary,
                    onPressed: matches == 0
                        ? null
                        : widget.controller.replaceAllMatches,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
