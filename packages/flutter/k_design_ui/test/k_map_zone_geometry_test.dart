import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_map_zone_editor.dart';

void main() {
  const west = KMapZone(
    id: 'zone-berlin-west',
    name: 'Berlin West',
    color: '#2563eb',
    coordinates: [
      KMapCenter(longitude: 13.382, latitude: 52.515),
      KMapCenter(longitude: 13.397, latitude: 52.515),
      KMapCenter(longitude: 13.397, latitude: 52.526),
      KMapCenter(longitude: 13.382, latitude: 52.526),
    ],
  );
  const east = KMapZone(
    id: 'zone-berlin-east',
    name: 'Berlin Ost',
    color: '#d97706',
    coordinates: [
      KMapCenter(longitude: 13.397, latitude: 52.515),
      KMapCenter(longitude: 13.412, latitude: 52.515),
      KMapCenter(longitude: 13.412, latitude: 52.526),
      KMapCenter(longitude: 13.397, latitude: 52.526),
    ],
  );

  test('adjacent Berlin fixtures may share their complete boundary', () {
    expect(validateKMapZones(const [west, east]), isNull);
  });

  test(
    'rejects axis-aligned overlap even when vertices stay on boundaries',
    () {
      final shifted = east.copyWith(
        coordinates: const [
          KMapCenter(longitude: 13.390, latitude: 52.515),
          KMapCenter(longitude: 13.405, latitude: 52.515),
          KMapCenter(longitude: 13.405, latitude: 52.526),
          KMapCenter(longitude: 13.390, latitude: 52.526),
        ],
      );

      expect(
        validateKMapZones([west, shifted])?.code,
        KMapZoneValidationCode.zoneOverlap,
      );
    },
  );

  test('rejects equality, containment, and proper crossings', () {
    const equal = KMapZone(
      id: 'equal',
      name: 'Equal',
      coordinates: [
        KMapCenter(longitude: 13.382, latitude: 52.515),
        KMapCenter(longitude: 13.397, latitude: 52.515),
        KMapCenter(longitude: 13.397, latitude: 52.526),
        KMapCenter(longitude: 13.382, latitude: 52.526),
      ],
    );
    expect(
      validateKMapZones([west, equal])?.code,
      KMapZoneValidationCode.zoneOverlap,
    );

    final triangle = KMapZone(
      id: 'triangle',
      name: 'Triangle',
      coordinates: const [
        KMapCenter(longitude: 13.382, latitude: 52.515),
        KMapCenter(longitude: 13.397, latitude: 52.515),
        KMapCenter(longitude: 13.3895, latitude: 52.526),
      ],
    );
    expect(
      validateKMapZones([west, triangle])?.code,
      KMapZoneValidationCode.zoneOverlap,
    );

    final crossing = KMapZone(
      id: 'crossing',
      name: 'Crossing',
      coordinates: const [
        KMapCenter(longitude: 13.390, latitude: 52.510),
        KMapCenter(longitude: 13.405, latitude: 52.520),
        KMapCenter(longitude: 13.390, latitude: 52.530),
      ],
    );
    expect(
      validateKMapZones([west, crossing])?.code,
      KMapZoneValidationCode.zoneOverlap,
    );
  });

  test(
    'ignores transient duplicates but keeps bowties and collapsed rings invalid',
    () {
      final duplicate = [
        const KMapCenter(longitude: 0, latitude: 0),
        const KMapCenter(longitude: 2, latitude: 0),
        const KMapCenter(longitude: 2, latitude: 0),
        const KMapCenter(longitude: 2, latitude: 2),
        const KMapCenter(longitude: 0, latitude: 2),
      ];
      expect(
        validateKMapZones([
          KMapZone(
            id: 'duplicate',
            name: 'Duplicate',
            color: '#2563eb',
            coordinates: duplicate,
          ),
        ]),
        isNull,
      );
      expect(
        validateKMapZones([
          KMapZone(
            id: 'bowtie',
            name: 'Bowtie',
            color: '#2563eb',
            coordinates: const [
              KMapCenter(longitude: 0, latitude: 0),
              KMapCenter(longitude: 2, latitude: 2),
              KMapCenter(longitude: 0, latitude: 2),
              KMapCenter(longitude: 2, latitude: 0),
            ],
          ),
        ])?.code,
        KMapZoneValidationCode.selfIntersection,
      );
      expect(
        validateKMapZones([
          KMapZone(
            id: 'collapsed',
            name: 'Collapsed',
            color: '#2563eb',
            coordinates: const [
              KMapCenter(longitude: 0, latitude: 0),
              KMapCenter(longitude: 0, latitude: 0),
              KMapCenter(longitude: 0, latitude: 0),
            ],
          ),
        ])?.code,
        KMapZoneValidationCode.selfIntersection,
      );
    },
  );

  test('validates an 8580-point ring without reducing its vertices', () {
    final ring = List.generate(8580, (index) {
      final angle = index / 8580 * 3.141592653589793 * 2;
      return KMapCenter(
        longitude: 10 + 0.1 * math.cos(angle),
        latitude: 50 + 0.1 * math.sin(angle),
      );
    });
    final zone = KMapZone(
      id: 'large-ring',
      name: 'Large ring',
      color: '#2563eb',
      coordinates: ring,
    );
    expect(validateKMapZones([zone]), isNull);
    expect(zone.coordinates.length, 8580);
  });

  test('detects a sub-meter self crossing at Berlin coordinates', () {
    const tinyBowTie = KMapZone(
      id: 'tiny',
      name: 'Tiny',
      coordinates: [
        KMapCenter(longitude: 13.4000000, latitude: 52.5200000),
        KMapCenter(longitude: 13.4000040, latitude: 52.5200040),
        KMapCenter(longitude: 13.4000000, latitude: 52.5200040),
        KMapCenter(longitude: 13.4000040, latitude: 52.5200000),
      ],
    );

    expect(
      validateKMapZones(const [tinyBowTie])?.code,
      KMapZoneValidationCode.selfIntersection,
    );
  });

  test('detects containment split by a boundary T-junction', () {
    const concave = KMapZone(
      id: 'concave',
      name: 'Concave',
      coordinates: [
        KMapCenter(longitude: 0, latitude: 0),
        KMapCenter(longitude: 1, latitude: 0),
        KMapCenter(longitude: 1, latitude: -1),
        KMapCenter(longitude: 2, latitude: 0),
        KMapCenter(longitude: 2, latitude: 2),
        KMapCenter(longitude: 0, latitude: 2),
      ],
    );
    const outer = KMapZone(
      id: 'outer',
      name: 'Outer',
      coordinates: [
        KMapCenter(longitude: 0, latitude: 0),
        KMapCenter(longitude: 2, latitude: 0),
        KMapCenter(longitude: 2, latitude: 2),
        KMapCenter(longitude: 0, latitude: 2),
      ],
    );

    expect(
      validateKMapZones(const [concave, outer])?.code,
      KMapZoneValidationCode.zoneOverlap,
    );
  });

  test('rejects antimeridian-spanning rings in the first slice', () {
    const zone = KMapZone(
      id: 'antimeridian',
      name: 'Antimeridian',
      coordinates: [
        KMapCenter(longitude: 179, latitude: 10),
        KMapCenter(longitude: -179, latitude: 10),
        KMapCenter(longitude: -179, latitude: 11),
        KMapCenter(longitude: 179, latitude: 11),
      ],
    );

    expect(
      validateKMapZones(const [zone])?.code,
      KMapZoneValidationCode.invalidCoordinate,
    );
  });

  test('rejects duplicate zone IDs', () {
    expect(
      validateKMapZones(
        [west, east.copyWith(name: 'Duplicate')].map((zone) {
          if (zone.id == east.id) {
            return KMapZone(
              id: west.id,
              name: zone.name,
              coordinates: zone.coordinates,
            );
          }
          return zone;
        }).toList(),
      )?.code,
      KMapZoneValidationCode.invalidCoordinate,
    );
  });
}
