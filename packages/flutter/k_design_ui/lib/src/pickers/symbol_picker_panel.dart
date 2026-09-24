part of 'k_symbol_picker.dart';

class _SymbolPicker extends StatefulWidget {
  const _SymbolPicker({
    required this.items,
    required this.searchFocus,
    required this.onSelect,
    required this.value,
    required this.recentIds,
    required this.labels,
    required this.categoryLabels,
    required this.itemBuilder,
    required this.enabled,
    required this.onDismiss,
    required this.width,
    required this.height,
    this.accessory,
  });
  final List<KSymbolItem> items;
  final FocusNode searchFocus;
  final ValueChanged<KSymbolItem> onSelect;
  final String? value;
  final List<String> recentIds;
  final KSymbolPickerLabels labels;
  final Map<String, String> categoryLabels;
  final KSymbolItemBuilder itemBuilder;
  final bool enabled;
  final VoidCallback? onDismiss;
  final double width, height;
  final Widget? accessory;
  @override
  State<_SymbolPicker> createState() => _SymbolPickerState();
}

class _SymbolPickerState extends State<_SymbolPicker> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _categoryScroll = ScrollController();
  String _query = '', _category = '';
  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    _categoryScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final labels = widget.labels;
    final categories = widget.items.map((i) => i.category).toSet();
    final tabs = <String, String>{
      '': labels.all,
      if (widget.recentIds.isNotEmpty) '__recent': labels.recent,
      for (final category in categories)
        category: widget.categoryLabels[category] ?? category,
    };
    final q = _query.trim().toLowerCase();
    final source = q.isEmpty && _category == '__recent'
        ? widget.recentIds.expand(
            (id) => widget.items.where((item) => item.id == id),
          )
        : widget.items;
    final visible = source
        .where(
          (item) => q.isNotEmpty
              ? [
                  item.label,
                  ...item.keywords,
                ].any((word) => word.toLowerCase().contains(q))
              : _category.isEmpty ||
                    _category == '__recent' ||
                    item.category == _category,
        )
        .toList();
    final scrollBehavior = ScrollConfiguration.of(context).copyWith(
      dragDevices: {
        ...ScrollConfiguration.of(context).dragDevices,
        PointerDeviceKind.mouse,
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
      },
    );
    Widget button(
      String label,
      Widget child,
      VoidCallback? action, {
      bool selected = false,
    }) => _SymbolPickerCell(
      label: label,
      selected: selected,
      onPressed: action,
      child: child,
    );
    return Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onDismiss?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: KSurface(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(
                  tokens.componentSymbolPickerPanelPadding,
                ),
                child: KInput(
                  focusNode: widget.searchFocus,
                  controller: _search,
                  label: labels.search,
                  placeholder: labels.searchPlaceholder ?? labels.search,
                  clearLabel: labels.clearSearch,
                  enabled: widget.enabled,
                  clearable: true,
                  onChanged: (value) => setState(() {
                    _query = value;
                  }),
                ),
              ),
              Container(
                height:
                    tokens.componentSymbolPickerFooterMinHeight +
                    tokens.borderWidthDefault,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: tokens.colorBorderDefault),
                  ),
                ),
                child: ScrollConfiguration(
                  behavior: scrollBehavior,
                  child: Scrollbar(
                    controller: _categoryScroll,
                    thumbVisibility: true,
                    scrollbarOrientation: ScrollbarOrientation.bottom,
                    child: ListView(
                      controller: _categoryScroll,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.fromLTRB(
                        tokens.componentSymbolPickerPanelPadding,
                        0,
                        tokens.componentSymbolPickerPanelPadding,
                        tokens.componentSymbolPickerPanelPadding,
                      ),
                      children: [
                        for (final tab in tabs.entries)
                          Padding(
                            padding: EdgeInsets.only(right: tokens.spaceTight),
                            child: button(
                              tab.value,
                              SizedBox(
                                width: tokens.componentSymbolPickerCellSize,
                                child: tab.key.isEmpty
                                    ? const KIcon(KIconName.search)
                                    : tab.key == '__recent'
                                    ? const KIcon(KIconName.clock)
                                    : widget.itemBuilder(
                                        context,
                                        widget.items.firstWhere(
                                          (item) => item.category == tab.key,
                                        ),
                                      ),
                              ),
                              widget.enabled
                                  ? () => setState(() {
                                      _category = tab.key;
                                      _search.clear();
                                      _query = '';
                                      if (_scroll.hasClients) _scroll.jumpTo(0);
                                    })
                                  : null,
                              selected: _category == tab.key,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(child: KText(labels.empty))
                    : LayoutBuilder(
                        builder: (context, constraints) => FocusTraversalGroup(
                          child: ScrollConfiguration(
                            behavior: scrollBehavior,
                            child: Scrollbar(
                              controller: _scroll,
                              child: GridView.builder(
                                controller: _scroll,
                                // SVG decoding is comparatively expensive. Build
                                // glyphs as they enter this small menu viewport.
                                scrollCacheExtent:
                                    const ScrollCacheExtent.pixels(0),
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      tokens.componentSymbolPickerPanelPadding,
                                  vertical: tokens.spaceControlGap,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          ((constraints.maxWidth -
                                                      tokens.sizeIconDefault) /
                                                  tokens
                                                      .componentSymbolPickerCellSize)
                                              .floor()
                                              .clamp(1, 100),
                                      mainAxisExtent:
                                          tokens.componentSymbolPickerCellSize,
                                    ),
                                itemCount: visible.length,
                                itemBuilder: (context, index) {
                                  final item = visible[index];
                                  return Focus(
                                    onKeyEvent: (_, event) {
                                      if (event is! KeyDownEvent) {
                                        return KeyEventResult.ignored;
                                      }
                                      final direction = {
                                        LogicalKeyboardKey.arrowLeft:
                                            TraversalDirection.left,
                                        LogicalKeyboardKey.arrowRight:
                                            TraversalDirection.right,
                                        LogicalKeyboardKey.arrowUp:
                                            TraversalDirection.up,
                                        LogicalKeyboardKey.arrowDown:
                                            TraversalDirection.down,
                                      }[event.logicalKey];
                                      if (direction == null) {
                                        return KeyEventResult.ignored;
                                      }
                                      FocusScope.of(
                                        context,
                                      ).focusInDirection(direction);
                                      return KeyEventResult.handled;
                                    },
                                    child: button(
                                      item.label,
                                      widget.itemBuilder(context, item),
                                      widget.enabled && !item.disabled
                                          ? () => widget.onSelect(item)
                                          : null,
                                      selected: widget.value == item.id,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              if (widget.accessory != null)
                Container(
                  height: tokens.componentSymbolPickerFooterMinHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.componentSymbolPickerPanelPadding,
                    vertical: tokens.spaceControlGap,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: tokens.colorBorderDefault),
                    ),
                  ),
                  child: Row(children: [const Spacer(), widget.accessory!]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// A symbol grid does not need a separate Material surface and ink animation
// for every cell. Keep hover/focus updates local to the affected target.
class _SymbolPickerCell extends StatefulWidget {
  const _SymbolPickerCell({
    required this.label,
    required this.child,
    required this.selected,
    this.onPressed,
  });
  final String label;
  final Widget child;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  State<_SymbolPickerCell> createState() => _SymbolPickerCellState();
}

class _SymbolPickerCellState extends State<_SymbolPickerCell> {
  bool _hovered = false, _focused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      label: widget.label,
      selected: widget.selected,
      enabled: enabled,
      onTap: widget.onPressed,
      child: Tooltip(
        message: widget.label,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed?.call();
                return null;
              },
            ),
          },
          onShowHoverHighlight: (value) {
            setState(() => _hovered = value);
          },
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: widget.onPressed,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.selected || _hovered
                    ? tokens.colorSurfaceSubtle
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(tokens.radiusSmall),
                border: widget.selected || _focused
                    ? Border.all(
                        color: tokens.colorBorderFocus,
                        width: tokens.borderWidthStrong,
                      )
                    : null,
              ),
              child: ExcludeSemantics(child: Center(child: widget.child)),
            ),
          ),
        ),
      ),
    );
  }
}
