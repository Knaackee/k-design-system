import 'package:flutter/widgets.dart';

enum KOrbitDirection { forward, reverse, bidirectional }

enum KOrbitLineStyle { solid, dashed, dotted }

enum KOrbitSignalStyle { point, trail, endpointPingsOnly }

enum KOrbitTone { neutral, brand, info, success, warning, error }

enum KOrbitStatus { idle, active, question, error }

enum KOrbitSignalTriggerResult { accepted, capacity, invalid, inactive }

enum KOrbitSignalEndReason { completed, cancelled }

enum KOrbitInteractionMode { dedicated, embedded }

@immutable
class KOrbitLevel {
  const KOrbitLevel({
    required this.id,
    required this.radius,
    this.inclination = 0,
    this.azimuth = 0,
    this.periodSeconds,
    this.clockwise = true,
    this.label,
  });

  final String id;
  final double radius;
  final double inclination;
  final double azimuth;
  final double? periodSeconds;
  final bool clockwise;
  final String? label;
}

@immutable
class KOrbitNode {
  const KOrbitNode({
    required this.id,
    required this.label,
    this.levelId,
    this.parentId,
    this.description,
    this.phase = 0,
    this.disabled = false,
    this.tone = KOrbitTone.neutral,
    this.status = KOrbitStatus.idle,
    this.statusLabel,
    this.pulse,
    this.pulsePeriod,
    this.content,
  });

  final String id;
  final String? levelId;
  final String? parentId;
  final String label;
  final String? description;
  final double phase;
  final bool disabled;
  final KOrbitTone tone;
  final KOrbitStatus status;
  final String? statusLabel;
  final bool? pulse;
  final Duration? pulsePeriod;
  final Widget? content;

  bool get isCenter => levelId == null;
  bool get shouldPulse =>
      pulse ?? status == KOrbitStatus.active || status == KOrbitStatus.question;
}

@immutable
class KOrbitConnection {
  const KOrbitConnection({
    required this.id,
    required this.sourceId,
    required this.targetId,
    this.direction = KOrbitDirection.forward,
    this.label,
    this.tone = KOrbitTone.neutral,
    this.lineStyle = KOrbitLineStyle.dashed,
    this.signalStyle = KOrbitSignalStyle.point,
    this.visible = false,
  });

  final String id;
  final String sourceId;
  final String targetId;
  final KOrbitDirection direction;
  final String? label;
  final KOrbitTone tone;
  final KOrbitLineStyle lineStyle;
  final KOrbitSignalStyle signalStyle;
  final bool visible;
}

@immutable
class KOrbitSignal {
  const KOrbitSignal({
    required this.id,
    required this.connectionId,
    this.duration,
    this.style,
    this.sourcePing = true,
    this.destinationPing = true,
  });

  final String id;
  final String connectionId;
  final Duration? duration;
  final KOrbitSignalStyle? style;
  final bool sourcePing;
  final bool destinationPing;
}

@immutable
class KOrbitViewState {
  const KOrbitViewState({
    this.yaw = 0,
    this.pitch = 0,
    this.zoom = 1,
    this.offset = Offset.zero,
  });

  final double yaw;
  final double pitch;
  final double zoom;
  final Offset offset;

  KOrbitViewState copyWith({
    double? yaw,
    double? pitch,
    double? zoom,
    Offset? offset,
  }) => KOrbitViewState(
    yaw: yaw ?? this.yaw,
    pitch: pitch ?? this.pitch,
    zoom: zoom ?? this.zoom,
    offset: offset ?? this.offset,
  );

  @override
  bool operator ==(Object other) =>
      other is KOrbitViewState &&
      other.yaw == yaw &&
      other.pitch == pitch &&
      other.zoom == zoom &&
      other.offset == offset;

  @override
  int get hashCode => Object.hash(yaw, pitch, zoom, offset);
}

@immutable
class KOrbitLabels {
  const KOrbitLabels({
    this.stage = 'Interactive orbit visualization',
    this.reset = 'Reset view',
    this.pause = 'Pause motion',
    this.resume = 'Resume motion',
    this.speed = 'Motion speed',
  });

  final String stage;
  final String reset;
  final String pause;
  final String resume;
  final String speed;
}

@immutable
class KOrbitVisualStyle {
  const KOrbitVisualStyle({
    this.trackColor,
    this.centerInnerColor,
    this.centerOuterColor,
    this.lineWidth,
    this.dashLength,
    this.gapLength,
    this.signalSize,
    this.trailLength,
    this.pingRadius,
  });

  final Color? trackColor;
  final Color? centerInnerColor;
  final Color? centerOuterColor;
  final double? lineWidth;
  final double? dashLength;
  final double? gapLength;
  final double? signalSize;
  final double? trailLength;
  final double? pingRadius;
}

void validateKOrbit({
  required List<KOrbitLevel> levels,
  required List<KOrbitNode> nodes,
  required List<KOrbitConnection> connections,
}) {
  final levelIds = <String>{};
  for (final level in levels) {
    if (level.id.isEmpty || !levelIds.add(level.id)) {
      throw ArgumentError(
        'Orbit level IDs must be non-empty and unique: ${level.id}',
      );
    }
    if (!level.radius.isFinite || level.radius <= 0) {
      throw ArgumentError('Orbit level ${level.id} has an invalid radius');
    }
    if (!level.inclination.isFinite ||
        !level.azimuth.isFinite ||
        (level.periodSeconds != null &&
            (!level.periodSeconds!.isFinite || level.periodSeconds! <= 0))) {
      throw ArgumentError('Orbit level ${level.id} has invalid numeric values');
    }
  }

  final nodeIds = <String>{};
  final parents = <String, String>{};
  for (final node in nodes) {
    if (node.id.isEmpty || !nodeIds.add(node.id)) {
      throw ArgumentError(
        'Orbit node IDs must be non-empty and unique: ${node.id}',
      );
    }
    if (!node.phase.isFinite) {
      throw ArgumentError('Orbit node ${node.id} has an invalid phase');
    }
    if (node.parentId != null && node.levelId == null) {
      throw ArgumentError('Orbit node ${node.id} has a parent but no level');
    }
    if (node.pulsePeriod != null && node.pulsePeriod! <= Duration.zero) {
      throw ArgumentError('Orbit node ${node.id} has an invalid pulse period');
    }
    if (node.levelId != null && !levelIds.contains(node.levelId)) {
      throw ArgumentError(
        'Orbit node ${node.id} references missing level ${node.levelId}',
      );
    }
    if (node.parentId != null) parents[node.id] = node.parentId!;
  }
  for (final entry in parents.entries) {
    if (!nodeIds.contains(entry.value)) {
      throw ArgumentError(
        'Orbit node ${entry.key} references missing parent ${entry.value}',
      );
    }
    final visited = <String>{entry.key};
    String? current = entry.value;
    while (current != null) {
      if (!visited.add(current)) {
        throw ArgumentError(
          'Orbit node parent chain contains a cycle at $current',
        );
      }
      current = parents[current];
    }
  }

  final connectionIds = <String>{};
  for (final connection in connections) {
    if (connection.id.isEmpty || !connectionIds.add(connection.id)) {
      throw ArgumentError(
        'Orbit connection IDs must be non-empty and unique: ${connection.id}',
      );
    }
    if (!nodeIds.contains(connection.sourceId) ||
        !nodeIds.contains(connection.targetId)) {
      throw ArgumentError(
        'Orbit connection ${connection.id} references a missing endpoint',
      );
    }
  }
}
