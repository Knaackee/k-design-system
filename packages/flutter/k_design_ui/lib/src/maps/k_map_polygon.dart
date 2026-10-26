import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:maplibre/maplibre.dart' as maplibre;

import 'k_map_controller.dart';
import 'k_map_zone_models.dart';
export 'k_map_zone_models.dart';

@immutable
class KMapZone {
  const KMapZone({
    required this.id,
    required this.coordinates,
    required this.name,
    this.color,
    this.kind = 'polygon',
    this.circle,
    this.source,
    this.settings,
    this.polygons,
  });

  final String id;
  final List<KMapCenter> coordinates;
  final String name;
  final String? color;
  final String kind;
  final KMapZoneCircle? circle;
  final KMapPostalArea? source;
  final KMapZoneSettings? settings;
  final List<KMapPolygon>? polygons;
  List<KMapPolygon> get geometry =>
      polygons ?? [KMapPolygon(outer: coordinates)];

  KMapZone copyWith({
    String? name,
    List<KMapCenter>? coordinates,
    String? color,
    String? kind,
    KMapZoneCircle? circle,
    KMapPostalArea? source,
    KMapZoneSettings? settings,
    List<KMapPolygon>? polygons,
  }) => KMapZone(
    id: id,
    name: name ?? this.name,
    coordinates: coordinates ?? this.coordinates,
    color: color ?? this.color,
    kind: kind ?? this.kind,
    circle: circle ?? this.circle,
    source: source ?? this.source,
    settings: settings ?? this.settings,
    polygons: polygons ?? this.polygons,
  );
}

typedef KMapZoneCallback = void Function(String id);
typedef KMapTapCallback = void Function(KMapCenter position);

@internal
List<maplibre.Layer> buildKMapZoneLayers(
  List<KMapZone> zones,
  KDesignTokens tokens, {
  String? selectedZoneId,
  required double fillOpacity,
  required double selectedFillOpacity,
  required double strokeWidth,
  required double selectedStrokeWidth,
  required Set<String> invalidZoneIds,
}) => [
  ..._validateZones(zones),
  for (final zone in zones)
    for (final polygon in zone.geometry)
      if (polygon.outer.length >= 3) ...[
        maplibre.PolygonLayer(
          polygons: [
            maplibre.Feature(
              geometry: maplibre.Polygon.from([
                [
                  for (final point in polygon.outer)
                    maplibre.Geographic(
                      lon: point.longitude,
                      lat: point.latitude,
                    ),
                  maplibre.Geographic(
                    lon: polygon.outer.first.longitude,
                    lat: polygon.outer.first.latitude,
                  ),
                ],
                for (final hole in polygon.holes)
                  [
                    for (final point in [...hole, hole.first])
                      maplibre.Geographic(
                        lon: point.longitude,
                        lat: point.latitude,
                      ),
                  ],
              ]),
            ),
          ],
          color:
              (invalidZoneIds.contains(zone.id)
                      ? tokens.colorStatusErrorAccent
                      : _parseColor(zone.color, tokens) ??
                            tokens.colorBrandPrimaryAccent)
                  .withValues(
                    alpha: selectedZoneId == zone.id
                        ? selectedFillOpacity
                        : fillOpacity,
                  ),
          outlineColor: Colors.transparent,
        ),
        maplibre.PolylineLayer(
          polylines: [
            for (final ring in [polygon.outer, ...polygon.holes])
              maplibre.Feature(
                geometry: maplibre.LineString.from([
                  for (final point in ring)
                    maplibre.Geographic(
                      lon: point.longitude,
                      lat: point.latitude,
                    ),
                  maplibre.Geographic(
                    lon: ring.first.longitude,
                    lat: ring.first.latitude,
                  ),
                ]),
              ),
          ],
          color: invalidZoneIds.contains(zone.id)
              ? tokens.colorStatusErrorAccent
              : _parseColor(zone.color, tokens) ??
                    tokens.colorBrandPrimaryAccent,
          width: (selectedZoneId == zone.id ? selectedStrokeWidth : strokeWidth)
              .round(),
        ),
      ],
];

Iterable<maplibre.Layer> _validateZones(List<KMapZone> zones) sync* {
  final ids = <String>{};
  for (final zone in zones) {
    if (zone.id.trim().isEmpty || !ids.add(zone.id)) {
      throw ArgumentError('KMap zone IDs must be nonempty and unique');
    }
    if (zone.name.trim().isEmpty) {
      throw ArgumentError('KMap zones need an accessible name');
    }
  }
}

@internal
String? hitTestKMapZones(List<KMapZone> zones, KMapCenter position) {
  for (final zone in zones.reversed) {
    if (zone.geometry.any(
      (polygon) =>
          _contains(polygon.outer, position) &&
          !polygon.holes.any((hole) => _contains(hole, position)),
    )) {
      return zone.id;
    }
  }
  return null;
}

Color? _parseColor(String? value, KDesignTokens tokens) {
  if (value == null) return null;
  value = resolveKMapZoneColor(
    value,
    tokens.colorSurfaceRaised.computeLuminance() < .5,
  );
  final hex = value.startsWith('#') ? value.substring(1) : value;
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
  return Color(int.parse('ff$hex', radix: 16));
}

bool _contains(List<KMapCenter> ring, KMapCenter point) {
  if (ring.length < 3) return false;
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final a = ring[i];
    final b = ring[j];
    if (_onSegment(a, b, point)) return true;
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

bool _onSegment(KMapCenter a, KMapCenter b, KMapCenter point) {
  final cross =
      (b.longitude - a.longitude) * (point.latitude - a.latitude) -
      (b.latitude - a.latitude) * (point.longitude - a.longitude);
  if (cross.abs() > 1e-10) return false;
  return point.longitude >= math.min(a.longitude, b.longitude) - 1e-10 &&
      point.longitude <= math.max(a.longitude, b.longitude) + 1e-10 &&
      point.latitude >= math.min(a.latitude, b.latitude) - 1e-10 &&
      point.latitude <= math.max(a.latitude, b.latitude) + 1e-10;
}
