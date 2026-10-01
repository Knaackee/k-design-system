import 'dart:convert';
import 'dart:math' as math;
import 'orbit_models.dart';

class KOrbitLayout {
  const KOrbitLayout({required this.levels, required this.nodes});
  final List<KOrbitLevel> levels;
  final List<KOrbitNode> nodes;
}

/// Reserves each complete moving subtree; explicit geometry is unchanged.
KOrbitLayout layoutKOrbit(
  List<KOrbitLevel> levels,
  List<KOrbitNode> nodes, {
  double gap = 12,
}) {
  validateKOrbit(levels: levels, nodes: nodes, connections: const []);
  if (!gap.isFinite || gap < 0) throw ArgumentError.value(gap, 'layoutGap');
  final byLevel = {for (final level in levels) level.id: level};
  final children = <String, List<KOrbitNode>>{};
  for (final node in nodes) {
    if (node.parentId != null) (children[node.parentId!] ??= []).add(node);
  }
  final result = <String, KOrbitNode>{};
  final resolvedLevels = <String, KOrbitLevel>{};
  final reserved = <String, double>{};
  double visit(KOrbitNode node) {
    if (reserved.containsKey(node.id)) return reserved[node.id]!;
    result[node.id] = node;
    var outer = node.radius ?? 12.0;
    final groups = <String, List<KOrbitNode>>{};
    for (final child in children[node.id] ?? <KOrbitNode>[]) {
      visit(child);
      final level = byLevel[child.levelId]!;
      final key = jsonEncode([
        level.id,
        child.periodSeconds ?? level.periodSeconds ?? 60,
        child.direction ?? level.direction,
      ]);
      (groups[key] ??= []).add(child);
    }
    final keys = groups.keys.toList()..sort();
    for (final key in keys) {
      final siblings = groups[key]!;
      final level = byLevel[siblings.first.levelId]!;
      final footprint = siblings
          .map((child) => reserved[child.id]!)
          .reduce(math.max);
      final spacing = siblings.length > 1
          ? (2 * footprint + gap) / (2 * math.sin(math.pi / siblings.length))
          : 0.0;
      final radius = math.max(
        level.radius,
        math.max(outer + footprint + gap, spacing),
      );
      final id = jsonEncode(['k-orbit-layout', node.id, key]);
      resolvedLevels[id] = KOrbitLevel(
        id: id,
        label: level.label,
        radius: radius,
        color: level.color,
        periodSeconds:
            siblings.first.periodSeconds ?? level.periodSeconds ?? 60,
        direction: siblings.first.direction ?? level.direction,
      );
      for (var index = 0; index < siblings.length; index++) {
        final child = siblings[index];
        result[child.id] = result[child.id]!.copyWith(
          levelId: id,
          phase: index * math.pi * 2 / siblings.length,
        );
      }
      outer = radius + footprint;
    }
    reserved[node.id] = outer;
    return outer;
  }

  for (final node in nodes) {
    if (node.parentId == null) {
      visit(node);
      if (node.levelId != null) {
        resolvedLevels[node.levelId!] = byLevel[node.levelId]!;
      }
    }
  }
  return KOrbitLayout(
    levels: resolvedLevels.values.toList(),
    nodes: [for (final node in nodes) result[node.id]!],
  );
}
