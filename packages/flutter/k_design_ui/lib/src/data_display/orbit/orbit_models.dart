import 'package:flutter/widgets.dart';

const _unset = Object();

enum KOrbitDirection { forward, reverse, bidirectional }

enum KOrbitLineStyle { solid, dashed, dotted }

enum KOrbitSignalStyle { point, trail, endpointPingsOnly }

enum KOrbitTone { neutral, brand, info, success, warning, error }

enum KOrbitStatus { idle, active, question, error, completed }

enum KOrbitNodeAppearance { sphere, icon, avatar }

enum KOrbitLabelVisibility { interaction, always, hidden }

enum KOrbitSignalTriggerResult { accepted, capacity, invalid, inactive }

enum KOrbitSignalEndReason { completed, cancelled }

enum KOrbitInteractionMode { dedicated, embedded }

@immutable
class KOrbitLevel {
  const KOrbitLevel({
    required this.id,
    required this.radius,
    this.color,
    this.inclination = 0,
    this.azimuth = 0,
    this.periodSeconds,
    int? direction,
    bool clockwise = true,
    this.label,
  }) : direction = direction ?? (clockwise ? 1 : -1);

  final String id;
  final double radius;
  final Color? color;
  final double inclination;
  final double azimuth;
  final double? periodSeconds;
  final int direction;
  final String? label;

  bool get clockwise => direction == 1;
}

@immutable
class KOrbitBadge {
  const KOrbitBadge({
    required this.content,
    this.label,
    this.tone = KOrbitTone.neutral,
  });

  final Widget content;
  final String? label;
  final KOrbitTone tone;
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
    this.periodSeconds,
    this.direction,
    this.backgroundColor,
    this.borderColor,
    this.badge,
    this.showBadge = true,
    this.pulseIntensity,
    this.radius,
    this.disabled = false,
    this.tone = KOrbitTone.neutral,
    this.status = KOrbitStatus.idle,
    this.statusLabel,
    this.pulse,
    this.pulsePeriod,
    this.progress,
    this.appearance = KOrbitNodeAppearance.icon,
    this.content,
  });

  final String id;
  final String? levelId;
  final String? parentId;
  final String label;
  final String? description;
  final double phase;
  final double? periodSeconds;
  final int? direction;
  final Color? backgroundColor;
  final Color? borderColor;
  final KOrbitBadge? badge;
  final bool showBadge;
  final double? pulseIntensity;
  final double? radius;
  final bool disabled;
  final KOrbitTone tone;
  final KOrbitStatus status;
  final String? statusLabel;
  final bool? pulse;
  final Duration? pulsePeriod;
  final double? progress;
  final KOrbitNodeAppearance appearance;
  final Widget? content;

  bool get isCenter => levelId == null;
  bool get shouldPulse =>
      pulse ?? status == KOrbitStatus.active || status == KOrbitStatus.question;

  KOrbitNode copyWith({
    String? id,
    String? label,
    Object? levelId = _unset,
    Object? parentId = _unset,
    Object? description = _unset,
    double? phase,
    Object? periodSeconds = _unset,
    Object? direction = _unset,
    Object? backgroundColor = _unset,
    Object? borderColor = _unset,
    Object? badge = _unset,
    bool? showBadge,
    Object? pulseIntensity = _unset,
    Object? radius = _unset,
    bool? disabled,
    KOrbitTone? tone,
    KOrbitStatus? status,
    Object? statusLabel = _unset,
    Object? pulse = _unset,
    Object? pulsePeriod = _unset,
    Object? progress = _unset,
    KOrbitNodeAppearance? appearance,
    Object? content = _unset,
  }) => KOrbitNode(
    id: id ?? this.id,
    label: label ?? this.label,
    levelId: identical(levelId, _unset) ? this.levelId : levelId as String?,
    parentId: identical(parentId, _unset) ? this.parentId : parentId as String?,
    description: identical(description, _unset)
        ? this.description
        : description as String?,
    phase: phase ?? this.phase,
    periodSeconds: identical(periodSeconds, _unset)
        ? this.periodSeconds
        : (periodSeconds as num?)?.toDouble(),
    direction: identical(direction, _unset)
        ? this.direction
        : direction as int?,
    backgroundColor: identical(backgroundColor, _unset)
        ? this.backgroundColor
        : backgroundColor as Color?,
    borderColor: identical(borderColor, _unset)
        ? this.borderColor
        : borderColor as Color?,
    badge: identical(badge, _unset) ? this.badge : badge as KOrbitBadge?,
    showBadge: showBadge ?? this.showBadge,
    pulseIntensity: identical(pulseIntensity, _unset)
        ? this.pulseIntensity
        : (pulseIntensity as num?)?.toDouble(),
    radius: identical(radius, _unset)
        ? this.radius
        : (radius as num?)?.toDouble(),
    disabled: disabled ?? this.disabled,
    tone: tone ?? this.tone,
    status: status ?? this.status,
    statusLabel: identical(statusLabel, _unset)
        ? this.statusLabel
        : statusLabel as String?,
    pulse: identical(pulse, _unset) ? this.pulse : pulse as bool?,
    pulsePeriod: identical(pulsePeriod, _unset)
        ? this.pulsePeriod
        : pulsePeriod as Duration?,
    progress: identical(progress, _unset)
        ? this.progress
        : (progress as num?)?.toDouble(),
    appearance: appearance ?? this.appearance,
    content: identical(content, _unset) ? this.content : content as Widget?,
  );
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
    this.sourcePing,
    this.arrivalPing,
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
  final bool? sourcePing;
  final bool? arrivalPing;
  final bool visible;
}

@immutable
class KOrbitSignal {
  const KOrbitSignal({
    required this.id,
    this.connectionId,
    this.nodeId,
    this.duration,
    this.style,
    this.sourcePing,
    this.destinationPing,
  });

  final String id;
  final String? connectionId;
  final String? nodeId;
  final Duration? duration;
  final KOrbitSignalStyle? style;
  final bool? sourcePing;
  final bool? destinationPing;
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
    this.instructions =
        'Drag with one finger to pan; pinch with two fingers to zoom. Long press a node for actions.',
    this.reset = 'Reset view',
    this.pause = 'Pause motion',
    this.resume = 'Resume motion',
    this.speed = 'Motion speed',
  });

  final String stage;
  final String instructions;
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
    this.progressLineWidth,
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
  final double? progressLineWidth;
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
    if (!level.radius.isFinite ||
        level.radius <= 0 ||
        !level.inclination.isFinite ||
        !level.azimuth.isFinite ||
        (level.periodSeconds != null &&
            (!level.periodSeconds!.isFinite || level.periodSeconds! <= 0)) ||
        (level.direction != 1 && level.direction != -1)) {
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
    if (!node.phase.isFinite ||
        (node.periodSeconds != null &&
            (!node.periodSeconds!.isFinite || node.periodSeconds! <= 0)) ||
        (node.direction != null &&
            node.direction != 1 &&
            node.direction != -1) ||
        (node.radius != null &&
            (!node.radius!.isFinite || node.radius! <= 0))) {
      throw ArgumentError('Orbit node ${node.id} has invalid numeric values');
    }
    if (node.pulseIntensity != null &&
        (!node.pulseIntensity!.isFinite ||
            node.pulseIntensity! < 0 ||
            node.pulseIntensity! > 1)) {
      throw ArgumentError('Orbit node ${node.id} has invalid pulse intensity');
    }
    if (node.progress != null &&
        (!node.progress!.isFinite ||
            node.progress! < 0 ||
            node.progress! > 100)) {
      throw ArgumentError('Orbit node ${node.id} has invalid progress');
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
