import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class KOrbitStage extends StatelessWidget {
  const KOrbitStage({
    required this.label,
    required this.focusNode,
    required this.onKeyEvent,
    required this.onPointerSignal,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
    required this.painter,
    required this.nodeLayer,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerEnd,
    super.key,
  });

  final String label;
  final FocusNode focusNode;
  final KeyEventResult Function(FocusNode, KeyEvent) onKeyEvent;
  final void Function(PointerSignalEvent, Size) onPointerSignal;
  final GestureScaleStartCallback onScaleStart;
  final void Function(ScaleUpdateDetails, Size) onScaleUpdate;
  final GestureScaleEndCallback onScaleEnd;
  final CustomPainter painter;
  final Widget nodeLayer;
  final void Function(PointerDownEvent, Size)? onPointerDown;
  final void Function(PointerMoveEvent, Size)? onPointerMove;
  final void Function(PointerEvent)? onPointerEnd;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      return Semantics(
        container: true,
        label: label,
        child: Focus(
          focusNode: focusNode,
          onKeyEvent: onKeyEvent,
          child: Listener(
            onPointerDown: (event) => onPointerDown?.call(event, size),
            onPointerMove: (event) => onPointerMove?.call(event, size),
            onPointerUp: onPointerEnd,
            onPointerCancel: onPointerEnd,
            onPointerSignal: (event) => onPointerSignal(event, size),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => focusNode.requestFocus(),
              onScaleStart: onScaleStart,
              onScaleUpdate: (details) => onScaleUpdate(details, size),
              onScaleEnd: onScaleEnd,
              child: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: painter),
                    nodeLayer,
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
