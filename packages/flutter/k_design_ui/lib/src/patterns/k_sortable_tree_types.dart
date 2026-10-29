import 'package:flutter/foundation.dart';
import 'k_sortable_tree_model.dart';

class KSortableTreeLabels {
  const KSortableTreeLabels({
    this.drag = 'Drag',
    this.expand = 'Expand',
    this.collapse = 'Collapse',
    this.move = 'Move',
    this.up = 'Move up',
    this.down = 'Move down',
    this.indent = 'Nest in previous group',
    this.outdent = 'Move out one level',
    this.moveTo = 'Move to',
    this.root = 'Top level',
    this.drop = 'Drop here',
    this.empty = 'No items',
    this.moved = _moved,
  });
  final String drag,
      expand,
      collapse,
      move,
      up,
      down,
      indent,
      outdent,
      moveTo,
      root,
      drop,
      empty;
  final String Function(String) moved;
  static String _moved(String label) => 'Moved $label';
}

class KSortableTreeContext<T> {
  const KSortableTreeContext({
    required this.node,
    required this.depth,
    required this.expanded,
    required this.toggleExpanded,
  });
  final KSortableTreeNode<T> node;
  final int depth;
  final bool expanded;
  final VoidCallback toggleExpanded;
}
