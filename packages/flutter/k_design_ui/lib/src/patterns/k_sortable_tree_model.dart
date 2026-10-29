import 'package:flutter/foundation.dart';

@immutable
class KSortableTreeNode<T> {
  const KSortableTreeNode({
    required this.id,
    required this.label,
    this.data,
    this.children,
  });
  final String id;
  final String label;
  final T? data;

  /// Null for leaves; an empty list is an empty container.
  final List<KSortableTreeNode<T>>? children;
  KSortableTreeNode<T> copyWith({
    String? label,
    List<KSortableTreeNode<T>>? children,
  }) => KSortableTreeNode(
    id: id,
    label: label ?? this.label,
    data: data,
    children: children ?? this.children,
  );
}

@immutable
class KSortableTreeMove {
  const KSortableTreeMove({
    required this.id,
    required this.parentId,
    required this.index,
  });
  final String id;
  final String? parentId;

  /// Destination index after removal of the source.
  final int index;
}

@immutable
class KSortableTreeEntry<T> {
  const KSortableTreeEntry({
    required this.node,
    required this.parentId,
    required this.index,
    required this.depth,
  });
  final KSortableTreeNode<T> node;
  final String? parentId;
  final int index;
  final int depth;
}

List<KSortableTreeEntry<T>> flattenKSortableTree<T>(
  List<KSortableTreeNode<T>> nodes, [
  Set<String>? expandedIds,
]) {
  final entries = <KSortableTreeEntry<T>>[];
  final seen = <String>{};
  void visit(
    List<KSortableTreeNode<T>> items,
    String? parentId,
    int depth,
    bool visible,
  ) {
    for (var i = 0; i < items.length; i++) {
      final node = items[i];
      if (!seen.add(node.id)) {
        throw ArgumentError('Duplicate sortable tree ID: ${node.id}');
      }
      if (visible) {
        entries.add(
          KSortableTreeEntry(
            node: node,
            parentId: parentId,
            index: i,
            depth: depth,
          ),
        );
      }
      if (node.children != null) {
        visit(
          node.children!,
          node.id,
          depth + 1,
          visible && (expandedIds == null || expandedIds.contains(node.id)),
        );
      }
    }
  }

  visit(nodes, null, 0, true);
  return entries;
}

/// Invalid moves, cycles and no-ops preserve the original list identity.
List<KSortableTreeNode<T>> moveKSortableTree<T>(
  List<KSortableTreeNode<T>> nodes,
  KSortableTreeMove move, {
  int? maxDepth,
}) {
  final all = flattenKSortableTree(nodes);
  final sources = all.where((e) => e.node.id == move.id);
  final targets = all.where((e) => e.node.id == move.parentId);
  if (sources.isEmpty || move.index < 0) return nodes;
  final source = sources.first;
  final target = targets.firstOrNull;
  if (move.parentId != null && target?.node.children == null) return nodes;
  final subtree = flattenKSortableTree([source.node]);
  if (subtree.any((e) => e.node.id == move.parentId)) return nodes;
  final depth = target == null ? 0 : target.depth + 1;
  if (maxDepth != null && subtree.any((e) => depth + e.depth > maxDepth)) {
    return nodes;
  }
  final count =
      (target?.node.children ?? nodes).length -
      (source.parentId == move.parentId ? 1 : 0);
  if (move.index > count ||
      (source.parentId == move.parentId && source.index == move.index)) {
    return nodes;
  }
  List<KSortableTreeNode<T>> remove(List<KSortableTreeNode<T>> items) => [
    for (final node in items)
      if (node.id != move.id)
        node.children == null
            ? node
            : node.copyWith(children: remove(node.children!)),
  ];
  List<KSortableTreeNode<T>> insert(
    List<KSortableTreeNode<T>> items,
    String? parentId,
  ) {
    if (parentId == move.parentId) {
      return [
        ...items.take(move.index),
        source.node,
        ...items.skip(move.index),
      ];
    }
    return [
      for (final node in items)
        node.children == null
            ? node
            : node.copyWith(children: insert(node.children!, node.id)),
    ];
  }

  return insert(remove(nodes), null);
}
