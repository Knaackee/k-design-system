import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'k_dictation_action.dart';

/// Places visual-only dots over the native editable's saved caret geometry.
class KDictationFieldOverlay extends StatefulWidget {
  const KDictationFieldOverlay({
    required this.child,
    required this.state,
    this.offset,
    this.controller,
    super.key,
  });
  final Widget child;
  final KDictationState? state;
  final int? offset;
  final TextEditingController? controller;
  @override
  State<KDictationFieldOverlay> createState() => _KDictationFieldOverlayState();
}

class _KDictationFieldOverlayState extends State<KDictationFieldOverlay> {
  final _fieldKey = GlobalKey();
  final _stackKey = GlobalKey();
  RenderEditable? _editable;
  Rect? _caret;
  bool get _active =>
      widget.state == KDictationState.recording ||
      widget.state == KDictationState.processing;
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_schedule);
  }

  @override
  void didUpdateWidget(KDictationFieldOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_schedule);
      widget.controller?.addListener(_schedule);
    }
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    if (mounted) setState(() {});
  }

  void _measure() {
    if (!mounted || !_active) return;
    RenderEditable? editable;
    void visit(RenderObject object) {
      if (object is RenderEditable) {
        editable = object;
      } else {
        object.visitChildren(visit);
      }
    }

    final render = _fieldKey.currentContext?.findRenderObject();
    if (render != null) visit(render);
    if (_editable != editable) {
      _editable?.offset.removeListener(_schedule);
      _editable = editable;
      _editable?.offset.addListener(_schedule);
    }
    final stack = _stackKey.currentContext?.findRenderObject();
    if (editable == null || stack is! RenderBox || !editable!.hasSize) return;
    final length = editable!.text?.toPlainText().length ?? 0;
    final offset = (widget.offset ?? editable!.selection?.baseOffset ?? length)
        .clamp(0, length);
    final rect = editable!.getLocalRectForCaret(TextPosition(offset: offset));
    final origin = editable!.localToGlobal(rect.topLeft, ancestor: stack);
    final caret = origin & rect.size;
    if (_caret != caret) setState(() => _caret = caret);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_schedule);
    _editable?.offset.removeListener(_schedule);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _schedule();
        return false;
      },
      child: Stack(
        key: _stackKey,
        clipBehavior: Clip.hardEdge,
        children: [
          KeyedSubtree(key: _fieldKey, child: widget.child),
          if (_active && _caret != null)
            Positioned(
              left: _caret!.left,
              top: _caret!.top,
              height: _caret!.height,
              child: KDictationAnchor(state: widget.state!),
            ),
        ],
      ),
    );
  }
}
