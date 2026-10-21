import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../maps/k_map_controller.dart';
import '../maps/k_map_polygon.dart';
import 'k_map_zone_boolean.dart';

enum KMapZoneValidationCode {
  invalidCoordinate('invalid-coordinate'),
  minimumVertices('minimum-vertices'),
  selfIntersection('self-intersection'),
  zoneOverlap('zone-overlap'),
  externalChange('external-change');

  const KMapZoneValidationCode(this.value);
  final String value;
}

@immutable
class KMapZoneValidationError {
  const KMapZoneValidationError({
    required this.code,
    required this.message,
    this.zoneId,
    this.conflictingZoneId,
  });

  final KMapZoneValidationCode code;
  final String? zoneId;
  final String? conflictingZoneId;
  final String message;
}

typedef KMapZonesChanged = void Function(List<KMapZone> zones);
typedef KMapZoneSelected = void Function(String? id);
typedef KMapZoneValidationErrorCallback =
    void Function(KMapZoneValidationError error);

KMapZoneValidationError? validateKMapZones(List<KMapZone> zones) {
  final ids = <String>{};
  for (final zone in zones) {
    if (zone.id.trim().isEmpty ||
        !ids.add(zone.id) ||
        zone.name.trim().isEmpty) {
      return KMapZoneValidationError(
        code: KMapZoneValidationCode.invalidCoordinate,
        zoneId: zone.id,
        message:
            'Gebiets-IDs müssen eindeutig und Namen dürfen nicht leer sein.',
      );
    }
    if (zone.geometry.isEmpty) {
      return _geometryFailure(zone, KMapZoneValidationCode.minimumVertices);
    }
    for (final polygon in zone.geometry) {
      for (final ring in [polygon.outer, ...polygon.holes]) {
        if (ring.any((point) => !_validCoordinate(point)) ||
            _crossesAntimeridian(ring)) {
          return _geometryFailure(
            zone,
            KMapZoneValidationCode.invalidCoordinate,
          );
        }
        if (ring.length < 3) {
          return _geometryFailure(zone, KMapZoneValidationCode.minimumVertices);
        }
        if (_hasDegenerateGeometry(ring) || _selfIntersects(ring)) {
          return _geometryFailure(
            zone,
            KMapZoneValidationCode.selfIntersection,
          );
        }
      }
      for (var i = 0; i < polygon.holes.length; i++) {
        final hole = polygon.holes[i];
        if (hole.any(
              (point) =>
                  !_strictlyInside(polygon.outer, point) &&
                  !_onBoundary(polygon.outer, point),
            ) ||
            _invalidHoleBoundaryContact(polygon.outer, hole)) {
          return _geometryFailure(
            zone,
            KMapZoneValidationCode.selfIntersection,
          );
        }
        for (var j = i + 1; j < polygon.holes.length; j++) {
          if (_overlaps(hole, polygon.holes[j])) {
            return _geometryFailure(
              zone,
              KMapZoneValidationCode.selfIntersection,
            );
          }
        }
      }
    }
    for (var i = 0; i < zone.geometry.length; i++) {
      for (var j = i + 1; j < zone.geometry.length; j++) {
        if (_geometryOverlaps([zone.geometry[i]], [zone.geometry[j]])) {
          return _geometryFailure(
            zone,
            KMapZoneValidationCode.selfIntersection,
          );
        }
      }
    }
  }

  for (var i = 0; i < zones.length; i++) {
    for (var j = i + 1; j < zones.length; j++) {
      if (_geometryOverlaps(zones[i].geometry, zones[j].geometry)) {
        return KMapZoneValidationError(
          code: KMapZoneValidationCode.zoneOverlap,
          zoneId: zones[i].id,
          conflictingZoneId: zones[j].id,
          message: 'Gebiete dürfen sich nicht überlappen.',
        );
      }
    }
  }
  return null;
}

KMapZoneValidationError _geometryFailure(
  KMapZone zone,
  KMapZoneValidationCode code,
) => KMapZoneValidationError(
  code: code,
  zoneId: zone.id,
  message: switch (code) {
    KMapZoneValidationCode.minimumVertices =>
      'Ein Gebiet benötigt mindestens drei Eckpunkte.',
    KMapZoneValidationCode.selfIntersection =>
      'Die Gebietsgrenze darf sich nicht selbst schneiden und braucht eine Fläche.',
    _ => 'Die Koordinaten des Gebiets sind ungültig.',
  },
);

bool _invalidHoleBoundaryContact(
  List<KMapCenter> outer,
  List<KMapCenter> hole,
) {
  final contacts = <KMapCenter>[];
  void addContact(KMapCenter point) {
    if (!contacts.any((contact) => _samePoint(contact, point))) {
      contacts.add(point);
    }
  }

  for (var i = 0; i < outer.length; i++) {
    final outerStart = outer[i], outerEnd = outer[(i + 1) % outer.length];
    for (var j = 0; j < hole.length; j++) {
      final holeStart = hole[j], holeEnd = hole[(j + 1) % hole.length];
      if (_segmentsProperlyIntersect(
        outerStart,
        outerEnd,
        holeStart,
        holeEnd,
      )) {
        return true;
      }
      if (_onSegment(holeStart, holeEnd, outerStart)) addContact(outerStart);
      if (_onSegment(holeStart, holeEnd, outerEnd)) addContact(outerEnd);
      if (_onSegment(outerStart, outerEnd, holeStart)) addContact(holeStart);
      if (_onSegment(outerStart, outerEnd, holeEnd)) addContact(holeEnd);
      if (contacts.length > 1) return true;
    }
  }
  return false;
}

bool _geometryOverlaps(List<KMapPolygon> a, List<KMapPolygon> b) {
  if (!a.any((left) => b.any((right) => _overlaps(left.outer, right.outer)))) {
    return false;
  }
  final area = kMapZoneGeometryArea(a);
  try {
    return area - kMapZoneGeometryArea(subtractKMapZoneGeometry(a, b)) >
        math.max(1e-14, area * 1e-10);
  } catch (_) {
    return true;
  }
}

bool _validCoordinate(KMapCenter point) =>
    point.longitude.isFinite &&
    point.latitude.isFinite &&
    point.longitude >= -180 &&
    point.longitude <= 180 &&
    point.latitude >= -90 &&
    point.latitude <= 90;

bool _crossesAntimeridian(List<KMapCenter> ring) {
  if (ring.length < 2) return false;
  for (var i = 0; i < ring.length; i++) {
    if ((ring[i].longitude - ring[(i + 1) % ring.length].longitude).abs() >
        180) {
      return true;
    }
  }
  return false;
}

bool _hasDegenerateGeometry(List<KMapCenter> ring) {
  final cleaned = _validationRing(ring);
  return cleaned.length < 3 ||
      _signedArea(cleaned).abs() <= _areaEpsilon(cleaned, cleaned);
}

bool _selfIntersects(List<KMapCenter> ring) {
  ring = _validationRing(ring);
  if (ring.length < 3) return true;
  final segments = [
    for (var index = 0; index < ring.length; index++)
      (
        index: index,
        start: ring[index],
        end: ring[(index + 1) % ring.length],
        minLongitude: math.min(
          ring[index].longitude,
          ring[(index + 1) % ring.length].longitude,
        ),
        maxLongitude: math.max(
          ring[index].longitude,
          ring[(index + 1) % ring.length].longitude,
        ),
        minLatitude: math.min(
          ring[index].latitude,
          ring[(index + 1) % ring.length].latitude,
        ),
        maxLatitude: math.max(
          ring[index].latitude,
          ring[(index + 1) % ring.length].latitude,
        ),
      ),
  ]..sort((first, second) => first.minLongitude.compareTo(second.minLongitude));
  for (var firstOffset = 0; firstOffset < segments.length; firstOffset++) {
    final first = segments[firstOffset];
    for (
      var secondOffset = firstOffset + 1;
      secondOffset < segments.length;
      secondOffset++
    ) {
      final second = segments[secondOffset];
      if (second.minLongitude > first.maxLongitude) break;
      final adjacent =
          (first.index + 1) % ring.length == second.index ||
          (second.index + 1) % ring.length == first.index;
      if (!adjacent &&
          second.maxLatitude >= first.minLatitude &&
          second.minLatitude <= first.maxLatitude &&
          _segmentsIntersect(
            first.start,
            first.end,
            second.start,
            second.end,
          )) {
        return true;
      }
    }
  }
  return false;
}

List<KMapCenter> _validationRing(List<KMapCenter> ring) {
  final result = <KMapCenter>[];
  for (final point in ring) {
    if (result.isEmpty || !_samePoint(result.last, point)) result.add(point);
  }
  while (result.length > 1 && _samePoint(result.first, result.last)) {
    result.removeLast();
  }
  return result;
}

bool _samePoint(KMapCenter a, KMapCenter b) =>
    (a.longitude - b.longitude).abs() <= 1e-12 &&
    (a.latitude - b.latitude).abs() <= 1e-12;

bool _overlaps(List<KMapCenter> a, List<KMapCenter> b) {
  for (var i = 0; i < a.length; i++) {
    for (var j = 0; j < b.length; j++) {
      if (_segmentsProperlyIntersect(
        a[i],
        a[(i + 1) % a.length],
        b[j],
        b[(j + 1) % b.length],
      )) {
        return true;
      }
    }
  }

  if (a.any((point) => _strictlyInside(b, point)) ||
      b.any((point) => _strictlyInside(a, point))) {
    return true;
  }
  if (_edgeIntervalsEnter(a, b) || _edgeIntervalsEnter(b, a)) return true;

  final sameArea =
      (_signedArea(a).abs() - _signedArea(b).abs()).abs() <= _areaEpsilon(a, b);
  return sameArea &&
      a.every((point) => _onBoundary(b, point)) &&
      b.every((point) => _onBoundary(a, point));
}

bool _edgeIntervalsEnter(List<KMapCenter> ring, List<KMapCenter> other) {
  for (var i = 0; i < ring.length; i++) {
    final start = ring[i];
    final end = ring[(i + 1) % ring.length];
    final values = <double>[0, 1];
    for (final point in other) {
      if (_onSegment(start, end, point)) {
        values.add(_edgeParameter(start, end, point));
      }
    }
    values.sort();
    final distinct = <double>[];
    for (final value in values) {
      if (distinct.isEmpty || (value - distinct.last).abs() > 1e-12) {
        distinct.add(value.clamp(0, 1));
      }
    }
    for (var j = 0; j + 1 < distinct.length; j++) {
      if (distinct[j + 1] - distinct[j] <= 1e-12) continue;
      final t = (distinct[j] + distinct[j + 1]) / 2;
      final sample = KMapCenter(
        longitude: start.longitude + (end.longitude - start.longitude) * t,
        latitude: start.latitude + (end.latitude - start.latitude) * t,
      );
      if (_strictlyInside(other, sample)) return true;
    }
  }
  return false;
}

double _edgeParameter(KMapCenter start, KMapCenter end, KMapCenter point) {
  final dx = end.longitude - start.longitude;
  final dy = end.latitude - start.latitude;
  return dx.abs() >= dy.abs()
      ? (point.longitude - start.longitude) / dx
      : (point.latitude - start.latitude) / dy;
}

bool _strictlyInside(List<KMapCenter> ring, KMapCenter point) {
  if (_onBoundary(ring, point)) return false;
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i];
    final b = ring[j];
    final crosses =
        (a.latitude > point.latitude) != (b.latitude > point.latitude) &&
        point.longitude <
            (b.longitude - a.longitude) *
                    (point.latitude - a.latitude) /
                    (b.latitude - a.latitude) +
                a.longitude;
    if (crosses) inside = !inside;
  }
  return inside;
}

bool _onBoundary(List<KMapCenter> ring, KMapCenter point) {
  for (var i = 0; i < ring.length; i++) {
    if (_onSegment(ring[i], ring[(i + 1) % ring.length], point)) return true;
  }
  return false;
}

bool _segmentsProperlyIntersect(
  KMapCenter a,
  KMapCenter b,
  KMapCenter c,
  KMapCenter d,
) {
  final abC = _orientation(a, b, c);
  final abD = _orientation(a, b, d);
  final cdA = _orientation(c, d, a);
  final cdB = _orientation(c, d, b);
  return abC != 0 &&
      abD != 0 &&
      cdA != 0 &&
      cdB != 0 &&
      abC != abD &&
      cdA != cdB;
}

bool _segmentsIntersect(
  KMapCenter a,
  KMapCenter b,
  KMapCenter c,
  KMapCenter d,
) {
  if (_segmentsProperlyIntersect(a, b, c, d)) return true;
  return _onSegment(a, b, c) ||
      _onSegment(a, b, d) ||
      _onSegment(c, d, a) ||
      _onSegment(c, d, b);
}

int _orientation(KMapCenter a, KMapCenter b, KMapCenter c) {
  final cross =
      (b.longitude - a.longitude) * (c.latitude - a.latitude) -
      (b.latitude - a.latitude) * (c.longitude - a.longitude);
  final epsilon = _linearEpsilon(a, b, c);
  if (cross > epsilon) return 1;
  if (cross < -epsilon) return -1;
  return 0;
}

bool _onSegment(KMapCenter a, KMapCenter b, KMapCenter point) {
  if (_orientation(a, b, point) != 0) return false;
  const epsilon = 1e-12;
  return point.longitude >= math.min(a.longitude, b.longitude) - epsilon &&
      point.longitude <= math.max(a.longitude, b.longitude) + epsilon &&
      point.latitude >= math.min(a.latitude, b.latitude) - epsilon &&
      point.latitude <= math.max(a.latitude, b.latitude) + epsilon;
}

double _linearEpsilon(KMapCenter a, KMapCenter b, KMapCenter c) {
  final scale = math.max(
    1e-12,
    math.max(
      math.max(
        (b.longitude - a.longitude).abs(),
        (b.latitude - a.latitude).abs(),
      ),
      math.max(
        (c.longitude - a.longitude).abs(),
        (c.latitude - a.latitude).abs(),
      ),
    ),
  );
  return 2.220446049250313e-16 * 64 * scale * scale;
}

double _signedArea(List<KMapCenter> ring) {
  final origin = ring.first;
  var twiceArea = 0.0;
  for (var i = 0; i < ring.length; i++) {
    final a = ring[i];
    final b = ring[(i + 1) % ring.length];
    twiceArea +=
        (a.longitude - origin.longitude) * (b.latitude - origin.latitude) -
        (b.longitude - origin.longitude) * (a.latitude - origin.latitude);
  }
  return twiceArea / 2;
}

double _areaEpsilon(List<KMapCenter> a, List<KMapCenter> b) {
  final points = [...a, ...b];
  final minLng = points.map((p) => p.longitude).reduce(math.min);
  final maxLng = points.map((p) => p.longitude).reduce(math.max);
  final minLat = points.map((p) => p.latitude).reduce(math.min);
  final maxLat = points.map((p) => p.latitude).reduce(math.max);
  final scale = math.max(1e-6, math.max(maxLng - minLng, maxLat - minLat));
  return 2.220446049250313e-16 * 64 * scale * scale;
}
