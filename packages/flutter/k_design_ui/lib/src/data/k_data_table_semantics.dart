import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// Uses the upstream TableView builder delegate and viewport renderer, adding
/// the semantic row parents missing from its stock widget adapter.
class KSemanticTableView extends StatefulWidget {
  const KSemanticTableView({required this.configuration, super.key});
  final TableView configuration;
  @override
  State<KSemanticTableView> createState() => _KSemanticTableViewState();
}

class _KSemanticTableViewState extends State<KSemanticTableView> {
  @override
  void didUpdateWidget(covariant KSemanticTableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.configuration.delegate != widget.configuration.delegate) {
      oldWidget.configuration.delegate.dispose();
    }
  }

  @override
  void dispose() {
    widget.configuration.delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.configuration;
    return _SemanticScrollView(
      delegate: c.delegate,
      verticalDetails: c.verticalDetails,
      horizontalDetails: c.horizontalDetails,
      // The public upstream constructor still uses cacheExtent.
      // ignore: deprecated_member_use
      cacheExtent: c.cacheExtent,
    );
  }
}

class _SemanticScrollView extends TwoDimensionalScrollView {
  const _SemanticScrollView({
    required super.delegate,
    required super.verticalDetails,
    required super.horizontalDetails,
    // ignore: deprecated_member_use
    super.cacheExtent,
  });
  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) => _SemanticViewport(
    delegate: delegate as TableCellDelegateMixin,
    verticalOffset: verticalOffset,
    horizontalOffset: horizontalOffset,
    verticalAxisDirection: verticalDetails.direction,
    horizontalAxisDirection: horizontalDetails.direction,
    mainAxis: mainAxis,
    // ignore: deprecated_member_use
    cacheExtent: cacheExtent,
  );
}

class _SemanticViewport extends TableViewport {
  const _SemanticViewport({
    required super.delegate,
    required super.verticalOffset,
    required super.horizontalOffset,
    required super.verticalAxisDirection,
    required super.horizontalAxisDirection,
    required super.mainAxis,
    // ignore: deprecated_member_use
    super.cacheExtent,
  });
  @override
  RenderTableViewport createRenderObject(BuildContext context) =>
      _SemanticTableRenderer(
        delegate: delegate as TableCellDelegateMixin,
        verticalOffset: verticalOffset,
        horizontalOffset: horizontalOffset,
        verticalAxisDirection: verticalAxisDirection,
        horizontalAxisDirection: horizontalAxisDirection,
        mainAxis: mainAxis,
        // ignore: deprecated_member_use
        cacheExtent: cacheExtent,
        childManager: context as TwoDimensionalChildManager,
        textDirection: Directionality.of(context),
      );
}

class _SemanticTableRenderer extends RenderTableViewport {
  _SemanticTableRenderer({
    required super.delegate,
    required super.verticalOffset,
    required super.horizontalOffset,
    required super.verticalAxisDirection,
    required super.horizontalAxisDirection,
    required super.mainAxis,
    required super.childManager,
    // ignore: deprecated_member_use
    super.cacheExtent,
    super.textDirection,
  });
  final _rows = <int, SemanticsNode>{};
  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.textDirection = textDirection;
    config.role = SemanticsRole.table;
    config.isSemanticBoundary = true;
    config.explicitChildNodes = true;
    config.value = '${delegate.rowCount ?? 0}';
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _rows.clear();
  }

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    final grouped = <int, List<SemanticsNode>>{};
    for (final child in children) {
      final id = child.getSemanticsData().identifier;
      final index = int.tryParse(id.replaceFirst('k-data-row-', ''));
      if (index != null) (grouped[index - 1] ??= []).add(child);
    }
    final rowNodes = <SemanticsNode>[];
    final indices = grouped.keys.toList()..sort();
    for (final index in indices) {
      final cells = grouped[index]!;
      // Keep child viewport coordinates intact; the synthetic row uses the same
      // coordinate origin. This avoids accumulating transforms during scroll.
      var rect = Rect.zero;
      for (final cell in cells) {
        final transform = cell.transform;
        final cellRect = transform == null
            ? cell.rect
            : MatrixUtils.transformRect(transform, cell.rect);
        rect = rect.isEmpty ? cellRect : rect.expandToInclude(cellRect);
      }
      final row = _rows.putIfAbsent(index, SemanticsNode.new);
      row.rect = rect;
      row.updateWith(
        config: SemanticsConfiguration()
          ..role = SemanticsRole.row
          ..indexInParent = index,
        childrenInInversePaintOrder: cells,
      );
      rowNodes.add(row);
    }
    node.updateWith(config: config, childrenInInversePaintOrder: rowNodes);
    _rows.removeWhere((index, _) => !grouped.containsKey(index));
  }
}
