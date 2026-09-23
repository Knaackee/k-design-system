import 'package:flutter/material.dart';

class KCalendarPointerDrag<T extends Object> extends StatefulWidget {
  const KCalendarPointerDrag({
    required this.data,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.axis,
    required this.child,
    required this.onTouchSelect,
    required this.touchSelected,
    super.key,
  });
  final T data;
  final Widget child;
  final VoidCallback onTouchSelect;
  final bool touchSelected;
  final VoidCallback onStart;
  final ValueChanged<DragUpdateDetails> onUpdate;
  final ValueChanged<DraggableDetails> onEnd;
  final Axis? axis;
  @override
  State<KCalendarPointerDrag<T>> createState() =>
      KCalendarPointerDragState<T>();
}

class KCalendarPointerDragState<T extends Object>
    extends State<KCalendarPointerDrag<T>> {
  bool _moved = false;

  void startDrag() {
    _moved = false;
    widget.onTouchSelect();
  }

  void updateDrag(DragUpdateDetails details) {
    if (!_moved) {
      _moved = true;
      widget.onStart();
    }
    widget.onUpdate(details);
  }

  @override
  Widget build(BuildContext context) => LongPressDraggable<T>(
    delay: widget.touchSelected
        ? Duration.zero
        : const Duration(milliseconds: 500),
    data: widget.data,
    axis: widget.axis,
    feedback: const SizedBox.shrink(),
    dragAnchorStrategy: pointerDragAnchorStrategy,
    onDragStarted: startDrag,
    onDragUpdate: updateDrag,
    onDragEnd: widget.onEnd,
    childWhenDragging: widget.child,
    child: widget.child,
  );
}
