import 'package:flutter/widgets.dart';

class KDataTableScrollPhysics extends ClampingScrollPhysics {
  const KDataTableScrollPhysics({required this.allow, super.parent});
  final bool Function(double) allow;
  @override
  KDataTableScrollPhysics applyTo(ScrollPhysics? ancestor) =>
      KDataTableScrollPhysics(allow: allow, parent: buildParent(ancestor));
  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value != position.pixels && !allow(value)) {
      return value - position.pixels;
    }
    return super.applyBoundaryConditions(position, value);
  }
}

void focusKDataTableCell(BuildContext context) {
  FocusNode? scope;
  context.visitChildElements(
    (child) => scope ??= Focus.maybeOf(child, createDependency: false),
  );
  if (scope == null) return;
  for (final node in scope!.descendants) {
    if (node.canRequestFocus && !node.skipTraversal) {
      node.requestFocus();
      break;
    }
  }
}
