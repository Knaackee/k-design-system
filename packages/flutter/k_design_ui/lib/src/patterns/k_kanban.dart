import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

typedef KKanbanCardBuilder<T> =
    Widget Function(BuildContext context, KKanbanCardContext<T> card);

@immutable
class KKanbanColumn<T> {
  const KKanbanColumn({
    required this.id,
    required this.title,
    required this.items,
    this.leading,
    this.trailing,
    this.addLabel,
  });

  final String id;
  final Widget title;
  final List<T> items;
  final Widget? leading;
  final Widget? trailing;
  final String? addLabel;
}

@immutable
class KKanbanCardContext<T> {
  const KKanbanCardContext({
    required this.item,
    required this.itemId,
    required this.columnId,
    required this.index,
    required this.selected,
    required this.toggleSelected,
  });

  final T item;
  final String itemId;
  final String columnId;
  final int index;
  final bool selected;
  final VoidCallback toggleSelected;
}

@immutable
class KKanbanMove<T> {
  const KKanbanMove({
    required this.item,
    required this.itemId,
    required this.sourceColumnId,
    required this.sourceIndex,
    required this.targetColumnId,
    required this.targetIndex,
  });

  final T item;
  final String itemId;
  final String sourceColumnId;
  final int sourceIndex;
  final String targetColumnId;
  final int targetIndex;
}

class _DragPayload<T> {
  const _DragPayload({
    required this.item,
    required this.itemId,
    required this.columnId,
    required this.index,
  });

  final T item;
  final String itemId;
  final String columnId;
  final int index;
}

class KKanban<T> extends StatelessWidget {
  const KKanban({
    required this.columns,
    required this.itemId,
    required this.cardBuilder,
    this.itemLabel,
    this.onCardOpen,
    this.onCardMove,
    this.canMove,
    this.onAddCard,
    this.selectedItemIds = const <String>{},
    this.onSelectionChanged,
    this.dragEnabled = true,
    this.columnWidth = 280,
    this.height = 640,
    this.scrollController,
    this.autoScrollEnabled = true,
    this.autoScrollEdgeExtent = 56,
    this.autoScrollMaxVelocity = 720,
    this.semanticLabel = 'Kanban board',
    super.key,
  });

  final List<KKanbanColumn<T>> columns;
  final String Function(T item) itemId;
  final String Function(T item)? itemLabel;
  final KKanbanCardBuilder<T> cardBuilder;
  final void Function(T item, String columnId)? onCardOpen;
  final void Function(KKanbanMove<T> move)? onCardMove;
  final bool Function(KKanbanMove<T> move)? canMove;
  final void Function(String columnId)? onAddCard;
  final Set<String> selectedItemIds;
  final ValueChanged<Set<String>>? onSelectionChanged;
  final bool dragEnabled;
  final double columnWidth;
  final double height;
  final ScrollController? scrollController;
  final bool autoScrollEnabled;
  final double autoScrollEdgeExtent;
  final double autoScrollMaxVelocity;
  final String semanticLabel;

  KKanbanMove<T> _moveFor(
    _DragPayload<T> payload,
    String targetColumnId,
    int targetIndex,
  ) {
    final adjustedIndex =
        payload.columnId == targetColumnId && targetIndex > payload.index
        ? targetIndex - 1
        : targetIndex;
    return KKanbanMove<T>(
      item: payload.item,
      itemId: payload.itemId,
      sourceColumnId: payload.columnId,
      sourceIndex: payload.index,
      targetColumnId: targetColumnId,
      targetIndex: adjustedIndex,
    );
  }

  bool _accepts(_DragPayload<T>? payload, String columnId, int index) {
    if (payload == null || onCardMove == null) return false;
    final move = _moveFor(payload, columnId, index);
    if (move.sourceColumnId == move.targetColumnId &&
        move.sourceIndex == move.targetIndex) {
      return false;
    }
    return canMove?.call(move) ?? true;
  }

  void _move(_DragPayload<T> payload, String columnId, int index) {
    final move = _moveFor(payload, columnId, index);
    if (_accepts(payload, columnId, index)) onCardMove?.call(move);
  }

  void _toggle(String id) {
    if (onSelectionChanged == null) return;
    final next = Set<String>.of(selectedItemIds);
    next.contains(id) ? next.remove(id) : next.add(id);
    onSelectionChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    if (!columnWidth.isFinite || columnWidth <= 0) {
      throw ArgumentError.value(columnWidth, 'columnWidth', 'Must be positive');
    }
    if (!height.isFinite || height <= 0) {
      throw ArgumentError.value(height, 'height', 'Must be positive');
    }
    if (!autoScrollEdgeExtent.isFinite || autoScrollEdgeExtent <= 0) {
      throw ArgumentError.value(
        autoScrollEdgeExtent,
        'autoScrollEdgeExtent',
        'Must be positive',
      );
    }
    if (!autoScrollMaxVelocity.isFinite || autoScrollMaxVelocity <= 0) {
      throw ArgumentError.value(
        autoScrollMaxVelocity,
        'autoScrollMaxVelocity',
        'Must be positive',
      );
    }
    return _KKanbanViewport<T>(kanban: this);
  }

  Widget _buildColumn(
    BuildContext context,
    KKanbanColumn<T> column,
    KDesignTokens tokens,
    ValueChanged<DragUpdateDetails> onDragUpdate,
    VoidCallback onDragEnd,
  ) {
    return SizedBox(
      width: columnWidth,
      height: height - tokens.spaceLayoutGutter * 2,
      child: Column(
        children: [
          SizedBox(
            height: tokens.sizeHitTarget,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceControlInsetInline,
              ),
              child: Row(
                children: [
                  if (column.leading != null) ...[
                    column.leading!,
                    SizedBox(width: tokens.spaceControlGap),
                  ],
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        color: tokens.colorTextPrimary,
                        fontFamily: tokens.fontFamily,
                        fontSize: tokens.fontLabelSize,
                        fontWeight: FontWeight.w500,
                        height:
                            tokens.fontLabelLineHeight / tokens.fontLabelSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: column.title,
                    ),
                  ),
                  SizedBox(width: tokens.spaceControlGap),
                  Text(
                    '${column.items.length}',
                    style: TextStyle(
                      color: tokens.colorTextMuted,
                      fontFamily: tokens.fontFamily,
                      fontSize: tokens.fontBodySmallSize,
                    ),
                  ),
                  if (column.trailing != null) ...[
                    SizedBox(width: tokens.spaceControlGap),
                    column.trailing!,
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceControlGap),
              itemCount: column.items.length + 1 + (onAddCard == null ? 0 : 1),
              itemBuilder: (context, index) {
                if (index == column.items.length) {
                  return _dropTarget(
                    column.id,
                    index,
                    tokens,
                    empty: column.items.isEmpty,
                  );
                }
                if (index == column.items.length + 1) {
                  return SizedBox(
                    width: double.infinity,
                    height: tokens.sizeHitTarget,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        foregroundColor: tokens.colorTextMuted,
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceControlInsetInline,
                        ),
                      ),
                      onPressed: () => onAddCard?.call(column.id),
                      child: Text(column.addLabel ?? 'Add item'),
                    ),
                  );
                }
                final item = column.items[index];
                final id = itemId(item);
                return Column(
                  children: [
                    _buildCard(
                      context,
                      column.id,
                      index,
                      item,
                      id,
                      tokens,
                      onDragUpdate,
                      onDragEnd,
                    ),
                    SizedBox(height: tokens.spaceControlGap),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropTarget(
    String columnId,
    int index,
    KDesignTokens tokens, {
    required bool empty,
  }) {
    return DragTarget<_DragPayload<T>>(
      onWillAcceptWithDetails: (details) =>
          _accepts(details.data, columnId, index),
      onAcceptWithDetails: (details) => _move(details.data, columnId, index),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: empty ? tokens.sizeHitTarget * 2 : tokens.spaceControlGap,
        decoration: BoxDecoration(
          border: empty
              ? Border.all(
                  color: candidates.isEmpty
                      ? tokens.colorBorderDefault
                      : tokens.colorBorderFocus,
                )
              : null,
          borderRadius: BorderRadius.circular(tokens.radiusCard),
          color: candidates.isEmpty ? null : tokens.colorSurfaceSubtle,
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String columnId,
    int index,
    T item,
    String id,
    KDesignTokens tokens,
    ValueChanged<DragUpdateDetails> onDragUpdate,
    VoidCallback onDragEnd,
  ) {
    final payload = _DragPayload<T>(
      item: item,
      itemId: id,
      columnId: columnId,
      index: index,
    );
    final selected = selectedItemIds.contains(id);
    final content = Semantics(
      label: itemLabel?.call(item) ?? id,
      selected: selected,
      button: onCardOpen != null,
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.radiusCard),
        onTap: onCardOpen == null ? null : () => onCardOpen!(item, columnId),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(tokens.spaceCardPadding),
          decoration: BoxDecoration(
            color: tokens.colorSurfaceRaised,
            border: Border.all(
              color: selected
                  ? tokens.colorBorderFocus
                  : tokens.colorBorderDefault,
              width: selected ? 2 : tokens.borderWidthDefault,
            ),
            borderRadius: BorderRadius.circular(tokens.radiusCard),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: cardBuilder(
            context,
            KKanbanCardContext<T>(
              item: item,
              itemId: id,
              columnId: columnId,
              index: index,
              selected: selected,
              toggleSelected: () => _toggle(id),
            ),
          ),
        ),
      ),
    );

    return DragTarget<_DragPayload<T>>(
      onWillAcceptWithDetails: (details) =>
          _accepts(details.data, columnId, index),
      onAcceptWithDetails: (details) => _move(details.data, columnId, index),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: candidates.isEmpty ? null : tokens.colorSurfaceSubtle,
          border: candidates.isEmpty
              ? null
              : Border(
                  top: BorderSide(color: tokens.colorBorderFocus, width: 2),
                ),
        ),
        child: dragEnabled && onCardMove != null
            ? LongPressDraggable<_DragPayload<T>>(
                data: payload,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(width: columnWidth, child: content),
                ),
                childWhenDragging: Opacity(opacity: 0.4, child: content),
                onDragUpdate: onDragUpdate,
                onDragEnd: (_) => onDragEnd(),
                onDragCompleted: onDragEnd,
                onDraggableCanceled: (_, _) => onDragEnd(),
                child: content,
              )
            : content,
      ),
    );
  }
}

class _KKanbanViewport<T> extends StatefulWidget {
  const _KKanbanViewport({required this.kanban});

  final KKanban<T> kanban;

  @override
  State<_KKanbanViewport<T>> createState() => _KKanbanViewportState<T>();
}

class _KKanbanViewportState<T> extends State<_KKanbanViewport<T>> {
  static const _tick = Duration(milliseconds: 16);

  final _internalController = ScrollController();
  final _viewportKey = GlobalKey();
  Timer? _autoScrollTimer;
  double _autoScrollVelocity = 0;

  ScrollController get _controller =>
      widget.kanban.scrollController ?? _internalController;

  @override
  void dispose() {
    _stopAutoScroll();
    _internalController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!widget.kanban.autoScrollEnabled) return;
    final renderObject = _viewportKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final local = renderObject.globalToLocal(details.globalPosition);
    final edge = widget.kanban.autoScrollEdgeExtent.clamp(
      1.0,
      renderObject.size.width / 2,
    );
    final velocity = local.dx < edge
        ? -widget.kanban.autoScrollMaxVelocity *
              ((edge - local.dx) / edge).clamp(0.0, 1.0)
        : local.dx > renderObject.size.width - edge
        ? widget.kanban.autoScrollMaxVelocity *
              ((local.dx - (renderObject.size.width - edge)) / edge).clamp(
                0.0,
                1.0,
              )
        : 0.0;
    _setAutoScrollVelocity(velocity);
  }

  void _setAutoScrollVelocity(double velocity) {
    _autoScrollVelocity = velocity;
    if (velocity == 0) {
      _stopAutoScroll();
      return;
    }
    _autoScrollTimer ??= Timer.periodic(_tick, (_) => _autoScroll());
  }

  void _autoScroll() {
    if (!_controller.hasClients || _autoScrollVelocity == 0) return;
    final position = _controller.position;
    final next =
        (_controller.offset + _autoScrollVelocity * _tick.inMilliseconds / 1000)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    if (next == _controller.offset) return;
    _controller.jumpTo(next);
  }

  void _stopAutoScroll() {
    _autoScrollVelocity = 0;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final kanban = widget.kanban;
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final behavior = ScrollConfiguration.of(context).copyWith(
      dragDevices: const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
      },
    );
    return Semantics(
      label: kanban.semanticLabel,
      container: true,
      child: SizedBox(
        key: _viewportKey,
        height: kanban.height,
        child: ScrollConfiguration(
          behavior: behavior,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(tokens.spaceLayoutGutter),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (
                  var columnIndex = 0;
                  columnIndex < kanban.columns.length;
                  columnIndex++
                ) ...[
                  kanban._buildColumn(
                    context,
                    kanban.columns[columnIndex],
                    tokens,
                    _handleDragUpdate,
                    _stopAutoScroll,
                  ),
                  if (columnIndex < kanban.columns.length - 1)
                    SizedBox(width: tokens.spaceLayoutSectionGap),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
