import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_map_zone_editor.dart';

const outer = [
  KMapCenter(longitude: 0, latitude: 0),
  KMapCenter(longitude: 4, latitude: 0),
  KMapCenter(longitude: 4, latitude: 4),
  KMapCenter(longitude: 0, latitude: 4),
];

KMapZone zone(List<KMapCenter> hole, {List<KMapCenter> boundary = outer}) =>
    KMapZone(
      id: 'postal',
      name: 'Postal',
      kind: 'postal',
      coordinates: boundary,
      polygons: [
        KMapPolygon(outer: boundary, holes: [hole]),
      ],
    );

void main() {
  test('a postal hole may touch its outer ring at one point', () {
    expect(
      validateKMapZones([
        zone(const [
          KMapCenter(longitude: 0, latitude: 2),
          KMapCenter(longitude: 1, latitude: 1),
          KMapCenter(longitude: 1, latitude: 3),
        ]),
      ]),
      isNull,
    );
  });

  test('postal holes still reject crossings and shared boundary edges', () {
    for (final hole in [
      const [
        KMapCenter(longitude: -1, latitude: 2),
        KMapCenter(longitude: 1, latitude: 1),
        KMapCenter(longitude: 1, latitude: 3),
      ],
      const [
        KMapCenter(longitude: 0, latitude: 1),
        KMapCenter(longitude: 1, latitude: 1),
        KMapCenter(longitude: 1, latitude: 3),
        KMapCenter(longitude: 0, latitude: 3),
      ],
    ]) {
      expect(
        validateKMapZones([zone(hole)])?.code,
        KMapZoneValidationCode.selfIntersection,
      );
    }
  });

  test(
    'a hole edge cannot leave a concave outer ring through boundary vertices',
    () {
      const concave = [
        KMapCenter(longitude: 0, latitude: 0),
        KMapCenter(longitude: 4, latitude: 0),
        KMapCenter(longitude: 4, latitude: 4),
        KMapCenter(longitude: 2, latitude: 2),
        KMapCenter(longitude: 0, latitude: 4),
      ];
      const outsideInterval = [
        KMapCenter(longitude: 1, latitude: 3),
        KMapCenter(longitude: 3, latitude: 3),
        KMapCenter(longitude: 2, latitude: 1),
      ];
      expect(
        validateKMapZones([zone(outsideInterval, boundary: concave)])?.code,
        KMapZoneValidationCode.selfIntersection,
      );
    },
  );
}
