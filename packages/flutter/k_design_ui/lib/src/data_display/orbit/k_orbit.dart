import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'orbit_controller.dart';
import 'orbit_controls.dart';
import 'orbit_gestures.dart';
import 'orbit_models.dart';
import 'orbit_node_layer.dart';
import 'orbit_painter.dart';
import 'orbit_projection.dart';
import 'orbit_stage.dart';
import 'orbit_transition.dart';

class KOrbit extends StatefulWidget {
  const KOrbit({
    required this.levels,
    required this.nodes,
    required this.connections,
    this.controller,
    this.viewState,
    this.initialViewState = const KOrbitViewState(),
    this.selectedNodeId,
    this.initialSelectedNodeId,
    this.selectionControlled = false,
    this.onNodeActivate,
    this.onSelectionChange,
    this.onViewChange,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.onSignalEnd,
    this.onMotionSpeedChange,
    this.onPausedChange,
    this.motionSpeed = 1,
    this.paused = false,
    this.elapsedSeconds,
    this.minZoom = 0.65,
    this.maxZoom = 2.2,
    this.maxActiveSignals = 32,
    this.reducedMotion,
    this.interactionMode = KOrbitInteractionMode.dedicated,
    this.showControls = true,
    this.centerContent,
    this.visualStyle = const KOrbitVisualStyle(),
    this.labels = const KOrbitLabels(),
    super.key,
  });

  final List<KOrbitLevel> levels;
  final List<KOrbitNode> nodes;
  final List<KOrbitConnection> connections;
  final KOrbitController? controller;
  final KOrbitViewState? viewState;
  final KOrbitViewState initialViewState;
  final String? selectedNodeId, initialSelectedNodeId;
  final bool selectionControlled, paused, showControls;
  final ValueChanged<KOrbitNode>? onNodeActivate;
  final ValueChanged<String?>? onSelectionChange;
  final ValueChanged<KOrbitViewState>? onViewChange;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;
  final void Function(String id, KOrbitSignalEndReason reason)? onSignalEnd;
  final ValueChanged<double>? onMotionSpeedChange;
  final ValueChanged<bool>? onPausedChange;
  final double motionSpeed;
  final double? elapsedSeconds;
  final double minZoom, maxZoom;
  final int maxActiveSignals;
  final bool? reducedMotion;
  final KOrbitInteractionMode interactionMode;
  final Widget? centerContent;
  final KOrbitVisualStyle visualStyle;
  final KOrbitLabels labels;

  @override
  State<KOrbit> createState() => _KOrbitState();
}

class _KOrbitState extends State<KOrbit> with TickerProviderStateMixin {
  late final AnimationController _ticker;
  late final KOrbitNodeTransition _nodeTransition;
  late KOrbitViewState _view;
  String? _selectedNodeId;
  final List<KOrbitActiveSignal> _signals = [];
  final FocusNode _focus = FocusNode();
  Duration? _lastElapsed, _lastDragAt;
  double _orbitTime = 0, _signalTime = 0;
  bool _interacting = false, _shaderRequested = false;
  Offset _inertia = Offset.zero;
  double _gestureZoom = 1;
  KOrbitViewState? _gestureStart;
  ui.FragmentShader? _centerShader;
  Duration _travelDuration = Duration.zero;

  KOrbitViewState get _currentView => widget.viewState ?? _view;
  String? get _currentSelection =>
      widget.selectionControlled ? widget.selectedNodeId : _selectedNodeId;
  bool get _reduceMotion =>
      widget.reducedMotion ??
      MediaQuery.maybeOf(context)?.disableAnimations ??
      false;
  double get _displayTime => widget.elapsedSeconds ?? _orbitTime;

  @override
  void initState() {
    super.initState();
    _validateConfiguration();
    _view = widget.initialViewState;
    _selectedNodeId = widget.initialSelectedNodeId;
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    )..addListener(_tick);
    _nodeTransition = KOrbitNodeTransition(
      vsync: this,
      initialNodes: widget.nodes,
      initialLevels: widget.levels,
    )..addListener(_transitionChanged);
    _attachController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_shaderRequested) {
      _shaderRequested = true;
      _loadCenterShader();
    }
    if (!TickerMode.getValuesNotifier(context).value.enabled) {
      _cancelAll();
      _ticker.stop();
    } else if (!_ticker.isAnimating) {
      _lastElapsed = null;
      _ticker.repeat();
    }
  }

  Future<void> _loadCenterShader() async {
    try {
      ui.FragmentProgram program;
      try {
        program = await ui.FragmentProgram.fromAsset(
          'packages/k_design_ui/shaders/orbit_center.frag',
        );
      } catch (_) {
        program = await ui.FragmentProgram.fromAsset(
          'shaders/orbit_center.frag',
        );
      }
      if (mounted) setState(() => _centerShader = program.fragmentShader());
    } catch (_) {
      // The painter keeps its token-driven gradient fallback when shaders are unavailable.
    }
  }

  @override
  void didUpdateWidget(covariant KOrbit oldWidget) {
    super.didUpdateWidget(oldWidget);
    _validateConfiguration();
    _nodeTransition.update(
      oldLevels: oldWidget.levels,
      levels: widget.levels,
      oldNodes: oldWidget.nodes,
      nodes: widget.nodes,
      reducedMotion: _reduceMotion,
    );
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      _attachController();
    }
    final nodeIds = widget.nodes.map((node) => node.id).toSet();
    if (_currentSelection != null && !nodeIds.contains(_currentSelection)) {
      if (!widget.selectionControlled) setState(() => _selectedNodeId = null);
      widget.onSelectionChange?.call(null);
    }
    final connectionIds = widget.connections.map((item) => item.id).toSet();
    for (final signal in List<KOrbitActiveSignal>.of(_signals)) {
      if (!connectionIds.contains(signal.signal.connectionId)) {
        _cancelSignal(signal.signal.id);
      }
    }
  }

  void _validateConfiguration() {
    validateKOrbit(
      levels: widget.levels,
      nodes: widget.nodes,
      connections: widget.connections,
    );
    if (!widget.motionSpeed.isFinite || widget.motionSpeed < 0) {
      throw ArgumentError.value(
        widget.motionSpeed,
        'motionSpeed',
        'Must be finite and non-negative',
      );
    }
    if (widget.elapsedSeconds != null &&
        (!widget.elapsedSeconds!.isFinite || widget.elapsedSeconds! < 0)) {
      throw ArgumentError.value(widget.elapsedSeconds, 'elapsedSeconds');
    }
    if (!widget.minZoom.isFinite ||
        !widget.maxZoom.isFinite ||
        widget.minZoom <= 0 ||
        widget.minZoom > widget.maxZoom) {
      throw ArgumentError('Orbit zoom bounds are invalid');
    }
    if (widget.maxActiveSignals < 1) {
      throw ArgumentError.value(widget.maxActiveSignals, 'maxActiveSignals');
    }
  }

  void _attachController() => widget.controller?.attach(
    trigger: _triggerSignal,
    cancel: _cancelSignal,
    cancelAll: _cancelAll,
    resetView: _resetView,
  );

  void _transitionChanged() {
    if (mounted) setState(() {});
  }

  void _tick() {
    final elapsed = _ticker.lastElapsedDuration;
    if (elapsed == null) return;
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) return;
    final delta =
        (elapsed - previous).inMicroseconds /
        Duration.microsecondsPerSecond *
        widget.motionSpeed;
    if (widget.paused || widget.motionSpeed == 0) return;
    _signalTime += delta;
    if (widget.elapsedSeconds == null && !_reduceMotion && !_interacting) {
      _orbitTime += delta;
    }
    if (!_reduceMotion && !_interacting && _inertia != Offset.zero) {
      _setView(
        _currentView.copyWith(
          yaw: _currentView.yaw + _inertia.dx * delta,
          pitch: _currentView.pitch + _inertia.dy * delta,
        ),
      );
      final decay = math.pow(.05, delta).toDouble();
      _inertia *= decay;
      if (_inertia.distance < .001) _inertia = Offset.zero;
    }
    final complete = _signals.where((active) {
      final duration =
          active.duration.inMicroseconds / Duration.microsecondsPerSecond;
      return _signalTime - active.startedAt >= duration;
    }).toList();
    if (complete.isNotEmpty) {
      setState(() => _signals.removeWhere(complete.contains));
      for (final item in complete) {
        widget.onSignalEnd?.call(
          item.signal.id,
          KOrbitSignalEndReason.completed,
        );
      }
    }
  }

  KOrbitSignalTriggerResult _triggerSignal(KOrbitSignal signal) {
    if (widget.paused ||
        widget.motionSpeed == 0 ||
        !TickerMode.getValuesNotifier(context).value.enabled) {
      return KOrbitSignalTriggerResult.inactive;
    }
    if (signal.id.isEmpty ||
        (signal.duration != null && signal.duration! <= Duration.zero) ||
        _signals.any((active) => active.signal.id == signal.id) ||
        !widget.connections.any((item) => item.id == signal.connectionId)) {
      return KOrbitSignalTriggerResult.invalid;
    }
    if (_signals.length >= widget.maxActiveSignals) {
      return KOrbitSignalTriggerResult.capacity;
    }
    setState(() {
      _signals.add(
        KOrbitActiveSignal(
          signal: signal,
          startedAt: _signalTime,
          duration: signal.duration ?? _travelDuration,
        ),
      );
    });
    return KOrbitSignalTriggerResult.accepted;
  }

  bool _cancelSignal(String id) {
    final index = _signals.indexWhere((active) => active.signal.id == id);
    if (index < 0) return false;
    final signal = _signals[index];
    setState(() => _signals.removeAt(index));
    widget.onSignalEnd?.call(signal.signal.id, KOrbitSignalEndReason.cancelled);
    return true;
  }

  void _cancelAll() {
    final cancelled = List<KOrbitActiveSignal>.of(_signals);
    if (mounted && cancelled.isNotEmpty) setState(_signals.clear);
    for (final active in cancelled) {
      widget.onSignalEnd?.call(
        active.signal.id,
        KOrbitSignalEndReason.cancelled,
      );
    }
  }

  void _setView(KOrbitViewState view) {
    final bounded = view.copyWith(
      pitch: view.pitch.clamp(-math.pi / 2, math.pi / 2),
      zoom: view.zoom.clamp(widget.minZoom, widget.maxZoom),
      offset: Offset(
        view.offset.dx.clamp(-240, 240),
        view.offset.dy.clamp(-240, 240),
      ),
    );
    if (widget.viewState == null) setState(() => _view = bounded);
    widget.onViewChange?.call(bounded);
  }

  void _resetView() {
    _inertia = Offset.zero;
    _setView(widget.initialViewState);
  }

  void _select(KOrbitNode node) {
    if (node.disabled) return;
    if (!widget.selectionControlled) setState(() => _selectedNodeId = node.id);
    widget.onSelectionChange?.call(node.id);
    widget.onNodeActivate?.call(node);
  }

  void _startInteraction() {
    _focus.requestFocus();
    _interacting = true;
    _inertia = Offset.zero;
    _lastDragAt = _ticker.lastElapsedDuration;
    widget.onInteractionStart?.call();
  }

  void _endInteraction() {
    _interacting = false;
    _lastDragAt = null;
    widget.onInteractionEnd?.call();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.home) {
      _resetView();
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (!widget.selectionControlled) setState(() => _selectedNodeId = null);
      widget.onSelectionChange?.call(null);
    } else {
      final view = kOrbitViewForKey(event.logicalKey, _currentView);
      if (view == null) return KeyEventResult.ignored;
      _setView(view);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    _travelDuration = tokens.componentOrbitMotionTravelDuration;
    _nodeTransition.setDuration(tokens.componentOrbitMotionTransitionDuration);
    final stage = _buildStage(tokens);
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedStage = constraints.hasBoundedHeight
            ? Expanded(child: stage)
            : AspectRatio(aspectRatio: 1, child: stage);
        if (!widget.showControls) {
          return constraints.hasBoundedHeight ? stage : boundedStage;
        }
        return Column(
          mainAxisSize: constraints.hasBoundedHeight
              ? MainAxisSize.max
              : MainAxisSize.min,
          children: [
            boundedStage,
            KOrbitControls(
              paused: widget.paused,
              speed: widget.motionSpeed,
              labels: widget.labels,
              onReset: _resetView,
              onPauseChanged: widget.onPausedChange,
              onSpeedChanged: widget.onMotionSpeedChange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStage(KDesignTokens tokens) => KOrbitStage(
    label: widget.labels.stage,
    focusNode: _focus,
    onKeyEvent: _onKey,
    onPointerSignal: (event, size) {
      if (event is! PointerScrollEvent ||
          (!_focus.hasFocus &&
              widget.interactionMode != KOrbitInteractionMode.dedicated)) {
        return;
      }
      _setView(
        kOrbitZoomAt(
          view: _currentView,
          zoom: _currentView.zoom * math.exp(-event.scrollDelta.dy * .001),
          focalPoint: event.localPosition,
          viewportCenter: size.center(Offset.zero),
          minZoom: widget.minZoom,
          maxZoom: widget.maxZoom,
        ),
      );
    },
    onScaleStart: (_) {
      _gestureStart = _currentView;
      _gestureZoom = _currentView.zoom;
      _startInteraction();
    },
    onScaleUpdate: _updateGesture,
    onScaleEnd: (_) => _endInteraction(),
    painter: KOrbitPainter(
      levels: _nodeTransition.levels,
      nodes: _nodeTransition.nodes,
      connections: widget.connections,
      view: () => _currentView,
      orbitTimeSeconds: () => _displayTime,
      signalTimeSeconds: () => _signalTime,
      signals: () => _signals,
      tokens: tokens,
      style: widget.visualStyle,
      reducedMotion: _reduceMotion,
      centerShader: _centerShader,
      extentOverride: _nodeTransition.extentOverride,
      repaint: _ticker,
    ),
    nodeLayer: KOrbitNodeLayer(
      levels: _nodeTransition.levels,
      nodes: _nodeTransition.nodes,
      connections: widget.connections,
      view: () => _currentView,
      time: () => _displayTime,
      tokens: tokens,
      selectedId: _currentSelection,
      reducedMotion: _reduceMotion,
      centerContent: widget.centerContent,
      extentOverride: _nodeTransition.extentOverride,
      opacityFor: _nodeTransition.opacityFor,
      scaleFor: _nodeTransition.scaleFor,
      isDeparting: _nodeTransition.isDeparting,
      onActivate: _select,
      repaint: _ticker,
    ),
  );

  void _updateGesture(ScaleUpdateDetails details, Size size) {
    final now = _ticker.lastElapsedDuration;
    final result = kOrbitGestureUpdate(
      details: details,
      size: size,
      interactionMode: widget.interactionMode,
      currentView: _currentView,
      gestureStart: _gestureStart,
      gestureZoom: _gestureZoom,
      now: now,
      lastDragAt: _lastDragAt,
      reducedMotion: _reduceMotion,
      minZoom: widget.minZoom,
      maxZoom: widget.maxZoom,
    );
    if (result == null) return;
    _setView(result.view);
    _inertia = result.inertia;
    _lastDragAt = result.lastDragAt;
    if (details.pointerCount == 1) _gestureStart = _currentView;
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _ticker.dispose();
    _nodeTransition.dispose();
    _focus.dispose();
    _signals.clear();
    super.dispose();
  }
}
