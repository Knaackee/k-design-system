import 'dart:math' as math;
import 'dart:ui';

import 'orbit_models.dart';

class KOrbitPoint3 {
  const KOrbitPoint3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  KOrbitPoint3 operator +(KOrbitPoint3 other) =>
      KOrbitPoint3(x + other.x, y + other.y, z + other.z);
}

class KOrbitProjectedPoint {
  const KOrbitProjectedPoint(this.offset, this.depth);

  final Offset offset;
  final double depth;
}

class KOrbitProjectedNode {
  const KOrbitProjectedNode({
    required this.node,
    required this.world,
    required this.point,
  });

  final KOrbitNode node;
  final KOrbitPoint3 world;
  final KOrbitProjectedPoint point;
}

class KOrbitProjectedRing {
  const KOrbitProjectedRing({
    required this.parentId,
    required this.level,
    required this.anchor,
  });

  final String? parentId;
  final KOrbitLevel level;
  final KOrbitPoint3 anchor;
}

class KOrbitProjectedConnection {
  const KOrbitProjectedConnection({
    required this.connection,
    required this.start,
    required this.control,
    required this.end,
    required this.startDepth,
    required this.endDepth,
  });

  final KOrbitConnection connection;
  final Offset start;
  final Offset control;
  final Offset end;
  final double startDepth;
  final double endDepth;

  Offset pointAt(double t) {
    final u = 1 - t;
    return start * (u * u) + control * (2 * u * t) + end * (t * t);
  }

  double depthAt(double t) => startDepth + (endDepth - startDepth) * t;
}

class KOrbitSceneProjection {
  const KOrbitSceneProjection({
    required this.nodes,
    required this.rings,
    required this.connections,
    required this.scale,
    required this.extent,
    required this.maxLevelRadius,
    required this.center,
    required this.centerRadius,
  });

  final List<KOrbitProjectedNode> nodes;
  final List<KOrbitProjectedRing> rings;
  final List<KOrbitProjectedConnection> connections;
  final double scale;
  final double extent;
  final double maxLevelRadius;
  final Offset center;
  final double centerRadius;

  KOrbitProjectedNode? node(String id) {
    for (final item in nodes) {
      if (item.node.id == id) return item;
    }
    return null;
  }
}

Map<String, Rect> kOrbitLabelLayout({
  required KOrbitSceneProjection scene,
  required Size size,
  required double fontSize,
  required double labelHeight,
  required double labelOffset,
  required double nodeSize,
  String? selectedId,
}) {
  final sorted = [...scene.nodes]
    ..sort((a, b) {
      int priority(KOrbitProjectedNode item) {
        if (item.node.isCenter) return 0;
        if (item.node.id == selectedId) return 1;
        if (item.node.status == KOrbitStatus.question) return 2;
        if (item.node.status == KOrbitStatus.active) return 3;
        return 4;
      }

      final order = priority(a).compareTo(priority(b));
      return order != 0 ? order : a.node.id.compareTo(b.node.id);
    });
  final placed = <String, Rect>{};
  final accepted = <Rect>[];
  final sphere = Rect.fromCircle(
    center: scene.center,
    radius: scene.centerRadius,
  );
  final inset = nodeSize / 6;
  final bounds =
      Offset(inset, inset) &
      Size(
        math.max(0, size.width - inset * 2),
        math.max(0, size.height - inset * 2),
      );
  for (final item in sorted) {
    final width = math.min(
      132.0,
      math.max(fontSize * item.node.label.length * .6, fontSize * 2),
    );
    final height = labelHeight;
    if (item.node.isCenter) {
      final rect = Rect.fromLTWH(
        scene.center.dx - width / 2,
        scene.center.dy + scene.centerRadius + labelOffset / 3,
        width,
        height,
      );
      placed[item.node.id] = rect;
      accepted.add(rect);
      continue;
    }
    final point = item.point.offset;
    final candidates = [
      Rect.fromLTWH(
        point.dx + labelOffset,
        point.dy - height / 2,
        width,
        height,
      ),
      Rect.fromLTWH(
        point.dx - labelOffset - width,
        point.dy - height / 2,
        width,
        height,
      ),
      Rect.fromLTWH(
        point.dx - width / 2,
        point.dy + labelOffset,
        width,
        height,
      ),
      Rect.fromLTWH(
        point.dx - width / 2,
        point.dy - labelOffset - height,
        width,
        height,
      ),
    ];
    for (final candidate in candidates) {
      if (!bounds.contains(candidate.topLeft) ||
          !bounds.contains(candidate.bottomRight)) {
        continue;
      }
      if (accepted.any(candidate.overlaps) || candidate.overlaps(sphere)) {
        continue;
      }
      final hitsMarker = scene.nodes.any(
        (other) =>
            !other.node.isCenter &&
            other.node.id != item.node.id &&
            _rectHitsCircle(candidate, other.point.offset, nodeSize / 2),
      );
      if (hitsMarker) continue;
      placed[item.node.id] = candidate;
      accepted.add(candidate);
      break;
    }
  }
  return placed;
}

KOrbitNode? kOrbitHitTest({
  required KOrbitSceneProjection scene,
  required Map<String, Rect> labels,
  required Offset point,
  required double hitTargetSize,
  bool Function(KOrbitProjectedNode item)? eligible,
}) {
  final candidates = scene.nodes.where((item) {
    if (item.node.disabled || !(eligible?.call(item) ?? true)) return false;
    if (labels[item.node.id]?.contains(point) ?? false) return true;
    final radius = item.node.isCenter ? scene.centerRadius : hitTargetSize / 2;
    return (item.point.offset - point).distanceSquared <= math.pow(radius, 2);
  }).toList();
  if (candidates.isEmpty) return null;
  final labelHits = candidates
      .where((item) => labels[item.node.id]?.contains(point) ?? false)
      .toList();
  final pool = labelHits.isEmpty ? candidates : labelHits;
  pool.sort((a, b) {
    final distance = (a.point.offset - point).distanceSquared.compareTo(
      (b.point.offset - point).distanceSquared,
    );
    return distance != 0 ? distance : a.node.id.compareTo(b.node.id);
  });
  return pool.first.node;
}

bool _rectHitsCircle(Rect rect, Offset center, double radius) {
  final x = center.dx.clamp(rect.left, rect.right);
  final y = center.dy.clamp(rect.top, rect.bottom);
  return (Offset(x, y) - center).distanceSquared < radius * radius;
}

double kOrbitPeriodFor(KOrbitLevel level, double maxLevelRadius) =>
    level.periodSeconds ??
    (18 * math.pow(level.radius / math.max(1.0, maxLevelRadius), 1.5))
        .toDouble();

/// Returns an orbit-local point after inclination and azimuth, then camera
/// pitch and yaw. Scene projection adds parent anchors before camera rotation.
KOrbitPoint3 kOrbitPointFor({
  required KOrbitLevel level,
  required double angle,
  required KOrbitViewState view,
}) => _camera(_local(level, angle), view);

KOrbitPoint3 kOrbitRingPointFor({
  required KOrbitProjectedRing ring,
  required double angle,
  required KOrbitViewState view,
}) => _camera(ring.anchor + _local(ring.level, angle), view);

KOrbitProjectedPoint kOrbitProjectPoint({
  required KOrbitPoint3 point,
  required Offset center,
  required double scale,
  double depthScale = 1,
}) => KOrbitProjectedPoint(
  center + Offset(point.x * scale, -point.y * scale),
  point.z / math.max(1, depthScale),
);

KOrbitSceneProjection projectKOrbitScene({
  required Size size,
  required List<KOrbitLevel> levels,
  required List<KOrbitNode> nodes,
  required List<KOrbitConnection> connections,
  required KOrbitViewState view,
  required double timeSeconds,
  double radiusRatio = .296,
  double? extentOverride,
}) {
  final levelById = {for (final level in levels) level.id: level};
  final nodeById = {for (final node in nodes) node.id: node};
  final maxLevelRadius = levels.fold<double>(
    1,
    (value, level) => math.max(value, level.radius),
  );
  final naturalExtent = kOrbitExtentFor(levels: levels, nodes: nodes);
  final extent = extentOverride ?? naturalExtent;
  final center = size.center(Offset.zero) + view.offset;
  final scale =
      math.max(1.0, math.min(size.width, size.height) - 64) /
      (2 * extent) *
      view.zoom;
  final worldById = <String, KOrbitPoint3>{};
  KOrbitPoint3 worldFor(KOrbitNode node) => worldById.putIfAbsent(node.id, () {
    final parent = node.parentId == null ? null : nodeById[node.parentId];
    final anchor = parent == null
        ? const KOrbitPoint3(0, 0, 0)
        : worldFor(parent);
    if (node.levelId == null) return anchor;
    final level = levelById[node.levelId]!;
    final direction = level.clockwise ? 1.0 : -1.0;
    final angle =
        node.phase +
        direction *
            timeSeconds *
            math.pi *
            2 /
            kOrbitPeriodFor(level, maxLevelRadius);
    return anchor + _local(level, angle);
  });
  final projectedNodes = [
    for (final node in nodes)
      KOrbitProjectedNode(
        node: node,
        world: worldFor(node),
        point: kOrbitProjectPoint(
          point: _camera(worldFor(node), view),
          center: center,
          scale: scale,
          depthScale: extent,
        ),
      ),
  ]..sort((a, b) => a.point.depth.compareTo(b.point.depth));
  final ringKeys = <(String?, String)>{};
  final rings = <KOrbitProjectedRing>[];
  for (final node in nodes) {
    if (node.levelId == null) continue;
    final key = (node.parentId, node.levelId!);
    if (!ringKeys.add(key)) continue;
    rings.add(
      KOrbitProjectedRing(
        parentId: node.parentId,
        level: levelById[node.levelId]!,
        anchor: node.parentId == null
            ? const KOrbitPoint3(0, 0, 0)
            : worldFor(nodeById[node.parentId]!),
      ),
    );
  }
  final projectedById = {for (final item in projectedNodes) item.node.id: item};
  final projectedConnections = <KOrbitProjectedConnection>[];
  for (final connection in connections) {
    final source = projectedById[connection.sourceId]!;
    final target = projectedById[connection.targetId]!;
    final start = source.point.offset;
    final end = target.point.offset;
    final delta = end - start;
    final length = math.max(1.0, delta.distance);
    final bend = math.min(48.0, length * .18);
    projectedConnections.add(
      KOrbitProjectedConnection(
        connection: connection,
        start: start,
        control:
            (start + end) / 2 + Offset(-delta.dy, delta.dx) / length * bend,
        end: end,
        startDepth: source.point.depth,
        endDepth: target.point.depth,
      ),
    );
  }
  return KOrbitSceneProjection(
    nodes: projectedNodes,
    rings: rings,
    connections: projectedConnections,
    scale: scale,
    extent: extent,
    maxLevelRadius: maxLevelRadius,
    center: center,
    centerRadius: extent * scale * radiusRatio,
  );
}

double kOrbitExtentFor({
  required List<KOrbitLevel> levels,
  required List<KOrbitNode> nodes,
}) {
  final levelById = {for (final level in levels) level.id: level};
  final nodeById = {for (final node in nodes) node.id: node};
  final cache = <String, double>{};
  double nodeExtent(KOrbitNode node) => cache.putIfAbsent(node.id, () {
    final own = node.levelId == null ? 0.0 : levelById[node.levelId]!.radius;
    final parent = node.parentId == null ? null : nodeById[node.parentId];
    return own + (parent == null ? 0 : nodeExtent(parent));
  });
  return math.max(
    1.0,
    nodes.fold<double>(0, (value, node) => math.max(value, nodeExtent(node))),
  );
}

KOrbitViewState kOrbitZoomAt({
  required KOrbitViewState view,
  required double zoom,
  required Offset focalPoint,
  required Offset viewportCenter,
  required double minZoom,
  required double maxZoom,
}) {
  final nextZoom = zoom.clamp(minZoom, maxZoom).toDouble();
  if (nextZoom == view.zoom) return view;
  final ratio = nextZoom / view.zoom;
  final offset =
      focalPoint -
      viewportCenter -
      (focalPoint - viewportCenter - view.offset) * ratio;
  return view.copyWith(zoom: nextZoom, offset: offset);
}

KOrbitPoint3 _local(KOrbitLevel level, double angle) {
  final sine = math.sin(angle);
  final point = KOrbitPoint3(
    level.radius * math.cos(angle),
    level.radius * sine * math.cos(level.inclination),
    level.radius * sine * math.sin(level.inclination),
  );
  return _rotateZ(point, level.azimuth);
}

KOrbitPoint3 _camera(KOrbitPoint3 point, KOrbitViewState view) =>
    _rotateY(_rotateX(point, view.pitch), view.yaw);

KOrbitPoint3 _rotateX(KOrbitPoint3 p, double angle) {
  final c = math.cos(angle);
  final s = math.sin(angle);
  return KOrbitPoint3(p.x, p.y * c - p.z * s, p.y * s + p.z * c);
}

KOrbitPoint3 _rotateY(KOrbitPoint3 p, double angle) {
  final c = math.cos(angle);
  final s = math.sin(angle);
  return KOrbitPoint3(p.x * c + p.z * s, p.y, -p.x * s + p.z * c);
}

KOrbitPoint3 _rotateZ(KOrbitPoint3 p, double angle) {
  final c = math.cos(angle);
  final s = math.sin(angle);
  return KOrbitPoint3(p.x * c - p.y * s, p.x * s + p.y * c, p.z);
}
