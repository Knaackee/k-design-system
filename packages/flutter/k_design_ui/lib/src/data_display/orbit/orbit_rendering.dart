part of 'k_orbit.dart';

// Shared rendering keeps paint, labels and hit targets on the same camera.
extension _KOrbitRendering on _KOrbitState {
  KOrbitSceneProjection _scene(Size size) {
    if (_frame != null && _frameSize == size) return _frame!;
    _frameSize = size;
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final duration = _reduceMotion
        ? Duration.zero
        : tokens.componentOrbitMotionTransitionDuration;
    final nodes = _presentation.animateProgress(
      nodes: _nodeTransition.nodes,
      now: _clock,
      duration: duration,
    );
    final angles = widget.elapsedSeconds == null ? _angles : <String, double>{};
    if (widget.elapsedSeconds != null) {
      advanceKOrbitAngles(
        angles: angles,
        levels: _nodeTransition.levels,
        nodes: nodes,
        delta: widget.elapsedSeconds!,
        speed: widget.motionSpeed,
        maxAngularSpeed: widget.maxAngularSpeed,
      );
    }
    KOrbitSceneProjection project(KOrbitViewState view) => projectKOrbitScene(
      size: size,
      levels: _nodeTransition.levels,
      nodes: nodes,
      connections: widget.connections,
      view: view,
      timeSeconds: _displayTime,
      radiusRatio: tokens.componentOrbitCenterRadiusRatio,
      extentOverride: _nodeTransition.extentOverride,
      angles: angles,
    );
    _renderedView = _presentation.resolveCamera(
      target: _currentView,
      pinnedId: _pinned,
      followOffset: (view) {
        final point = project(view).node(_pinned ?? '')?.point.offset;
        return point == null
            ? view.offset
            : view.offset + size.center(Offset.zero) - point;
      },
      now: _clock,
      duration: duration,
    );
    return _frame = project(_renderedView!);
  }

  KOrbitViewState _viewFor(Size size) {
    _scene(size);
    return _renderedView!;
  }

  Widget _buildStage(KDesignTokens tokens) => KOrbitStage(
    label: widget.labels.stage,
    focusNode: _focus,
    onPointerDown: _mouseDown,
    onPointerMove: _mouseMove,
    onPointerEnd: (event) {
      if (event.pointer != _mousePointer) return;
      if (event is PointerCancelEvent) _inertia = Offset.zero;
      _mousePointer = null;
      _endInteraction();
    },
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
      if (_mouseInput) return;
      _gestureStart = _currentView;
      _gestureZoom = _currentView.zoom;
      _startInteraction();
    },
    onScaleUpdate: _updateGesture,
    onScaleEnd: (_) {
      if (!_mouseInput) _endInteraction();
    },
    painter: KOrbitPainter(
      levels: _nodeTransition.levels,
      nodes: _nodeTransition.nodes,
      connections: widget.connections,
      view: () => _currentView,
      orbitTimeSeconds: () => _displayTime,
      signalTimeSeconds: () => _signals.time,
      signals: () => _signals.active,
      sceneFor: _scene,
      viewFor: _viewFor,
      opacityFor: _nodeTransition.opacityFor,
      scaleFor: _nodeTransition.scaleFor,
      isDeparting: _nodeTransition.isDeparting,
      tokens: tokens,
      style: widget.visualStyle,
      reducedMotion: _reduceMotion,
      centerShader: _centerShader,
      extentOverride: _nodeTransition.extentOverride,
      repaint: _ticker,
    ),
    nodeLayer: KOrbitNodeLayer(
      sceneFor: _scene,
      labelVisibility: widget.labelVisibility,
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
      nodeActions: widget.nodeActions,
      repaint: _ticker,
    ),
  );

  void _updateGesture(ScaleUpdateDetails details, Size size) {
    if (_mouseInput) return;
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

  void _mouseDown(PointerDownEvent event, Size size) {
    _keyboardFocus = false;
    _mouseInput = event.kind == PointerDeviceKind.mouse;
    if (!_mouseInput ||
        (event.buttons != kPrimaryMouseButton &&
            event.buttons != kSecondaryMouseButton)) {
      return;
    }
    _mouseRotate = event.buttons == kSecondaryMouseButton;
    if (_mouseRotate && widget.nodeActions != null) {
      final tokens =
          Theme.of(context).extension<KDesignTokens>() ??
          KDesignTokens.orbitLight;
      final hit = kOrbitHitTest(
        scene: _scene(size),
        labels: const {},
        point: event.localPosition,
        hitTargetSize: tokens.componentOrbitNodeHitTargetSize,
        eligible: (item) => !_nodeTransition.isDeparting(item.node.id),
      );
      if (hit != null) return;
    }
    if (!_mouseRotate && _pinned != null) return;
    _mousePointer = event.pointer;
    _startInteraction();
  }

  void _mouseMove(PointerMoveEvent event, Size size) {
    if (event.pointer != _mousePointer) return;
    final delta = event.localDelta;
    final now = _ticker.lastElapsedDuration;
    final dt = now == null || _lastDragAt == null
        ? 1 / 60
        : math.max(
            .008,
            (now - _lastDragAt!).inMicroseconds /
                Duration.microsecondsPerSecond,
          );
    final view = _currentView;
    _setView(
      _mouseRotate
          ? view.copyWith(
              yaw: view.yaw + delta.dx * .008,
              pitch: view.pitch + delta.dy * .008,
            )
          : view.copyWith(offset: view.offset + delta),
    );
    _inertia = _reduceMotion || !_mouseRotate
        ? Offset.zero
        : Offset(
            (delta.dx * .008 / dt).clamp(-3, 3),
            (delta.dy * .008 / dt).clamp(-3, 3),
          );
    _lastDragAt = now;
  }
}
