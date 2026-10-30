import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../actions/k_icon_button.dart';
import '../actions/k_menu_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_text.dart';
import 'k_sortable_tree_model.dart';
export 'k_sortable_tree_model.dart';
import 'k_sortable_tree_types.dart';
import 'k_sortable_tree_motion.dart';
export 'k_sortable_tree_types.dart';
part 'k_sortable_tree_row.dart';

/// Controlled hierarchical list. Hosts own data, edit/remove actions and undo.
class KSortableTree<T> extends StatefulWidget {
  const KSortableTree({
    required this.nodes,
    required this.onMove,
    this.renderContent,
    this.renderActions,
    this.ariaLabel = 'Sortable hierarchy',
    this.getActions,
    this.expandedIds,
    this.defaultExpandedIds,
    this.onExpandedChange,
    this.canMove,
    this.maxDepth,
    this.minRowHeight,
    this.ungroupedLabel,
    this.defaultUngroupedExpanded = true,
    this.disabled = false,
    this.labels = const KSortableTreeLabels(),
    super.key,
  });
  final String ariaLabel;
  final Widget Function(BuildContext, KSortableTreeContext<T>)? renderActions;
  final List<KSortableTreeNode<T>> nodes;
  final ValueChanged<KSortableTreeMove> onMove;
  final Widget Function(BuildContext, KSortableTreeContext<T>)? renderContent;
  final List<KMenuAction> Function(KSortableTreeContext<T>)? getActions;
  final Set<String>? expandedIds, defaultExpandedIds;
  final ValueChanged<Set<String>>? onExpandedChange;
  final bool Function(KSortableTreeMove)? canMove;
  final int? maxDepth;

  /// Minimum complete row extent for custom content, including row insets.
  final double? minRowHeight;

  /// Display-only group for root leaves. Move events retain parentId == null.
  final String? ungroupedLabel;
  final bool defaultUngroupedExpanded;
  final bool disabled;
  final KSortableTreeLabels labels;
  @override
  State<KSortableTree<T>> createState() => _KSortableTreeState<T>();
}

class _KSortableTreeState<T> extends State<KSortableTree<T>> {
  late Set<String> _expanded =
      widget.defaultExpandedIds ??
      {
        for (final e in flattenKSortableTree(widget.nodes))
          if (e.node.children != null) e.node.id,
      };
  late bool _ungroupedOpen = widget.defaultUngroupedExpanded;
  void toggleUngrouped() => setState(() => _ungroupedOpen = !_ungroupedOpen);
  String? _dragging;
  String _announcement = '';
  final _rowKeys = <String, GlobalKey>{};
  Timer? _scrollTimer;
  Offset? _dragPosition;
  KSortableTreeMove? _keyboardMove;
  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }

  void dragStart(String id) {
    setState(() => _dragging = id);
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final scroll = Scrollable.maybeOf(context);
      final position = _dragPosition;
      final box = scroll?.context.findRenderObject() as RenderBox?;
      if (scroll == null || box == null || position == null) return;
      final y = box.globalToLocal(position).dy;
      final edge = t.sizeControl;
      final delta = y < edge
          ? -t.spaceControlGap
          : y > box.size.height - edge
          ? t.spaceControlGap
          : 0.0;
      if (delta != 0) {
        scroll.position.jumpTo(
          (scroll.position.pixels + delta).clamp(
            scroll.position.minScrollExtent,
            scroll.position.maxScrollExtent,
          ),
        );
      }
    });
  }

  void dragEnd() {
    _scrollTimer?.cancel();
    _dragPosition = null;
    if (mounted) {
      setState(() {
        _dragging = null;
        _keyboardMove = null;
      });
    }
  }

  KeyEventResult handleKey(KSortableTreeEntry<T> e, KeyEvent event) {
    if (event is! KeyDownEvent || widget.disabled) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      if (_keyboardMove == null) {
        setState(() {
          _dragging = e.node.id;
          _keyboardMove = KSortableTreeMove(
            id: e.node.id,
            parentId: e.parentId,
            index: e.index,
          );
        });
      } else {
        commit(_keyboardMove!);
        dragEnd();
      }
      return KeyEventResult.handled;
    }
    if (_keyboardMove == null || _dragging != e.node.id) {
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.escape) {
      dragEnd();
      return KeyEventResult.handled;
    }
    final all = flattenKSortableTree(widget.nodes);
    final current = _keyboardMove!;
    final siblings = current.parentId == null
        ? widget.nodes
        : all.firstWhere((n) => n.node.id == current.parentId).node.children!;
    KSortableTreeMove? next;
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown) {
      next = KSortableTreeMove(
        id: e.node.id,
        parentId: current.parentId,
        index: current.index + (key == LogicalKeyboardKey.arrowUp ? -1 : 1),
      );
    } else if (key == LogicalKeyboardKey.arrowLeft &&
        current.parentId != null) {
      final parent = all.firstWhere((n) => n.node.id == current.parentId);
      next = moveTo(e.node.id, parent.parentId, parent.index + 1);
    } else if (key == LogicalKeyboardKey.arrowRight &&
        current.index > 0 &&
        current.index <= siblings.length) {
      final previous = siblings[current.index - 1];
      if (previous.children != null) {
        next = moveTo(e.node.id, previous.id, previous.children!.length);
      }
    }
    if (next == null) return KeyEventResult.ignored;
    if (allowed(next)) setState(() => _keyboardMove = next);
    return KeyEventResult.handled;
  }

  Set<String> get expanded => widget.expandedIds ?? _expanded;
  KDesignTokens get t =>
      Theme.of(context).extension<KDesignTokens>() ?? KDesignTokens.orbitLight;
  void toggle(String id) {
    final next = {...expanded};
    next.contains(id) ? next.remove(id) : next.add(id);
    setState(() => _expanded = next);
    widget.onExpandedChange?.call(next);
  }

  bool allowed(KSortableTreeMove move) =>
      !widget.disabled &&
      !identical(
        moveKSortableTree(widget.nodes, move, maxDepth: widget.maxDepth),
        widget.nodes,
      ) &&
      (widget.canMove?.call(move) ?? true);
  KSortableTreeMove moveTo(String id, String? parent, int index) {
    final source = flattenKSortableTree(
      widget.nodes,
    ).where((e) => e.node.id == id).firstOrNull;
    if (source == null) {
      return KSortableTreeMove(id: id, parentId: parent, index: index);
    }
    return KSortableTreeMove(
      id: id,
      parentId: parent,
      index:
          index - (source.parentId == parent && source.index < index ? 1 : 0),
    );
  }

  void commit(KSortableTreeMove move) {
    if (!allowed(move)) return;
    final moved = flattenKSortableTree(
      widget.nodes,
    ).firstWhere((e) => e.node.id == move.id).node;
    setState(() => _announcement = widget.labels.moved(moved.label));
    widget.onMove(move);
    if (move.parentId != null && !expanded.contains(move.parentId)) {
      toggle(move.parentId!);
    }
  }

  List<KMenuAction> actions(
    KSortableTreeEntry<T> e,
    KSortableTreeContext<T> c,
  ) {
    final all = flattenKSortableTree(widget.nodes);
    final siblings = e.parentId == null
        ? widget.nodes
        : all.firstWhere((p) => p.node.id == e.parentId).node.children!;
    final peers = e.parentId == null && widget.ungroupedLabel != null
        ? siblings
              .where((n) => (n.children == null) == (e.node.children == null))
              .toList()
        : siblings;
    final peerIndex = peers.indexWhere((n) => n.id == e.node.id);
    final upIndex = peerIndex > 0 ? siblings.indexOf(peers[peerIndex - 1]) : -1;
    final downIndex = peerIndex + 1 < peers.length
        ? siblings.indexOf(peers[peerIndex + 1])
        : e.index;
    final supplied = widget.getActions?.call(c) ?? <KMenuAction>[];
    KMenuAction movement(
      String id,
      String label,
      KIconName icon,
      int index, {
      bool separator = false,
    }) {
      final move = KSortableTreeMove(
        id: e.node.id,
        parentId: e.parentId,
        index: index,
      );
      return KMenuAction(
        id: id,
        label: label,
        iconContent: KIcon(icon, strokeWidth: 1.5),
        disabled: !allowed(move),
        separatorBefore: separator,
        onSelect: () => commit(move),
      );
    }

    final destinations = <KMenuAction>[];
    for (final target in all.where((p) => p.node.children != null)) {
      final move = moveTo(
        e.node.id,
        target.node.id,
        target.node.children!.length,
      );
      if (target.node.id != e.parentId && allowed(move)) {
        destinations.add(
          KMenuAction(
            id: 'to-${target.node.id}',
            label: target.node.label,
            onSelect: () => commit(move),
          ),
        );
      }
    }
    final root = moveTo(e.node.id, null, widget.nodes.length);
    if (e.parentId != null && allowed(root)) {
      destinations.add(
        KMenuAction(
          id: 'to-root',
          label: widget.ungroupedLabel ?? widget.labels.root,
          onSelect: () => commit(root),
        ),
      );
    }
    return [
      ...supplied.where((a) => !a.destructive),
      movement(
        'up',
        widget.labels.up,
        KIconName.arrowUp,
        upIndex,
        separator: supplied.any((a) => !a.destructive),
      ),
      movement('down', widget.labels.down, KIconName.arrowDown, downIndex),
      if (destinations.isNotEmpty)
        KMenuAction(
          id: 'move-to',
          label: widget.labels.moveTo,
          iconContent: const KIcon(KIconName.arrowRight, strokeWidth: 1.5),
          children: destinations,
        ),
      for (final a in supplied.where((a) => a.destructive))
        KMenuAction(
          id: a.id,
          label: a.label,
          onSelect: a.onSelect,
          icon: a.icon,
          iconContent: a.iconContent,
          disabled: a.disabled,
          destructive: true,
          separatorBefore: true,
        ),
    ];
  }

  bool keyboardTarget(String? parent, int index) {
    final move = _keyboardMove;
    if (move == null || !allowed(move)) return false;
    final target = moveTo(move.id, parent, index);
    return move.parentId == target.parentId && move.index == target.index;
  }

  Widget drop({
    Key? key,
    required String? parent,
    required int index,
    required Widget child,
    bool inside = false,
  }) => DragTarget<String>(
    key: key,
    onWillAcceptWithDetails: (d) =>
        !(inside &&
            parent == null &&
            flattenKSortableTree(
              widget.nodes,
            ).any((e) => e.node.id == d.data && e.node.children != null)) &&
        allowed(moveTo(d.data, parent, index)),
    onAcceptWithDetails: (d) => commit(moveTo(d.data, parent, index)),
    builder: (context, accepted, rejected) => Container(
      foregroundDecoration: BoxDecoration(
        color: inside && (accepted.isNotEmpty || keyboardTarget(parent, index))
            ? t.colorBorderFocus.withValues(alpha: .18)
            : null,
        border:
            !inside && (accepted.isNotEmpty || keyboardTarget(parent, index))
            ? Border(
                top: BorderSide(
                  color: t.colorBorderFocus,
                  width: t.borderWidthStrong,
                ),
              )
            : null,
      ),
      child: child,
    ),
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final all = flattenKSortableTree(widget.nodes, expanded);
      final grouped =
          widget.ungroupedLabel != null &&
          widget.nodes.any((n) => n.children == null);
      final leaves = all
          .where((e) => e.parentId == null && e.node.children == null)
          .toList();
      final defaultHeight =
          math.max(
            t.sizeHitTarget,
            MediaQuery.textScalerOf(
              context,
            ).scale(t.fontBodySmallLineHeight + t.fontCaptionLineHeight),
          ) +
          2 * t.spaceControlGap +
          2 * t.borderWidthDefault;
      final height = math.max(defaultHeight, widget.minRowHeight ?? 0);
      final indent = constraints.maxWidth < 640
          ? t.spaceControlInsetInline
          : t.spaceLayoutSectionGap;
      Widget entry(KSortableTreeEntry<T> e, {int? depth}) {
        final padding = math.min(depth ?? e.depth, 3) * indent;
        return Padding(
          key: ValueKey(e.node.id),
          padding: EdgeInsets.only(left: padding),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: t.colorBorderDefault,
                  width: t.borderWidthDefault,
                ),
              ),
            ),
            child: row(
              depth == null
                  ? e
                  : KSortableTreeEntry(
                      node: e.node,
                      parentId: e.parentId,
                      index: e.index,
                      depth: depth,
                    ),
              constraints.maxWidth - padding,
              height,
            ),
          ),
        );
      }

      return Semantics(
        label: _announcement.isEmpty
            ? widget.ariaLabel
            : '${widget.ariaLabel}. $_announcement',
        liveRegion: true,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: t.colorSurfaceRaised,
            border: Border.all(
              color: t.colorBorderDefault,
              width: t.borderWidthDefault,
            ),
            borderRadius: BorderRadius.circular(t.radiusControl),
          ),
          child: SortableTreeMotion(
            rowExtent: height,
            duration: t.motionModerate,
            children: [
              for (final e in all)
                if (!grouped || e.parentId != null || e.node.children != null)
                  entry(e),
              if (grouped) ...[
                KeyedSubtree(
                  key: const ValueKey(#ungrouped),
                  child: row(
                    KSortableTreeEntry(
                      node: KSortableTreeNode<T>(
                        id: '__k-sortable-tree-ungrouped',
                        label: widget.ungroupedLabel!,
                        children: leaves.map((e) => e.node).toList(),
                      ),
                      parentId: null,
                      index: widget.nodes.length,
                      depth: 0,
                    ),
                    constraints.maxWidth,
                    height,
                    fixed: true,
                  ),
                ),
                if (_ungroupedOpen)
                  for (final e in leaves) entry(e, depth: 1),
              ],
              if (all.isEmpty)
                Padding(
                  key: const ValueKey('tree-empty'),
                  padding: EdgeInsets.all(t.spaceControlInsetInline),
                  child: KText(
                    widget.labels.empty,
                    variant: KTextVariant.bodySmall,
                  ),
                ),
              if (_dragging != null)
                drop(
                  key: const ValueKey('tree-end'),
                  parent: null,
                  index: widget.nodes.length,
                  child: SizedBox(
                    height: t.sizeHitTarget,
                    width: double.infinity,
                    child: Center(
                      child: KText(
                        widget.ungroupedLabel ?? widget.labels.root,
                        variant: KTextVariant.caption,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
