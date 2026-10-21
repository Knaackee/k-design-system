import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'k_map_controller.dart';
import 'k_map_pin.dart';

/// Editable overlays consume their first pointer before it can hit the native
/// map. Own pan/scale for this surface so every pinch has both pointers, even
/// after a handle has already won its drag arena. Taps still use the renderer.
class KMapGestureSurface extends StatefulWidget {
  const KMapGestureSurface({
    required this.controller,
    required this.child,
    super.key,
  });

  final KMapController controller;
  final Widget child;

  @override
  State<KMapGestureSurface> createState() => _KMapGestureSurfaceState();
}

class _KMapGestureSurfaceState extends State<KMapGestureSurface> {
  final _pointers = <int, Offset>{};
  Offset? _lastFocal;
  double? _initialSpan;
  double? _initialZoom;
  KMapCenter? _anchor;
  bool _multiple = false;
  bool _handle = false;
  bool _moving = false;
  bool _panStarted = false;
  KMapCenter? _panAnchor;
  double? _panZoom;
  ({Offset focal, double zoom, KMapCenter anchor})? _pending;

  Offset get _focal =>
      _pointers.values.reduce((a, b) => a + b) / _pointers.length.toDouble();
  double get _span {
    final points = _pointers.values.take(2).toList();
    return (points[0] - points[1]).distance;
  }

  void _down(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _pointers[event.pointer] = event.position;
    _handle = _handle || KMapPinPointerRegistry.hasPin(widget.controller);
    KMapPinPointerRegistry.pointerDown(widget.controller, event.pointer);
    if (_pointers.length == 1) {
      _panAnchor = widget.controller.toMapCenter(
        event.position - (widget.controller.viewport?.topLeft ?? Offset.zero),
      );
      _panZoom = widget.controller.view?.zoom;
    }
    if (_pointers.length == 2) {
      _multiple = true;
      _initialSpan = _span;
      _initialZoom = widget.controller.view?.zoom;
      _anchor = widget.controller.toMapCenter(
        _focal - (widget.controller.viewport?.topLeft ?? Offset.zero),
      );
    }
    _lastFocal = _focal;
  }

  void _move(PointerMoveEvent event) {
    if (!_pointers.containsKey(event.pointer)) return;
    _pointers[event.pointer] = event.position;
    final viewport = widget.controller.viewport;
    final zoom = widget.controller.view?.zoom;
    if (viewport == null || zoom == null) return;
    final focal = _focal - viewport.topLeft;
    if (_multiple) {
      final span = _initialSpan, initialZoom = _initialZoom, anchor = _anchor;
      if (_pointers.length >= 2 &&
          span != null &&
          span > 0 &&
          initialZoom != null &&
          anchor != null) {
        _queueCamera(
          focal,
          (initialZoom + math.log(_span / span) / math.ln2).clamp(0.0, 22.0),
          anchor,
        );
      }
    } else if (!_handle && _lastFocal != null) {
      if (!_panStarted && (_focal - _lastFocal!).distance <= kTouchSlop) return;
      _panStarted = true;
      final anchor = _panAnchor;
      if (anchor != null) _queueCamera(focal, _panZoom ?? zoom, anchor);
    }
    if (_panStarted) _lastFocal = _focal;
  }

  // Serialize native calls and coalesce queued frames. Compute from the current
  // projection at execution time, keeping the geographic grab point under the
  // fingers without stale camera snapshots or native/controller double zoom.
  void _queueCamera(Offset focal, double zoom, KMapCenter anchor) {
    _pending = (focal: focal, zoom: zoom, anchor: anchor);
    if (!_moving) unawaited(_flushCamera());
  }

  Future<void> _flushCamera() async {
    _moving = true;
    try {
      while (mounted && _pending != null) {
        final next = _pending!;
        _pending = null;
        final controller = widget.controller;
        final viewport = controller.viewport;
        final view = controller.view;
        final projected = controller.toScreenOffset(next.anchor);
        if (viewport == null || view == null || projected == null) continue;
        final scale = math.pow(2, next.zoom - view.zoom).toDouble();
        final center = controller.toMapCenter(
          projected + (viewport.size.center(Offset.zero) - next.focal) / scale,
        );
        if (center == null) continue;
        await controller.moveCamera(center: center, zoom: next.zoom);
        if (mounted) controller.updateView();
      }
    } on Object {
      // As with native gestures, detaching a map ends the camera interaction.
      _pending = null;
    } finally {
      _moving = false;
    }
  }

  void _up(PointerEvent event) {
    KMapPinPointerRegistry.pointerUp(widget.controller, event.pointer);
    _pointers.remove(event.pointer);
    if (_pointers.isEmpty) {
      _lastFocal = null;
      _multiple = false;
      _handle = false;
      _panStarted = false;
      _panAnchor = null;
      _panZoom = null;
      _initialSpan = null;
      _initialZoom = null;
      _anchor = null;
    }
    // Once a pinch ends, its remaining finger must never resume a handle drag.
  }

  @override
  void dispose() {
    for (final pointer in _pointers.keys) {
      KMapPinPointerRegistry.pointerUp(widget.controller, pointer);
    }
    _pending = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    gestures: {
      _MapCameraGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<_MapCameraGestureRecognizer>(
            _MapCameraGestureRecognizer.new,
            (_) {},
          ),
    },
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: widget.child,
    ),
  );
}

/// Resolve map movement before the native platform view. Handle pan/tap
/// recognizers are descendants and retain their usual arena priority.
class _MapCameraGestureRecognizer extends OneSequenceGestureRecognizer {
  _MapCameraGestureRecognizer()
    : super(supportedDevices: {PointerDeviceKind.touch});
  final _origins = <int, Offset>{};

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    _origins[event.pointer] = event.position;
    if (_origins.length > 1) resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent &&
        _origins.containsKey(event.pointer) &&
        (event.position - _origins[event.pointer]!).distance > kTouchSlop) {
      resolve(GestureDisposition.accepted);
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _origins.remove(event.pointer);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    resolve(GestureDisposition.rejected);
  }

  @override
  String get debugDescription => 'editable map camera';
}
