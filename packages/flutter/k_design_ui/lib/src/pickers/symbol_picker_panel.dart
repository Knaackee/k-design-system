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
  String _query = '', _category = '';
  KSymbolItem? _hovered;
  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
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
    Widget button(
      String label,
      Widget child,
      VoidCallback? action, {
      bool selected = false,
      VoidCallback? hover,
    }) => _SymbolPickerCell(
      label: label,
      selected: selected,
      onPressed: action,
      onHighlight: hover,
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
                padding: const EdgeInsets.all(12),
                child: KInput(
                  focusNode: widget.searchFocus,
                  controller: _search,
                  label: labels.search,
                  placeholder: labels.search,
                  enabled: widget.enabled,
                  clearable: true,
                  onChanged: (value) => setState(() {
                    _query = value;
                    _hovered = null;
                  }),
                ),
              ),
              Container(
                height: 53,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: tokens.colorBorderDefault),
                  ),
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  children: [
                    for (final tab in tabs.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: button(
                          tab.value,
                          SizedBox(
                            width: 44,
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
                                  _hovered = null;
                                  if (_scroll.hasClients) _scroll.jumpTo(0);
                                })
                              : null,
                          selected: _category == tab.key,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(child: KText(labels.empty))
                    : LayoutBuilder(
                        builder: (context, constraints) => FocusTraversalGroup(
                          child: GridView.builder(
                            controller: _scroll,
                            // SVG decoding is comparatively expensive. Build
                            // glyphs as they enter this small menu viewport.
                            scrollCacheExtent: const ScrollCacheExtent.pixels(
                              0,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      ((constraints.maxWidth - 24) / 44)
                                          .floor()
                                          .clamp(1, 100),
                                  mainAxisExtent: 44,
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
                                  hover: () {
                                    if (_hovered != item) {
                                      setState(() => _hovered = item);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
              ),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: tokens.colorBorderDefault),
                  ),
                ),
                child: Row(
                  children: [
                    if (_hovered != null) ...[
                      widget.itemBuilder(context, _hovered!),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: KText(
                        _hovered?.label ?? labels.hint,
                        variant: KTextVariant.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.accessory != null) ...[
                      const SizedBox(width: 8),
                      widget.accessory!,
                    ],
                  ],
                ),
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
    this.onHighlight,
  });
  final String label;
  final Widget child;
  final bool selected;
  final VoidCallback? onPressed, onHighlight;

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
            if (value) widget.onHighlight?.call();
          },
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          onFocusChange: (value) {
            if (value) widget.onHighlight?.call();
          },
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
                    ? Border.all(color: tokens.colorBorderFocus, width: 2)
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
