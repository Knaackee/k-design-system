import 'orbit_models.dart';
import 'orbit_painter.dart';

/// Transient effects use wall time, independent of the orbital speed control.
class KOrbitSignals {
  KOrbitSignals(this.onEnd);
  final void Function(String, KOrbitSignalEndReason) onEnd;
  final List<KOrbitActiveSignal> active = [];
  double time = 0;

  KOrbitSignalTriggerResult trigger(
    KOrbitSignal signal, {
    required List<KOrbitNode> nodes,
    required List<KOrbitConnection> connections,
    required int capacity,
    required Duration defaultDuration,
    required bool visible,
  }) {
    if (!visible) return KOrbitSignalTriggerResult.inactive;
    final duration = signal.duration ?? defaultDuration;
    final validTarget = signal.nodeId != null
        ? nodes.any((node) => node.id == signal.nodeId)
        : connections.any((connection) => connection.id == signal.connectionId);
    if (signal.id.isEmpty ||
        (signal.nodeId == null) == (signal.connectionId == null) ||
        !validTarget ||
        duration <= Duration.zero ||
        active.any((item) => item.signal.id == signal.id)) {
      return KOrbitSignalTriggerResult.invalid;
    }
    if (active.length >= capacity) return KOrbitSignalTriggerResult.capacity;
    active.add(
      KOrbitActiveSignal(signal: signal, startedAt: time, duration: duration),
    );
    return KOrbitSignalTriggerResult.accepted;
  }

  void advance(double delta) {
    time += delta;
    final completed = active
        .where(
          (item) =>
              time - item.startedAt >=
              item.duration.inMicroseconds / Duration.microsecondsPerSecond,
        )
        .toList();
    active.removeWhere(completed.contains);
    for (final item in completed) {
      onEnd(item.signal.id, KOrbitSignalEndReason.completed);
    }
  }

  bool cancel(String id) {
    final count = active.length;
    active.removeWhere((item) => item.signal.id == id);
    if (count == active.length) return false;
    onEnd(id, KOrbitSignalEndReason.cancelled);
    return true;
  }

  void reconcile(List<KOrbitNode> nodes, List<KOrbitConnection> connections) {
    final ids = nodes.map((node) => node.id).toSet();
    final links = connections.map((connection) => connection.id).toSet();
    for (final item in List<KOrbitActiveSignal>.of(active)) {
      if (item.signal.nodeId != null
          ? !ids.contains(item.signal.nodeId)
          : !links.contains(item.signal.connectionId)) {
        cancel(item.signal.id);
      }
    }
  }

  void cancelAll() {
    final removed = List<KOrbitActiveSignal>.of(active);
    active.clear();
    for (final item in removed) {
      onEnd(item.signal.id, KOrbitSignalEndReason.cancelled);
    }
  }
}
