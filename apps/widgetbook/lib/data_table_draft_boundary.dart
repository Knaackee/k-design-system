import 'package:flutter/material.dart';

/// Consumer-owned row boundary. Focus inside a cell also owns that cell's
/// selection popup; pointer transfers between non-focusable cells stay inside.
class DraftRowBoundary {
  DraftRowBoundary({required this.onExit});
  final VoidCallback onExit;
  final Set<FocusNode> nodes = {};
  bool _insidePointer = false;
  bool _scheduled = false;
  bool _closed = false;

  void close() => _closed = true;
  void pointerInside() {
    _insidePointer = true;
    checkExit();
  }

  void checkExit() {
    if (_closed || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.ensureVisualUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      final inside = _insidePointer || nodes.any((node) => node.hasFocus);
      _insidePointer = false;
      if (!_closed && !inside) onExit();
    });
  }
}

class DraftCellBoundary extends StatefulWidget {
  const DraftCellBoundary({
    required this.boundary,
    required this.child,
    super.key,
  });
  final DraftRowBoundary? boundary;
  final Widget child;
  @override
  State<DraftCellBoundary> createState() => _DraftCellBoundaryState();
}

class _DraftCellBoundaryState extends State<DraftCellBoundary> {
  final _focus = FocusNode(skipTraversal: true);
  @override
  void initState() {
    super.initState();
    widget.boundary?.nodes.add(_focus);
  }

  @override
  void didUpdateWidget(DraftCellBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.boundary != widget.boundary) {
      oldWidget.boundary?.nodes.remove(_focus);
      widget.boundary?.nodes.add(_focus);
    }
  }

  @override
  void dispose() {
    widget.boundary?.nodes.remove(_focus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TapRegion(
    groupId: widget.boundary ?? this,
    enabled: widget.boundary != null,
    onTapInside: (_) => widget.boundary?.pointerInside(),
    onTapOutside: (_) => widget.boundary?.checkExit(),
    child: Focus(
      focusNode: _focus,
      onFocusChange: (_) => widget.boundary?.checkExit(),
      child: widget.child,
    ),
  );
}
