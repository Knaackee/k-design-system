import 'dart:math' as math;

import 'orbit_models.dart';

/// Integrates node-local angles so live speed and period changes do not rewind.
Map<String, double> advanceKOrbitAngles({
  required Map<String, double> angles,
  required List<KOrbitLevel> levels,
  required List<KOrbitNode> nodes,
  required double delta,
  double speed = 1,
  double maxAngularSpeed = 12,
  bool synchronizeLevels = false,
}) {
  final levelsById = {for (final level in levels) level.id: level};
  final ids = nodes.map((node) => node.id).toSet();
  final groupAngles = <String, double>{};
  angles.removeWhere((id, _) => !ids.contains(id));
  for (final node in nodes) {
    final level = node.levelId == null ? null : levelsById[node.levelId];
    if (level == null) continue;
    if (synchronizeLevels && groupAngles.containsKey(level.id)) {
      angles[node.id] = groupAngles[level.id]!;
      continue;
    }
    final degrees = math.min(
      maxAngularSpeed,
      360 * speed / (node.periodSeconds ?? level.periodSeconds ?? 60),
    );
    angles[node.id] =
        ((angles[node.id] ?? 0) +
                delta *
                    degrees *
                    math.pi /
                    180 *
                    (node.direction ?? level.direction))
            .remainder(math.pi * 2);
    if (synchronizeLevels) groupAngles[level.id] = angles[node.id]!;
  }
  return angles;
}
