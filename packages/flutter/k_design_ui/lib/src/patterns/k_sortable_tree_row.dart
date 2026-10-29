part of 'k_sortable_tree.dart';

extension _SortableTreeRows<T> on _KSortableTreeState<T> {
  Widget row(
    KSortableTreeEntry<T> e,
    double width,
    double height, {
    bool feedback = false,
    bool fixed = false,
  }) {
    final category = e.node.children != null;
    final open = fixed ? _ungroupedOpen : expanded.contains(e.node.id);
    void toggleRow() {
      if (fixed) {
        toggleUngrouped();
      } else {
        toggle(e.node.id);
      }
    }

    final c = KSortableTreeContext(
      node: e.node,
      depth: e.depth,
      expanded: open,
      toggleExpanded: toggleRow,
    );
    final body =
        widget.renderContent?.call(context, c) ??
        KText(e.node.label, variant: KTextVariant.bodySmall);
    Widget handle = KIconButton(
      label:
          '${fixed ? (open ? widget.labels.collapse : widget.labels.expand) : widget.labels.drag}: ${e.node.label}',
      icon: fixed ? KIconName.folder : KIconName.gripVertical,
      iconContent: KIcon(
        fixed ? KIconName.folder : KIconName.gripVertical,
        strokeWidth: 1.5,
      ),
      selected: false,
      onPressed: widget.disabled
          ? null
          : category
          ? toggleRow
          : () {},
    );
    handle = DecoratedBox(
      decoration: BoxDecoration(
        color: category && open ? t.colorSurfaceRaised : null,
        borderRadius: BorderRadius.circular(t.radiusControl),
      ),
      child: handle,
    );
    if (!feedback && !fixed && !widget.disabled) {
      handle = Focus(
        onKeyEvent: (_, event) => handleKey(e, event),
        child: LongPressDraggable<String>(
          data: e.node.id,
          delay: const Duration(milliseconds: 300),
          maxSimultaneousDrags: 1,
          dragAnchorStrategy: (_, _, position) {
            final box =
                _rowKeys[e.node.id]?.currentContext?.findRenderObject()
                    as RenderBox?;
            return box?.globalToLocal(position) ?? Offset.zero;
          },
          feedback: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: width,
              child: row(e, width, height, feedback: true),
            ),
          ),
          onDragStarted: () => dragStart(e.node.id),
          onDragUpdate: (details) => _dragPosition = details.globalPosition,
          onDragEnd: (_) => dragEnd(),
          child: handle,
        ),
      );
    }
    Widget content = Container(
      key: feedback ? null : _rowKeys.putIfAbsent(e.node.id, GlobalKey.new),
      constraints: BoxConstraints(minHeight: height),
      padding: EdgeInsets.symmetric(
        horizontal: t.spaceControlInsetInline,
        vertical: t.spaceControlGap,
      ),
      decoration: BoxDecoration(
        color: category
            ? t.colorSurfaceSubtle
            : feedback
            ? t.colorSurfaceRaised
            : null,
      ),
      child: Row(
        children: [
          handle,
          SizedBox(width: t.spaceControlGap),
          Expanded(child: body),
          SizedBox(width: t.spaceControlGap),
          if (!fixed && widget.renderActions != null)
            widget.renderActions!(context, c),
          if (!fixed)
            KMenuButton(
              label: '${widget.labels.move}: ${e.node.label}',
              overflow: true,
              alignEnd: true,
              triggerContent: const KIcon(KIconName.ellipsis, strokeWidth: 1.5),
              disabled: widget.disabled || feedback,
              actions: actions(e, c),
            ),
        ],
      ),
    );
    if (!feedback && category) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.disabled ? null : toggleRow,
        child: content,
      );
    }
    if (!feedback && category) {
      content = drop(
        parent: fixed ? null : e.node.id,
        index: fixed ? widget.nodes.length : e.node.children!.length,
        inside: true,
        child: content,
      );
    }
    // Paint drop feedback above the category surface; never change text colors.
    if (!feedback && !fixed) {
      content = Stack(
        children: [
          content,
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: t.spaceControlGap,
            child: drop(
              parent: e.parentId,
              index: e.index,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      );
    }
    return category ? Semantics(expanded: open, child: content) : content;
  }
}
