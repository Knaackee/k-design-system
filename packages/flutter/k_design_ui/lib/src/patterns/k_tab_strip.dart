import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../actions/k_menu_button.dart';
import '../actions/k_context_menu.dart';
import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';

class KTabStripItem {
  const KTabStripItem({required this.id, required this.label, this.icon});
  final String id, label;
  final Widget? icon;
}

/// Controlled sortable tabs with a file picker on compact screens.
class KTabStrip extends StatefulWidget {
  const KTabStrip({
    required this.items,
    required this.selectedId,
    required this.onSelect,
    this.onClose,
    this.onReorder,
    this.menuActions,
    super.key,
  });
  final List<KTabStripItem> items;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String>? onClose;
  final ValueChanged<List<String>>? onReorder;
  final List<KMenuAction> Function(KTabStripItem, bool mobile)? menuActions;
  @override
  State<KTabStrip> createState() => _KTabStripState();
}

class _KTabStripState extends State<KTabStrip> {
  late final ScrollController _scrollController;
  final _tabKeys = <String, GlobalKey>{};
  bool _overflow = false, _measurementQueued = false;
  double _availableWidth = 0;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      onAttach: (_) => _measureAfterLayout(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(KTabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tabKeys.removeWhere((id, _) => !widget.items.any((item) => item.id == id));
    if (oldWidget.selectedId != widget.selectedId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final selected = _tabKeys[widget.selectedId]?.currentContext;
        if (selected != null) {
          Scrollable.ensureVisible(
            selected,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : Theme.of(context).extension<KDesignTokens>()!.motionStandard,
          );
        }
      });
    }
    _measureAfterLayout();
  }

  void _measureAfterLayout() {
    if (_measurementQueued) return;
    _measurementQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementQueued = false;
      if (!mounted || !_scrollController.hasClients) return;
      final metrics = _scrollController.position;
      if (!metrics.hasContentDimensions) return;
      // Compare measured content against the full strip, before overflow consumes space.
      final overflow =
          metrics.maxScrollExtent + metrics.viewportDimension >
          _availableWidth + 1;
      if (overflow != _overflow) setState(() => _overflow = overflow);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final selectedId = widget.selectedId;
    final onSelect = widget.onSelect;
    final onClose = widget.onClose;
    final onReorder = widget.onReorder;
    final menuActions = widget.menuActions;
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, bounds) {
        _availableWidth = bounds.maxWidth;
        _measureAfterLayout();
        final mobile = MediaQuery.sizeOf(context).width < 600;
        final current = items
            .where((item) => item.id == selectedId)
            .firstOrNull;
        if (mobile) {
          return KMenuButton(
            label: 'Geöffnete Dateien',
            fullWidth: true,
            triggerContent: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: t.spaceControlInsetInline,
              ),
              child: Row(
                children: [
                  if (current?.icon != null) current!.icon!,
                  SizedBox(width: t.spaceSmallInset),
                  Expanded(
                    child: Text(
                      current?.label ?? 'Dateien',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const KIcon(KIconName.chevronDown, size: 16),
                ],
              ),
            ),
            actions: [
              for (final item in items)
                KMenuAction(
                  id: 'select-${item.id}',
                  label: item.label,
                  iconContent: item.icon,
                  onSelect: () => onSelect(item.id),
                  contextActions:
                      menuActions?.call(item, true) ??
                      [
                        if (onClose != null)
                          KMenuAction(
                            id: 'close',
                            label: 'Schließen',
                            onSelect: () => onClose(item.id),
                          ),
                      ],
                ),
              if (current != null)
                for (final (index, action)
                    in (menuActions?.call(current, true) ?? <KMenuAction>[])
                        .indexed)
                  KMenuAction(
                    id: action.id,
                    label: action.label,
                    onSelect: action.onSelect,
                    icon: action.icon,
                    iconContent: action.iconContent,
                    children: action.children,
                    contextActions: action.contextActions,
                    disabled: action.disabled,
                    destructive: action.destructive,
                    separatorBefore: index == 0 || action.separatorBefore,
                  ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: t.sizeControl + 2,
                child: NotificationListener<ScrollMetricsNotification>(
                  onNotification: (_) {
                    _measureAfterLayout();
                    return false;
                  },
                  child: ReorderableListView.builder(
                    scrollController: _scrollController,
                    scrollDirection: Axis.horizontal,
                    buildDefaultDragHandles: false,
                    itemCount: items.length,
                    onReorderItem: (oldIndex, newIndex) {
                      final ids = items.map((item) => item.id).toList();
                      ids.insert(newIndex, ids.removeAt(oldIndex));
                      onReorder?.call(ids);
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ReorderableDragStartListener(
                        key: ValueKey(item.id),
                        index: index,
                        enabled: onReorder != null,
                        child: KContextMenu(
                          key: _tabKeys.putIfAbsent(item.id, GlobalKey.new),
                          label: item.label,
                          actions: menuActions?.call(item, false) ?? [],
                          child: Material(
                            color: item.id == selectedId
                                ? t.colorSurfaceCanvas
                                : t.colorSurfaceRaised,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    width: t.spaceMicro,
                                    color: item.id == selectedId
                                        ? t.colorTextPrimary
                                        : Colors.transparent,
                                  ),
                                  right: BorderSide(
                                    color: t.colorBorderDefault,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => onSelect(item.id),
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: t.spaceControlInsetInline,
                                        right: t.spaceTight,
                                      ),
                                      child: Row(
                                        children: [
                                          ?item.icon,
                                          SizedBox(width: t.spaceControlGap),
                                          Text(
                                            item.label,
                                            style: TextStyle(
                                              fontSize: t.fontControlSize,
                                              fontFamily: t.fontFamily,
                                              color: item.id == selectedId
                                                  ? t.colorTextPrimary
                                                  : t.colorTextMuted,
                                              fontVariations: [
                                                FontVariation.weight(400),
                                              ],
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (onClose != null)
                                    SizedBox(width: t.spaceTight),
                                  if (onClose != null)
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        extensions: [
                                          for (final extension in Theme.of(
                                            context,
                                          ).extensions.values)
                                            if (extension is! KDesignTokens)
                                              extension,
                                          // Compact pointer targets; touch-oriented platforms retain DS hit targets.
                                          if ([
                                            TargetPlatform.windows,
                                            TargetPlatform.linux,
                                            TargetPlatform.macOS,
                                          ].contains(
                                            Theme.of(context).platform,
                                          ))
                                            t.copyWith(
                                              sizeControl: 24,
                                              sizeHitTarget: 24,
                                            )
                                          else
                                            t.copyWith(
                                              sizeControl: 24,
                                              sizeHitTarget: 36,
                                            ),
                                        ],
                                      ),
                                      child: KIconSizeScope(
                                        size: 14,
                                        child: KIconButton(
                                          label: '${item.label} schließen',
                                          icon: KIconName.x,
                                          onPressed: () => onClose(item.id),
                                        ),
                                      ),
                                    ),
                                  SizedBox(width: t.spaceControlGap),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (_overflow)
              KMenuButton(
                label: 'Alle geöffneten Dateien',
                overflow: true,
                alignEnd: true,
                actions: [
                  for (final item in items)
                    KMenuAction(
                      id: item.id,
                      label: item.label,
                      iconContent: item.icon,
                      onSelect: () => onSelect(item.id),
                    ),
                  if (current != null)
                    ...menuActions?.call(current, false) ?? [],
                ],
              ),
          ],
        );
      },
    );
  }
}
