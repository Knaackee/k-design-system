import 'package:flutter/material.dart';
import 'k_data_table_draft.dart';

/// Shared row interaction boundary. Keep it outside recycled cells. Focus inside a cell also owns that cell's
/// selection popup; pointer transfers between non-focusable cells stay inside.
class KDataTableDraftBoundary {
  KDataTableDraftBoundary({required this.controller, required this.rowId});
  final KDataTableDraftController<dynamic> controller;
  final String rowId;
  void onExit() {
    controller.leave(rowId);
  }

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

class KDataTableDraftCellBoundary extends StatefulWidget {
  const KDataTableDraftCellBoundary({
    required this.boundary,
    required this.child,
    this.autofocus = false,
    super.key,
  });
  final KDataTableDraftBoundary? boundary;
  final Widget child;
  final bool autofocus;
  @override
  State<KDataTableDraftCellBoundary> createState() =>
      _KDataTableDraftCellBoundaryState();
}

class _KDataTableDraftCellBoundaryState
    extends State<KDataTableDraftCellBoundary> {
  final _focus = FocusNode(skipTraversal: true);
  @override
  void initState() {
    super.initState();
    widget.boundary?.nodes.add(_focus);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final node in _focus.descendants) {
          if (node.canRequestFocus && !node.skipTraversal) {
            node.requestFocus();
            break;
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(KDataTableDraftCellBoundary oldWidget) {
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
