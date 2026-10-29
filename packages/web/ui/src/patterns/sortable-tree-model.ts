export interface KSortableTreeNode<T = unknown> {
  /** Unique across the entire tree; never derived from the current position. */
  id: string;
  label: string;
  data?: T;
  /** Defined (including []) for containers; omitted for leaves. */
  children?: readonly KSortableTreeNode<T>[];
}

export interface KSortableTreeMove {
  id: string;
  parentId: string | null;
  /** Destination index AFTER removing the source. */
  index: number;
}

export interface KSortableTreeEntry<T = unknown> {
  node: KSortableTreeNode<T>;
  parentId: string | null;
  index: number;
  /** Root nodes have depth 0. */
  depth: number;
}

export function flattenKSortableTree<T>(
  nodes: readonly KSortableTreeNode<T>[],
  expandedIds?: readonly string[],
): KSortableTreeEntry<T>[] {
  const entries: KSortableTreeEntry<T>[] = [];
  const expanded = expandedIds === undefined ? undefined : new Set(expandedIds);
  const seen = new Set<string>();
  function visit(
    items: readonly KSortableTreeNode<T>[],
    parentId: string | null,
    depth: number,
    visible: boolean,
  ) {
    items.forEach((node, index) => {
      if (seen.has(node.id))
        throw new Error(`Duplicate sortable tree ID: ${node.id}`);
      seen.add(node.id);
      if (visible) entries.push({ node, parentId, index, depth });
      if (node.children)
        visit(
          node.children,
          node.id,
          depth + 1,
          visible && (!expanded || expanded.has(node.id)),
        );
    });
  }
  visit(nodes, null, 0, true);
  return entries;
}

/** Invalid moves (including cycles, leaf targets and excessive depth) are no-ops. */
export function moveKSortableTree<T>(
  nodes: readonly KSortableTreeNode<T>[],
  move: KSortableTreeMove,
  options: { maxDepth?: number } = {},
): readonly KSortableTreeNode<T>[] {
  const entries = flattenKSortableTree(nodes);
  const source = entries.find(({ node }) => node.id === move.id);
  const target = entries.find(({ node }) => node.id === move.parentId);
  if (!source || (move.parentId !== null && !target?.node.children))
    return nodes;
  if (!Number.isInteger(move.index) || move.index < 0) return nodes;
  const subtree = flattenKSortableTree([source.node]);
  if (subtree.some(({ node }) => node.id === move.parentId)) return nodes;
  const depth = target ? target.depth + 1 : 0;
  if (
    options.maxDepth !== undefined &&
    depth + Math.max(...subtree.map((entry) => entry.depth)) > options.maxDepth
  )
    return nodes;
  const count =
    (target?.node.children ?? nodes).length -
    (source.parentId === move.parentId ? 1 : 0);
  if (
    move.index > count ||
    (source.parentId === move.parentId && source.index === move.index)
  )
    return nodes;
  function remove(
    items: readonly KSortableTreeNode<T>[],
  ): readonly KSortableTreeNode<T>[] {
    return items
      .filter((node) => node.id !== move.id)
      .map((node) =>
        node.children ? { ...node, children: remove(node.children) } : node,
      );
  }
  function insert(
    items: readonly KSortableTreeNode<T>[],
    parentId: string | null,
  ): readonly KSortableTreeNode<T>[] {
    if (parentId === move.parentId)
      return [
        ...items.slice(0, move.index),
        source!.node,
        ...items.slice(move.index),
      ];
    return items.map((node) =>
      node.children
        ? { ...node, children: insert(node.children, node.id) }
        : node,
    );
  }
  return insert(remove(nodes), null);
}
