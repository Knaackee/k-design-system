import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:maplibre/maplibre.dart' as maplibre;

import '../primitives/k_icon.dart';
import 'k_map_controller.dart';
import 'k_map_overlays.dart';

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
  final KMapPinBuilder? pinBuilder;

  @override
  Widget build(BuildContext context) => _MapLocalWidgetLayer(
    child: maplibre.WidgetLayer(
      allowInteraction: true,
      markers: [
        for (final pin in pins)
          maplibre.Marker(
            point: maplibre.Geographic(
              lon: pin.position.longitude,
              lat: pin.position.latitude,
            ),
            size: Size.square(pin.size + 40),
            alignment: Alignment.bottomCenter,
            child: _InteractivePin(
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
              builder: pinBuilder,
            ),
          ),
      ],
    ),
  );
}

/// MapLibre Web reports projected points in page coordinates while its widget
/// layer positions them inside the map-local stack. Remove the map's page
/// origin once at the KDS boundary; native projections are already local.
class _MapLocalWidgetLayer extends StatefulWidget {
  const _MapLocalWidgetLayer({required this.child});

  final Widget child;

  @override
  State<_MapLocalWidgetLayer> createState() => _MapLocalWidgetLayerState();
}

class _MapLocalWidgetLayerState extends State<_MapLocalWidgetLayer> {
  final _anchor = GlobalKey();
  Offset _pageOrigin = Offset.zero;
  bool _measurementScheduled = false;

  void _scheduleMeasurement() {
    if (!kIsWeb || _measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (!mounted) return;
      final box = _anchor.currentContext?.findRenderObject() as RenderBox?;
      final next = box?.localToGlobal(Offset.zero) ?? Offset.zero;
      if (next != _pageOrigin) setState(() => _pageOrigin = next);
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasurement();
    return SizedBox.expand(
      key: _anchor,
      child: Transform.translate(
        offset: kMapPinLayerTranslation(pageOrigin: _pageOrigin, isWeb: kIsWeb),
        child: widget.child,
      ),
    );
  }
}

@visibleForTesting
Offset kMapPinLayerTranslation({
  required Offset pageOrigin,
  required bool isWeb,
}) => isWeb ? -pageOrigin : Offset.zero;

class _InteractivePin extends StatefulWidget {
  const _InteractivePin({
    required this.controller,
    required this.pin,
    required this.selected,
    required this.options,
    required this.onTap,
    this.onMove,
    this.onDragStart,
    this.onDrag,
    this.onDragEnd,
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
  final KMapPinBuilder? builder;

  @override
  State<_InteractivePin> createState() => _InteractivePinState();
}

class _InteractivePinState extends State<_InteractivePin>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int? _pointer;
  Offset? _origin;
  Offset _offset = Offset.zero;
  bool _dragging = false;
  bool _suppressTap = false;
  final _moveCoordinator = KMapPinMoveCoordinator();
  late final AnimationController _rollback;
  Animation<Offset>? _rollbackOffset;

  @override
  void initState() {
    super.initState();
    _rollback = AnimationController(vsync: this)
      ..addListener(() => setState(() => _offset = _rollbackOffset!.value));
  }

  @override
  void didUpdateWidget(covariant _InteractivePin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pin.position != widget.pin.position) {
      _moveCoordinator.invalidate();
      _resetVisual();
    }
    if (!widget.pin.draggable && _dragging) _rollbackToHost();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rollback.dispose();
    super.dispose();
  }

  void _pointerDown(PointerDownEvent event) {
    if (!widget.pin.draggable || _pointer != null) return;
    _pointer = event.pointer;
    _origin = event.position;
    if (widget.options.activation == KMapPinDragActivation.drag) {
      setState(() => _dragging = true);
      widget.onDragStart?.call(_event(widget.pin.position));
      return;
    }
    _timer = Timer(widget.options.longPressDuration, () {
      if (!mounted || _pointer == null) return;
      setState(() => _dragging = true);
      widget.onDragStart?.call(_event(widget.pin.position));
    });
  }

  void _pointerMove(PointerMoveEvent event) {
    if (_pointer != event.pointer || _origin == null) return;
    final next = event.position - _origin!;
    if (!_dragging) {
      if (next.distance > 8) _cancelPointer();
      return;
    }
    setState(() => _offset = next);
    final position = _positionFor(next);
    if (position != null) widget.onDrag?.call(_event(position));
  }

  void _pointerUp(PointerEvent event) {
    if (_pointer != event.pointer) return;
    _timer?.cancel();
    if (!_dragging) {
      _cancelPointer();
      return;
    }
    final position = _positionFor(_offset) ?? widget.pin.position;
    final dragEvent = _event(position);
    widget.onDragEnd?.call(dragEvent);
    _pointer = null;
    _origin = null;
    _suppressTap = true;
    setState(() => _dragging = false);
    Future<void>(
      () => _moveCoordinator.commit(
        callback: widget.onMove,
        event: dragEvent,
        rollback: _rollbackToHost,
      ),
    );
  }

  void _pointerCancel(PointerEvent event) {
    if (_pointer != event.pointer) return;
    _timer?.cancel();
    if (_dragging) {
      final position = _positionFor(_offset) ?? widget.pin.position;
      widget.onDragEnd?.call(_event(position));
      _suppressTap = true;
      _rollbackToHost();
    }
    _pointer = null;
    _origin = null;
    if (mounted) setState(() => _dragging = false);
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
    ).animate(CurvedAnimation(parent: _rollback, curve: Curves.easeOutBack));
    await _rollback.forward(from: 0);
  }

  void _resetVisual() {
    _rollback.stop();
    if (mounted) setState(() => _offset = Offset.zero);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
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
      hint: widget.pin.draggable ? 'Zum Verschieben gedrückt halten' : null,
      child: Focus(
        onKeyEvent: _onKey,
        child: Listener(
          behavior: HitTestBehavior.deferToChild,
          onPointerDown: _pointerDown,
          onPointerMove: _pointerMove,
          onPointerUp: _pointerUp,
          onPointerCancel: _pointerCancel,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox.square(
              dimension: widget.pin.size < 44 ? 44 : widget.pin.size,
              child: GestureDetector(
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
                    alignment: Alignment.bottomCenter,
                    child: Center(
                      child:
                          widget.builder?.call(context, widget.pin, state) ??
                          widget.pin.child ??
                          _DefaultPin(
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

@visibleForTesting
class KMapPinMoveCoordinator {
  int _revision = 0;

  void invalidate() => _revision += 1;

  Future<void> commit({
    required KMapPinMoveCallback? callback,
    required KMapPinMove event,
    required FutureOr<void> Function() rollback,
  }) async {
    final request = ++_revision;
    try {
      final accepted = await callback?.call(event);
      if (accepted == false && request == _revision) {
        await rollback();
      }
    } on Object {
      if (request == _revision) await rollback();
    }
  }
}

class _DefaultPin extends StatelessWidget {
  const _DefaultPin({required this.pin, required this.selected});
  final KMapPin pin;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final color = pin.color ?? tokens.colorBrandPrimaryAccent;
    final radius = switch (pin.shape) {
      KMapPinShape.pin => BorderRadius.only(
        topLeft: Radius.circular(pin.size / 2),
        topRight: Radius.circular(pin.size / 2),
        bottomLeft: Radius.circular(pin.size / 2),
        bottomRight: Radius.zero,
      ),
      KMapPinShape.circle => BorderRadius.circular(pin.size / 2),
      KMapPinShape.square => BorderRadius.circular(tokens.radiusControl),
    };
    final tipOffset = pin.shape == KMapPinShape.pin
        ? pin.size / 1.41421356237 - (pin.size < 44 ? 44 : pin.size) / 2
        : 0.0;
    return Transform.translate(
      offset: Offset(0, -tipOffset),
      child: Transform.rotate(
        angle: pin.shape == KMapPinShape.pin ? .785398 : 0,
        child: AnimatedContainer(
          duration: tokens.motionStandard,
          width: pin.size,
          height: pin.size,
          decoration: BoxDecoration(
            color: tokens.colorSurfaceRaised,
            borderRadius: radius,
            border: Border.all(color: color, width: tokens.spaceHairline * 3),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: tokens.colorBrandPrimaryAccent,
                  spreadRadius: tokens.spaceHairline * 6,
                ),
              if (selected)
                BoxShadow(
                  color: tokens.colorSurfaceRaised,
                  spreadRadius: tokens.spaceHairline * 3,
                ),
              ...tokens.elevationMedium,
            ],
          ),
          child: Transform.rotate(
            angle: pin.shape == KMapPinShape.pin ? -.785398 : 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(pin.size),
              child: pin.image != null
                  ? Image(image: pin.image!, fit: BoxFit.cover)
                  : Center(
                      child: SizedBox.square(
                        dimension:
                            tokens.sizeIconDefault - tokens.spaceHairline * 4,
                        child: KIcon(
                          pin.icon ?? KIconName.mapPin,
                          size:
                              tokens.sizeIconDefault - tokens.spaceHairline * 4,
                          color: color,
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
