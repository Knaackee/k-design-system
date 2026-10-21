import 'dart:math' as math;
import '../maps/k_map_controller.dart';
import '../maps/k_map_polygon.dart';

double _cross((double, double) a, (double, double) b) =>
    a.$1 * b.$2 - a.$2 * b.$1;
(double, double) _sub(KMapCenter a, KMapCenter b) =>
    (a.longitude - b.longitude, a.latitude - b.latitude);
KMapCenter _at(KMapCenter a, KMapCenter b, double t) => KMapCenter(
  longitude: a.longitude + (b.longitude - a.longitude) * t,
  latitude: a.latitude + (b.latitude - a.latitude) * t,
);
double _area(List<KMapCenter> ring) {
  if (ring.isEmpty) return 0;
  final origin = ring.first;
  var sum = 0.0;
  for (var i = 0; i < ring.length; i++) {
    sum += _cross(
      _sub(ring[i], origin),
      _sub(ring[(i + 1) % ring.length], origin),
    );
  }
  return sum / 2;
}

bool _insideRing(List<KMapCenter> ring, KMapCenter p) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i], b = ring[j];
    if ((a.latitude > p.latitude) != (b.latitude > p.latitude) &&
        p.longitude <
            (b.longitude - a.longitude) *
                    (p.latitude - a.latitude) /
                    (b.latitude - a.latitude) +
                a.longitude) {
      inside = !inside;
    }
  }
  return inside;
}

bool _inside(List<KMapPolygon> polygons, KMapCenter p) => polygons.any(
  (polygon) =>
      _insideRing(polygon.outer, p) &&
      !polygon.holes.any((hole) => _insideRing(hole, p)),
);

List<List<KMapCenter>> _rings(List<KMapPolygon> polygons) => [
  for (final polygon in polygons) ...[
    _area(polygon.outer) >= 0 ? polygon.outer : polygon.outer.reversed.toList(),
    for (final hole in polygon.holes)
      _area(hole) <= 0 ? hole : hole.reversed.toList(),
  ],
];

/// Polygon difference by planar boundary arrangement. Splits at every crossing,
/// keeps directed edges separating the result's inside/outside, then assembles
/// outer rings and holes. Coordinates stay in longitude/latitude without raster
/// approximation; both disconnected remnants and enclosed holes are retained.
List<KMapPolygon> subtractKMapZoneGeometry(
  List<KMapPolygon> subject,
  List<KMapPolygon> clip,
) {
  final rings = [..._rings(subject), ..._rings(clip)];
  final segments = <(KMapCenter, KMapCenter)>[];
  for (final ring in rings) {
    for (var i = 0; i < ring.length; i++) {
      segments.add((ring[i], ring[(i + 1) % ring.length]));
    }
  }
  final result = <(KMapCenter, KMapCenter)>[];
  for (final (a, b) in segments) {
    final vector = _sub(b, a);
    final length = math.sqrt(vector.$1 * vector.$1 + vector.$2 * vector.$2);
    if (length < 1e-12) continue;
    final cuts = <double>[0, 1];
    for (final (c, d) in segments) {
      final other = _sub(d, c), offset = _sub(c, a);
      final denominator = _cross(vector, other);
      if (denominator.abs() > 1e-15) {
        final t = _cross(offset, other) / denominator;
        final u = _cross(offset, vector) / denominator;
        if (t > 1e-10 && t < 1 - 1e-10 && u >= -1e-10 && u <= 1 + 1e-10) {
          cuts.add(t);
        }
      } else if (_cross(offset, vector).abs() < 1e-13) {
        for (final p in [c, d]) {
          final t = vector.$1.abs() > vector.$2.abs()
              ? (p.longitude - a.longitude) / vector.$1
              : (p.latitude - a.latitude) / vector.$2;
          if (t > 1e-10 && t < 1 - 1e-10) cuts.add(t);
        }
      }
    }
    cuts.sort();
    for (var i = 0; i < cuts.length - 1; i++) {
      if (cuts[i + 1] - cuts[i] < 1e-10) continue;
      final start = _at(a, b, cuts[i]), end = _at(a, b, cuts[i + 1]);
      final middle = _at(start, end, .5);
      final epsilon = math.min(1e-8, length * (cuts[i + 1] - cuts[i]) * 1e-5);
      final left = KMapCenter(
        longitude: middle.longitude - vector.$2 / length * epsilon,
        latitude: middle.latitude + vector.$1 / length * epsilon,
      );
      final right = KMapCenter(
        longitude: middle.longitude + vector.$2 / length * epsilon,
        latitude: middle.latitude - vector.$1 / length * epsilon,
      );
      final inLeft = _inside(subject, left) && !_inside(clip, left);
      final inRight = _inside(subject, right) && !_inside(clip, right);
      if (inLeft == inRight) continue;
      final edge = inLeft ? (start, end) : (end, start);
      if (!result.any(
        (current) => _near(current.$1, edge.$1) && _near(current.$2, edge.$2),
      )) {
        result.add(edge);
      }
    }
  }
  final contours = <List<KMapCenter>>[];
  while (result.isNotEmpty) {
    final first = result.removeLast();
    final ring = <KMapCenter>[first.$1];
    var end = first.$2;
    while (!_near(end, ring.first)) {
      ring.add(end);
      final index = result.indexWhere((edge) => _near(edge.$1, end));
      if (index < 0) throw StateError('Polygon boundary did not close');
      end = result.removeAt(index).$2;
    }
    if (ring.length >= 3 && _area(ring).abs() > 1e-14) contours.add(ring);
  }
  return [
    for (final outer in contours.where((ring) => _area(ring) > 0))
      KMapPolygon(
        outer: List.unmodifiable(outer),
        holes: [
          for (final hole in contours.where((ring) => _area(ring) < 0))
            if (_insideRing(outer, hole.first)) List.unmodifiable(hole),
        ],
      ),
  ];
}

bool _near(KMapCenter a, KMapCenter b) =>
    (a.longitude - b.longitude).abs() < 1e-9 &&
    (a.latitude - b.latitude).abs() < 1e-9;

double kMapZoneGeometryArea(List<KMapPolygon> polygons) => polygons.fold(
  0.0,
  (sum, polygon) =>
      sum +
      _area(polygon.outer).abs() -
      polygon.holes.fold(0.0, (value, hole) => value + _area(hole).abs()),
);

List<KMapCenter> createKMapCircleCoordinates(
  KMapCenter center,
  double radiusKm,
) => [
  for (var i = 0; i < 64; i++)
    _destination(center, radiusKm, i * 2 * math.pi / 64),
];

KMapCenter _destination(KMapCenter center, double radiusKm, double bearing) {
  final latitude = center.latitude * math.pi / 180,
      longitude = center.longitude * math.pi / 180;
  final distance = radiusKm / 6371.0088;
  final lat = math.asin(
    math.sin(latitude) * math.cos(distance) +
        math.cos(latitude) * math.sin(distance) * math.cos(bearing),
  );
  final lon =
      longitude +
      math.atan2(
        math.sin(bearing) * math.sin(distance) * math.cos(latitude),
        math.cos(distance) - math.sin(latitude) * math.sin(lat),
      );
  return KMapCenter(
    longitude: lon * 180 / math.pi,
    latitude: lat * 180 / math.pi,
  );
}
