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
  required KOrbitViewState currentView,
  required double gestureZoom,
  required Duration? now,
  required double minZoom,
  required double maxZoom,
}) {
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
  return (
    view: currentView.copyWith(
      offset: currentView.offset + details.focalPointDelta,
    ),
    inertia: Offset.zero,
    lastDragAt: now,
  );
}
