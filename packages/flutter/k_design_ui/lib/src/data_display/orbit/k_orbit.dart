import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../../actions/k_menu_button.dart';

import 'orbit_controller.dart';
import 'orbit_controls.dart';
import 'orbit_gestures.dart';
import 'orbit_models.dart';
import 'orbit_node_layer.dart';
import 'orbit_painter.dart';
import 'orbit_projection.dart';
import 'orbit_stage.dart';
import 'orbit_transition.dart';
import 'orbit_motion.dart';
import 'orbit_layout.dart';
import 'orbit_presentation.dart';
import 'orbit_signals.dart';

part 'orbit_rendering.dart';

class KOrbit extends StatefulWidget {
  const KOrbit({
    required this.levels,
    required this.nodes,
    required this.connections,
    this.controller,
    this.autoLayout = false,
    this.layoutGap = 12,
    this.viewState,
    this.initialViewState = const KOrbitViewState(),
    this.selectedNodeId,
    this.pinnedNodeId,
    this.onPinnedChange,
    this.maxAngularSpeed = 12,
    this.labelVisibility = KOrbitLabelVisibility.interaction,
    this.initialSelectedNodeId,
    this.selectionControlled = false,
    this.onNodeActivate,
    this.nodeActions,
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
    this.showControls = false,
    this.centerContent,
    this.visualStyle = const KOrbitVisualStyle(),
    this.labels = const KOrbitLabels(),
    super.key,
  });

  final List<KOrbitLevel> levels;
  final List<KOrbitNode> nodes;
  final List<KOrbitConnection> connections;
  final KOrbitController? controller;
  final bool autoLayout;
  final double layoutGap;
  final KOrbitViewState? viewState;
  final KOrbitViewState initialViewState;
  final String? selectedNodeId, initialSelectedNodeId;
  final bool selectionControlled, paused, showControls;
  final ValueChanged<KOrbitNode>? onNodeActivate;
  final List<KMenuAction> Function(KOrbitNode)? nodeActions;
  final ValueChanged<String?>? onSelectionChange;
  final ValueChanged<KOrbitViewState>? onViewChange;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;
  final void Function(String id, KOrbitSignalEndReason reason)? onSignalEnd;
  final ValueChanged<double>? onMotionSpeedChange;
  final ValueChanged<bool>? onPausedChange;
  final String? pinnedNodeId;
  final ValueChanged<String?>? onPinnedChange;
  final KOrbitLabelVisibility labelVisibility;
  final double motionSpeed, maxAngularSpeed;
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
  late KOrbitLayout _layout;
  KOrbitLayout _resolveLayout() => widget.autoLayout
      ? layoutKOrbit(widget.levels, widget.nodes, gap: widget.layoutGap)
      : KOrbitLayout(levels: widget.levels, nodes: widget.nodes);
  late KOrbitViewState _view;
  String? _selectedNodeId;
  late final KOrbitSignals _signals;
  final _angles = <String, double>{};
  final _presentation = KOrbitPresentation();
  KOrbitSceneProjection? _frame;
  Size? _frameSize;
  KOrbitViewState? _renderedView;
  double _clock = 0;
  final FocusNode _focus = FocusNode();
  Duration? _lastElapsed, _lastDragAt;
  double _orbitTime = 0;
  bool _interacting = false, _shaderRequested = false;
  bool _contextMenuOpen = false;
  Offset _inertia = Offset.zero;
  int? _mousePointer;
  bool _mouseInput = false, _mouseRotate = false, _keyboardFocus = false;
  double _gestureZoom = 1;
  ui.FragmentShader? _centerShader;
  Duration _travelDuration = Duration.zero;

  KOrbitViewState get _currentView => _bounded(widget.viewState ?? _view);
  String? get _pinned => widget.nodes.any((n) => n.id == widget.pinnedNodeId)
      ? widget.pinnedNodeId
      : null;
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
    _view = _bounded(widget.initialViewState);
    _signals = KOrbitSignals(
      (id, reason) => widget.onSignalEnd?.call(id, reason),
    );
    _selectedNodeId = widget.initialSelectedNodeId;
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    )..addListener(_tick);
    _layout = _resolveLayout();
    if (_pinned != null) _view = _bounded(_view.copyWith(zoom: _followZoom()));
    _nodeTransition = KOrbitNodeTransition(
      vsync: this,
      initialNodes: _layout.nodes,
      initialLevels: _layout.levels,
    )..addListener(_transitionChanged);
    _attachController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_shaderRequested &&
        widget.nodes.any(
          (node) => node.appearance == KOrbitNodeAppearance.sphere,
        )) {
      _shaderRequested = true;
      _loadCenterShader();
    }
    if (!TickerMode.getValuesNotifier(context).value.enabled) {
      _signals.cancelAll();
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
    if (!_shaderRequested &&
        widget.nodes.any(
          (node) => node.appearance == KOrbitNodeAppearance.sphere,
        )) {
      _shaderRequested = true;
      _loadCenterShader();
    }
    final previousLayout = _layout;
    _layout = _resolveLayout();
    _nodeTransition.update(
      oldLevels: previousLayout.levels,
      levels: _layout.levels,
      oldNodes: previousLayout.nodes,
      nodes: _layout.nodes,
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
    _signals.reconcile(widget.nodes, widget.connections);
    if (_pinned != null && oldWidget.pinnedNodeId != _pinned) {
      _setView(_currentView.copyWith(zoom: _followZoom()));
    }
    if (oldWidget.pinnedNodeId != null && _pinned == null) {
      _inertia = Offset.zero;
      _setView(widget.initialViewState.copyWith(offset: Offset.zero));
    }
    if (widget.pinnedNodeId != null && _pinned == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPinnedChange?.call(null);
      });
    }
    _frame = null;
  }

  void _validateConfiguration() {
    validateKOrbit(
      levels: widget.levels,
      nodes: widget.nodes,
      connections: widget.connections,
    );
    if (!widget.maxAngularSpeed.isFinite || widget.maxAngularSpeed < 0) {
      throw ArgumentError.value(widget.maxAngularSpeed, 'maxAngularSpeed');
    }
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
    cancel: _signals.cancel,
    cancelAll: _signals.cancelAll,
    resetView: _resetView,
  );

  void _transitionChanged() {
    _frame = null;
    if (mounted) setState(() {});
  }

  void _tick() {
    final elapsed = _ticker.lastElapsedDuration;
    if (elapsed == null) return;
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (_contextMenuOpen) return;
    if (previous == null) return;
    final realDelta =
        (elapsed - previous).inMicroseconds / Duration.microsecondsPerSecond;
    final delta = math.min(.05, realDelta);
    _clock += realDelta * 1000;
    _frame = null;
    _signals.advance(realDelta);
    if (widget.paused ||
        widget.motionSpeed == 0 ||
        _interacting ||
        (_keyboardFocus && _focus.hasFocus && _pinned == null)) {
      return;
    }
    if (widget.elapsedSeconds == null && !_reduceMotion) {
      _orbitTime += delta;
      advanceKOrbitAngles(
        angles: _angles,
        levels: _nodeTransition.levels,
        nodes: _nodeTransition.nodes,
        delta: delta,
        speed: widget.motionSpeed,
        maxAngularSpeed: widget.maxAngularSpeed,
        synchronizeLevels: widget.autoLayout,
      );
    }
    if (!_reduceMotion && _inertia != Offset.zero) {
      _setView(
        _currentView.copyWith(
          yaw: _currentView.yaw + _inertia.dx * delta,
          pitch: _currentView.pitch + _inertia.dy * delta,
        ),
      );
      _inertia *= math.pow(.05, delta).toDouble();
      if (_inertia.distance < .001) _inertia = Offset.zero;
    }
  }

  KOrbitSignalTriggerResult _triggerSignal(KOrbitSignal signal) =>
      _signals.trigger(
        signal,
        nodes: widget.nodes,
        connections: widget.connections,
        capacity: widget.maxActiveSignals,
        defaultDuration: _travelDuration,
        visible: TickerMode.getValuesNotifier(context).value.enabled,
      );

  double _followZoom() =>
      kOrbitExtentFor(levels: _layout.levels, nodes: _layout.nodes) /
      kOrbitExtentFor(
        levels: _layout.levels,
        nodes: _layout.nodes,
        rootId: _pinned,
      );

  KOrbitViewState _bounded(KOrbitViewState view) => view.copyWith(
    pitch: view.pitch.clamp(-math.pi / 2, math.pi / 2),
    zoom: view.zoom.clamp(widget.minZoom, widget.maxZoom),
  );

  void _setView(KOrbitViewState view) {
    final bounded = _bounded(view);
    _frame = null;
    if (widget.viewState == null) setState(() => _view = bounded);
    widget.onViewChange?.call(bounded);
  }

  void _resetView() {
    _inertia = Offset.zero;
    widget.onPinnedChange?.call(null);
    _setView(widget.initialViewState.copyWith(offset: Offset.zero));
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
    _keyboardFocus = true;
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
    _frame = null;
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

  @override
  void dispose() {
    widget.controller?.detach();
    _ticker.dispose();
    _nodeTransition.dispose();
    _focus.dispose();
    _signals.active.clear();
    super.dispose();
  }
}
