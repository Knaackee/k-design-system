import 'dart:ui';

import 'orbit_models.dart';

class KOrbitPresentation {
  String? pinnedId;
  KOrbitViewState? view;
  _CameraReturn? _returning;
  final Map<String, _ProgressTransition> _progress = {};

  KOrbitViewState resolveCamera({
    required KOrbitViewState target,
    required String? pinnedId,
    required Offset Function(KOrbitViewState view) followOffset,
    required double now,
    required Duration duration,
  }) {
    if (this.pinnedId != null && pinnedId == null && view != null) {
      _returning = _CameraReturn(view!, now);
    }
    var resolved = target;
    if (pinnedId != null) {
      _returning = null;
      resolved = target.copyWith(offset: followOffset(target));
    } else if (_returning case final returning?) {
      final t = _ease(now, returning.startedAt, duration.inMilliseconds);
      resolved = KOrbitViewState(
        yaw: _mix(returning.from.yaw, target.yaw, t),
        pitch: _mix(returning.from.pitch, target.pitch, t),
        zoom: _mix(returning.from.zoom, target.zoom, t),
        offset: Offset.lerp(returning.from.offset, target.offset, t)!,
      );
      if (t == 1) _returning = null;
    }
    this.pinnedId = pinnedId;
    view = resolved;
    return resolved;
  }

  List<KOrbitNode> animateProgress({
    required List<KOrbitNode> nodes,
    required double now,
    required Duration duration,
  }) {
    final ids = nodes
        .where((node) => node.progress != null)
        .map((node) => node.id)
        .toSet();
    _progress.removeWhere((id, _) => !ids.contains(id));
    return [
      for (final node in nodes)
        if (node.progress == null)
          node
        else
          node.copyWith(progress: _animatedProgress(node, now, duration)),
    ];
  }

  double _animatedProgress(KOrbitNode node, double now, Duration duration) {
    final durationMs = duration.inMilliseconds;
    var transition = _progress[node.id];
    if (transition == null || durationMs == 0) {
      transition = _ProgressTransition(
        node.progress!,
        node.progress!,
        now,
        durationMs,
      );
    }
    final current = _mix(
      transition.from,
      transition.to,
      _ease(now, transition.startedAt, transition.durationMs),
    );
    if (node.progress != transition.to) {
      transition = _ProgressTransition(
        current,
        node.progress!,
        now,
        durationMs,
      );
    }
    _progress[node.id] = transition;
    return durationMs == 0
        ? node.progress!
        : _mix(
            transition.from,
            transition.to,
            _ease(now, transition.startedAt, transition.durationMs),
          );
  }
}

class _CameraReturn {
  const _CameraReturn(this.from, this.startedAt);
  final KOrbitViewState from;
  final double startedAt;
}

class _ProgressTransition {
  const _ProgressTransition(
    this.from,
    this.to,
    this.startedAt,
    this.durationMs,
  );
  final double from;
  final double to;
  final double startedAt;
  final int durationMs;
}

double _ease(double now, double start, int durationMs) {
  final t = durationMs <= 0
      ? 1.0
      : ((now - start) / durationMs).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _mix(double from, double to, double t) => from + (to - from) * t;
