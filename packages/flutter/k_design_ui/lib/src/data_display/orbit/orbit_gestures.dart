import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'orbit_models.dart';
import 'orbit_projection.dart';

typedef KOrbitGestureResult = ({
  KOrbitViewState view,
  Offset inertia,
  Duration? lastDragAt,
});

KOrbitViewState? kOrbitViewForKey(
  LogicalKeyboardKey key,
  KOrbitViewState view,
) {
  const step = .12;
  if (key == LogicalKeyboardKey.arrowLeft) {
    return view.copyWith(yaw: view.yaw - step);
  }
  if (key == LogicalKeyboardKey.arrowRight) {
    return view.copyWith(yaw: view.yaw + step);
  }
  if (key == LogicalKeyboardKey.arrowUp) {
    return view.copyWith(pitch: view.pitch - step);
  }
  if (key == LogicalKeyboardKey.arrowDown) {
    return view.copyWith(pitch: view.pitch + step);
  }
  if (key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.equal) {
    return view.copyWith(zoom: view.zoom * 1.12);
  }
  if (key == LogicalKeyboardKey.minus) {
    return view.copyWith(zoom: view.zoom / 1.12);
  }
  return null;
}

KOrbitGestureResult? kOrbitGestureUpdate({
  required ScaleUpdateDetails details,
  required Size size,
  required KOrbitInteractionMode interactionMode,
  required KOrbitViewState currentView,
  required KOrbitViewState? gestureStart,
  required double gestureZoom,
  required Duration? now,
  required Duration? lastDragAt,
  required bool reducedMotion,
  required double minZoom,
  required double maxZoom,
}) {
  if (interactionMode == KOrbitInteractionMode.embedded &&
      details.pointerCount < 2) {
    return null;
  }
  if (details.pointerCount > 1) {
    return (
      view: kOrbitZoomAt(
        view: currentView,
        zoom: gestureZoom * details.scale,
        focalPoint: details.localFocalPoint,
        viewportCenter: size.center(Offset.zero),
        minZoom: minZoom,
        maxZoom: maxZoom,
      ),
      inertia: Offset.zero,
      lastDragAt: now,
    );
  }
  final seconds = now == null || lastDragAt == null
      ? 1 / 60
      : math.max(
          .008,
          (now - lastDragAt).inMicroseconds / Duration.microsecondsPerSecond,
        );
  final delta = details.focalPointDelta;
  final view = (gestureStart ?? currentView).copyWith(
    yaw: (gestureStart ?? currentView).yaw + delta.dx * .008,
    pitch: (gestureStart ?? currentView).pitch + delta.dy * .008,
  );
  return (
    view: view,
    inertia: reducedMotion
        ? Offset.zero
        : Offset(
            (delta.dx * .008 / seconds).clamp(-3, 3),
            (delta.dy * .008 / seconds).clamp(-3, 3),
          ),
    lastDragAt: now,
  );
}
