part of 'k_markdown_editor.dart';

extension _MarkdownEditorSurface on KMarkdownEditorState {
  Widget _buildAccessibleSurface(BuildContext context) => ExcludeSemantics(
    excluding: _movingSurface,
    child: _buildSurface(context),
  );

  Widget _buildSurface(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    // Only the source editor is reparented. Recreate toolbar tooltips in their
    // new overlay instead of moving an active Tooltip OverlayPortal.
    return LayoutBuilder(
      builder: (context, constraints) {
        final editing = _mode == KEditorMode.source;
        final showFixedToolbar = widget.showFixedToolbar || _expanded;
        final expandClearance = widget.showExpandButton
            ? math.max(t.sizeHitTarget, t.sizeControl) + t.spaceControlGap * 2
            : 0.0;
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
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: IndexedStack(
                              index: editing ? 0 : 1,
                              sizing: StackFit.expand,
                              children: [
                                ExcludeFocus(
                                  excluding: !editing,
                                  child: KMarkdownSourceGeometry(
                                    // Extra scrollable room at the document end,
                                    // above the floating editor action.
                                    bottomInset:
                                        expandClearance +
                                        (widget.showExpandButton
                                            ? t.spaceSmallInset
                                            : 0),
                                    scrollController: _scrollController,
                                    paragraphs: _paragraphs,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: KCodeEditor(
                                            key: _editorKey,
                                            value: _effectiveDraft,
                                            onChanged: _changeSource,
                                            onSelectionChanged:
                                                _updateSelection,
                                            language: KCodeLanguage.markdown,
                                            readOnly: widget.readOnly,
                                            placeholder: widget.placeholder,
                                            showLineNumbers: false,
                                            lineWrapping: true,
                                            showSearchButton:
                                                widget.showSearchButton,
                                            contentMaxWidth:
                                                widget.contentMaxWidth,
                                            searchButtonEndInset:
                                                widget.showModeSwitcher
                                                ? t.sizeHitTarget +
                                                      t.spaceControlGap * 2
                                                : null,
                                            labels: widget.labels,
                                            remoteSelections:
                                                widget.remoteSelections,
                                            collaborationAdapter:
                                                widget.collaborationAdapter,
                                            semanticLabel: widget.semanticLabel,
                                            minHeight: widget.minHeight,
                                            onFocus: widget.onFocus,
                                            onBlur: widget.onBlur,
                                            dictationState:
                                                widget.dictationState,
                                            dictationOffset:
                                                widget.dictationOffset ??
                                                _dictationSelection?.start ??
                                                selection.start,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                _MarkdownPreview(
                                  initialScrollOffset: _previewScrollOffset,
                                  onScrollOffsetChanged: (offset) =>
                                      _previewScrollOffset = offset,
                                  markdown: _effectiveDraft,
                                  semanticLabel:
                                      '${widget.semanticLabel} preview',
                                  contentMaxWidth: widget.contentMaxWidth,
                                  imageBuilder: widget.imageBuilder,
                                  markdownOptions: widget.markdownOptions,
                                  onLinkPressed: widget.onLinkPressed,
                                  bottomInset: expandClearance,
                                  topInset: widget.showModeSwitcher
                                      ? t.sizeHitTarget + t.spaceSmallInset
                                      : t.spaceMediumInset,
                                ),
                              ],
                            ),
                          ),
                          if (widget.showExpandButton)
                            PositionedDirectional(
                              bottom: t.spaceControlGap,
                              end: t.spaceControlGap,
                              child: CodeEditorTapRegion(
                                child: KIconButton(
                                  label: _expanded
                                      ? widget.collapseLabel
                                      : widget.expandLabel,
                                  variant: KButtonVariant.secondary,
                                  icon: _expanded
                                      ? KIconName.minimize2
                                      : KIconName.maximize2,
                                  onPressed: _toggleExpanded,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if ((showFixedToolbar ||
                            (!widget.showExpandButton &&
                                widget.dictationState != null)) &&
                        editing &&
                        !widget.readOnly)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.all(t.spaceControlGap),
                          child: KEditorFormatBar(
                            labels: widget.labels,
                            actions: showFixedToolbar
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
