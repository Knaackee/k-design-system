import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:maplibre/maplibre.dart' as maplibre;

import 'k_map_controller.dart';
import 'k_map_default_pin.dart';
import 'k_map_pin_drag.dart';
import 'k_map_pin_move_coordinator.dart';
export 'k_map_pin_move_coordinator.dart';
import 'k_map_overlays.dart';

/// Coordinates overlay pins with the map's native multi-pointer gestures.
/// A second pointer cancels a pending or active pin drag before the map
/// recognizer receives the pinch sequence.
class KMapPinPointerRegistry {
  KMapPinPointerRegistry._();
  static final _scopes =
      <
        KMapController,
        ({Set<int> pointers, KMapInteractivePinState? active})
      >{};
  static ({Set<int> pointers, KMapInteractivePinState? active}) _scope(
    KMapController controller,
  ) => _scopes[controller] ??= (pointers: <int>{}, active: null);

  static bool hasPin(KMapController controller) =>
      _scopes[controller]?.active != null;

  static void pointerDown(KMapController controller, int pointer) {
    final scope = _scope(controller);
    scope.pointers.add(pointer);
    if (scope.pointers.length > 1) scope.active?._cancelForMultiPointer();
  }

  static void pointerUp(KMapController controller, int pointer) {
    final scope = _scope(controller);
    scope.pointers.remove(pointer);
    if (scope.pointers.isEmpty && scope.active == null) {
      _scopes.remove(controller);
    }
  }

  static bool claim(
    KMapController controller,
    KMapInteractivePinState state,
    int pointer,
  ) {
    final scope = _scope(controller);
    if (scope.pointers.length > 1) return false;
    scope.active?._cancelForMultiPointer();
    _scopes[controller] = (pointers: scope.pointers, active: state);
    return true;
  }

  static void release(
    KMapController controller,
    KMapInteractivePinState state,
  ) {
    final scope = _scope(controller);
    if (identical(scope.active, state)) {
      _scopes[controller] = (pointers: scope.pointers, active: null);
      if (scope.pointers.isEmpty) _scopes.remove(controller);
    }
  }
}

class KMapPinLayer extends StatelessWidget {
  const KMapPinLayer({
    required this.controller,
    required this.pins,
    required this.dragOptions,
    required this.onTap,
    this.selectedPinId,
    this.onPinMove,
    this.onDragStart,
    this.onDrag,
    this.onDragEnd,
    this.onDragCancel,
    this.pinBuilder,
    super.key,
  });

  final KMapController controller;
  final List<KMapPin> pins;
  final String? selectedPinId;
  final KMapPinDragOptions dragOptions;
  final KMapPinCallback onTap;
  final KMapPinMoveCallback? onPinMove;
  final KMapPinDragCallback? onDragStart;
  final KMapPinDragCallback? onDrag;
  final KMapPinDragCallback? onDragEnd;
  final KMapPinDragCallback? onDragCancel;
  final KMapPinBuilder? pinBuilder;

  @override
  Widget build(BuildContext context) => maplibre.WidgetLayer(
    allowInteraction: true,
    markers: [
      for (final pin in pins)
        maplibre.Marker(
          point: maplibre.Geographic(
            lon: pin.position.longitude,
            lat: pin.position.latitude,
          ),
          size: Size.square(pin.size + 40),
          alignment: pin.anchor == KMapPinAnchor.center
              ? Alignment.center
              : Alignment.bottomCenter,
          child: KMapInteractivePin(
            key: ValueKey('k-map-pin-${pin.id}'),
            controller: controller,
            pin: pin,
            selected: selectedPinId == pin.id,
            options: pin.drag ?? dragOptions,
            onTap: () => onTap(pin.id),
            onMove: onPinMove,
            onDragStart: onDragStart,
            onDrag: onDrag,
            onDragEnd: onDragEnd,
            onDragCancel: onDragCancel,
            builder: pinBuilder,
          ),
        ),
    ],
  );
}

// MapLibre.project() and native projection APIs already return map-local
// coordinates; WidgetLayer positions them in the map's own Stack. Applying the
// page origin here would offset every handle when a gallery/map is nested.
class KMapInteractivePin extends StatefulWidget {
  const KMapInteractivePin({
    required this.controller,
    required this.pin,
    required this.selected,
    required this.options,
    required this.onTap,
    this.onMove,
    this.onDragStart,
    this.onDrag,
    this.onDragEnd,
    this.onDragCancel,
    this.builder,
    super.key,
  });

  final KMapController controller;
  final KMapPin pin;
  final bool selected;
  final KMapPinDragOptions options;
  final VoidCallback onTap;
  final KMapPinMoveCallback? onMove;
  final KMapPinDragCallback? onDragStart;
  final KMapPinDragCallback? onDrag;
  final KMapPinDragCallback? onDragEnd;
  final KMapPinDragCallback? onDragCancel;
  final KMapPinBuilder? builder;

  @override
  State<KMapInteractivePin> createState() => KMapInteractivePinState();
}

class KMapInteractivePinState extends State<KMapInteractivePin>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int? _pointer;
  Offset? _origin;
  KMapPinDragSession? _session;
  Timer? _edgeTimer;
  bool _movingCamera = false;
  bool _committing = false;
  final _edgeClock = Stopwatch();
  int _edgeLastMicros = 0;
  Offset _offset = Offset.zero;
  bool _dragging = false;
  bool _suppressTap = false;
  final _moveCoordinator = KMapPinMoveCoordinator();
  late final AnimationController _rollback;
  Animation<Offset>? _rollbackOffset;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_cameraMoved);
    _rollback = AnimationController(vsync: this)
      ..addListener(() => setState(() => _offset = _rollbackOffset!.value));
  }

  @override
  void didUpdateWidget(covariant KMapInteractivePin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_cameraMoved);
      widget.controller.addListener(_cameraMoved);
    }
    if (oldWidget.pin.position != widget.pin.position && !_dragging) {
      _moveCoordinator.invalidate();
      _resetVisual();
    }
    if (_dragging && _session != null && widget.controller.viewport != null) {
      final projected = widget.controller.toScreenOffset(widget.pin.position);
      if (projected != null) {
        _offset =
            _session!.localAnchor(widget.controller.viewport!) - projected;
      }
    }
    if (!widget.pin.draggable && _dragging && _pointer != null) {
      _pointerCancel(PointerCancelEvent(pointer: _pointer!));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _edgeTimer?.cancel();
    KMapPinPointerRegistry.release(widget.controller, this);
    widget.controller.removeListener(_cameraMoved);
    _rollback.dispose();
    super.dispose();
  }

  void _pointerDown(PointerDownEvent event) {
    if (!widget.pin.draggable || _committing) return;
    if (!KMapPinPointerRegistry.claim(widget.controller, this, event.pointer)) {
      return;
    }
    if (_pointer != null && _pointer != event.pointer && _dragging) {
      _pointerCancel(PointerCancelEvent(pointer: _pointer!));
      return;
    }
    if (_pointer != null) {
      KMapPinPointerRegistry.release(widget.controller, this);
      return;
    }
    _suppressTap = false;
    _pointer = event.pointer;
    _origin = event.position;
    final projected = widget.controller.toScreenOffset(widget.pin.position);
    final viewport = widget.controller.viewport;
    if (projected != null && viewport != null) {
      _session = KMapPinDragSession(
        pointer: event.position,
        projected: projected,
        viewport: viewport,
      );
    }
    if (widget.options.activation == KMapPinDragActivation.drag) return;
    _timer = Timer(widget.options.longPressDuration, () {
      if (!mounted || _pointer == null) return;
      setState(() => _dragging = true);
      _startDrag();
    });
  }

  void _pointerMove(PointerMoveEvent event) {
    if (_pointer != event.pointer || _origin == null) return;
    _session?.pointer = event.position;
    final next = event.position - _origin!;
    if (!_dragging) {
      if (widget.options.activation == KMapPinDragActivation.drag) {
        if (next.distance <= 3) return;
        setState(() => _dragging = true);
        _startDrag();
      } else {
        if (next.distance > 8) _cancelPointer();
        return;
      }
    }
    _previewDrag();
  }

  void _pointerUp(PointerEvent event) {
    if (_pointer != event.pointer) return;
    KMapPinPointerRegistry.release(widget.controller, this);
    _timer?.cancel();
    if (!_dragging) {
      _cancelPointer();
      return;
    }
    final position = _dragPosition() ?? widget.pin.position;
    final dragEvent = _event(position);
    final session = _session;
    _committing = true;
    _edgeTimer?.cancel();
    _pointer = null;
    _origin = null;
    _suppressTap = true;
    setState(() => _dragging = false);
    Future<void>(() async {
      await _moveCoordinator.commit(
        callback: widget.onMove,
        event: dragEvent,
        rollback: _rollbackToHost,
      );
      if (mounted && identical(_session, session)) {
        widget.onDragEnd?.call(dragEvent);
        _session = null;
        _committing = false;
        _resetVisual();
      }
    });
  }

  void _pointerCancel(PointerEvent event) {
    if (_pointer != event.pointer) return;
    KMapPinPointerRegistry.release(widget.controller, this);
    _timer?.cancel();
    if (_dragging) {
      final position = _dragPosition() ?? widget.pin.position;
      widget.onDragCancel?.call(_event(position));
      _suppressTap = true;
      _rollbackToHost();
    }
    _edgeTimer?.cancel();
    _session = null;
    _pointer = null;
    _origin = null;
    if (mounted) setState(() => _dragging = false);
  }

  void _cancelForMultiPointer() {
    final pointer = _pointer;
    if (pointer == null) return;
    _suppressTap = true;
    _pointerCancel(PointerCancelEvent(pointer: pointer));
  }

  void _startDrag() {
    widget.onDragStart?.call(_event(widget.pin.position));
    if (widget.options.edgePan != null) {
      _edgeClock
        ..reset()
        ..start();
      _edgeLastMicros = 0;
      _edgeTimer = Timer.periodic(
        const Duration(milliseconds: 16),
        (_) => _edgePan(),
      );
    }
  }

  KMapCenter? _dragPosition() {
    final session = _session, viewport = widget.controller.viewport;
    return session == null || viewport == null
        ? null
        : widget.controller.toMapCenter(session.localAnchor(viewport));
  }

  void _previewDrag() {
    final session = _session, viewport = widget.controller.viewport;
    if (!_dragging || session == null || viewport == null) return;
    final projected = widget.controller.toScreenOffset(widget.pin.position);
    if (projected != null) {
      setState(() => _offset = session.localAnchor(viewport) - projected);
    }
    final position = _dragPosition();
    if (position != null) widget.onDrag?.call(_event(position));
  }

  void _cameraMoved() {
    if (mounted && _dragging) _previewDrag();
  }

  Future<void> _edgePan() async {
    final viewport = widget.controller.viewport, session = _session;
    final options = widget.options.edgePan, view = widget.controller.view;
    if (!_dragging ||
        _movingCamera ||
        viewport == null ||
        session == null ||
        options == null ||
        view == null) {
      return;
    }
    final velocity = kMapEdgePanVelocity(
      session.pointer - viewport.topLeft,
      viewport.size,
      options,
    );
    if (velocity == Offset.zero) return;
    final micros = _edgeClock.elapsedMicroseconds;
    final seconds = ((micros - _edgeLastMicros) / 1000000)
        .clamp(0, .032)
        .toDouble();
    _edgeLastMicros = micros;
    final center = widget.controller.toMapCenter(
      viewport.size.center(Offset.zero) + velocity * seconds,
    );
    _movingCamera = true;
    try {
      await widget.controller.moveCamera(
        center: center,
        zoom: kMapEdgePanZoom(view.zoom, options, seconds),
      );
      if (mounted && _dragging && identical(_session, session)) {
        widget.controller.updateView();
        _previewDrag();
      }
    } on Object {
      // The renderer may detach while an edge-pan camera request is in flight.
      if (identical(_session, session)) _edgeTimer?.cancel();
    } finally {
      _movingCamera = false;
    }
  }

  KMapCenter? _positionFor(Offset delta) {
    final origin = widget.controller.toScreenOffset(widget.pin.position);
    return origin == null
        ? null
        : widget.controller.toMapCenter(origin + delta);
  }

  KMapPinMove _event(
    KMapCenter position, [
    KMapPinMoveSource source = KMapPinMoveSource.drag,
  ]) => KMapPinMove(id: widget.pin.id, position: position, source: source);

  void _cancelPointer() {
    _timer?.cancel();
    _pointer = null;
    _origin = null;
  }

  Future<void> _rollbackToHost() async {
    if (!mounted) return;
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final duration = widget.options.animationDuration ?? tokens.motionStandard;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion || duration == Duration.zero) {
      _resetVisual();
      return;
    }
    _rollback.duration = duration;
    _rollbackOffset = Tween<Offset>(
      begin: _offset,
      end: Offset.zero,
      // k-ui-rules-ignore raw-motion: drag rollback overshoot follows the release velocity
    ).animate(CurvedAnimation(parent: _rollback, curve: Curves.easeOutBack));
    await _rollback.forward(from: 0);
  }

  void _resetVisual() {
    _rollback.stop();
    if (mounted) setState(() => _offset = Offset.zero);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _dragging &&
        _pointer != null) {
      _pointerCancel(PointerCancelEvent(pointer: _pointer!));
      return KeyEventResult.handled;
    }
    if (!widget.pin.draggable || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final step =
        widget.options.keyboardStep *
        (HardwareKeyboard.instance.isShiftPressed ? 10 : 1);
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => Offset(-step, 0),
      LogicalKeyboardKey.arrowRight => Offset(step, 0),
      LogicalKeyboardKey.arrowUp => Offset(0, -step),
      LogicalKeyboardKey.arrowDown => Offset(0, step),
      _ => null,
    };
    if (delta == null) return KeyEventResult.ignored;
    final nextOffset = _offset + delta;
    final position = _positionFor(nextOffset);
    if (position != null) {
      setState(() => _offset = nextOffset);
      final move = _event(position, KMapPinMoveSource.keyboard);
      Future<void>(
        () => _moveCoordinator.commit(
          callback: widget.onMove,
          event: move,
          rollback: _rollbackToHost,
        ),
      );
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final state = KMapPinState(
      selected: widget.selected,
      draggable: widget.pin.draggable,
      dragging: _dragging,
    );
    final scale = _dragging ? widget.options.scale : 1.0;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.pin.label,
      hint: !widget.pin.draggable
          ? null
          : widget.options.activation == KMapPinDragActivation.drag
          ? 'Zum Verschieben ziehen'
          : 'Zum Verschieben gedrückt halten',
      child: Focus(
        onKeyEvent: _onKey,
        child: Listener(
          behavior: HitTestBehavior.deferToChild,
          onPointerDown: _pointerDown,
          onPointerMove: _pointerMove,
          onPointerUp: _pointerUp,
          onPointerCancel: _pointerCancel,
          child: Align(
            alignment: widget.pin.anchor == KMapPinAnchor.center
                ? Alignment.center
                : Alignment.bottomCenter,
            child: SizedBox.square(
              dimension: widget.pin.size < 44 ? 44 : widget.pin.size,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Claim handle drags before the native platform view receives
                // the gesture; raw pointer events retain the fixed grab anchor.
                onPanUpdate:
                    widget.pin.draggable &&
                        widget.options.activation == KMapPinDragActivation.drag
                    ? (_) {}
                    : null,
                onTap: () {
                  if (_suppressTap) {
                    _suppressTap = false;
                    return;
                  }
                  widget.onTap();
                },
                child: Transform.translate(
                  offset: _offset,
                  child: Transform.scale(
                    scale: scale,
                    alignment: widget.pin.anchor == KMapPinAnchor.center
                        ? Alignment.center
                        : Alignment.bottomCenter,
                    child: Center(
                      child:
                          widget.builder?.call(context, widget.pin, state) ??
                          widget.pin.child ??
                          KMapDefaultPin(
                            pin: widget.pin,
                            selected: widget.selected,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
