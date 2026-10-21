import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_map_zone_editor.dart';
import 'package:k_design_ui/src/editors/k_map_zone_boolean.dart';

List<KMapCenter> rectangle(
  double left,
  double bottom,
  double right,
  double top,
) => [
  KMapCenter(longitude: left, latitude: bottom),
  KMapCenter(longitude: right, latitude: bottom),
  KMapCenter(longitude: right, latitude: top),
  KMapCenter(longitude: left, latitude: top),
];
List<KMapPolygon> geometry(List<KMapCenter> ring) => [KMapPolygon(outer: ring)];

void main() {
  test(
    'same web fixtures: partial reduction, containment, splits, holes, shared edges',
    () {
      final partial = subtractKMapZoneGeometry(
        geometry(rectangle(0, 0, 4, 4)),
        geometry(rectangle(2, 0, 6, 4)),
      );
      expect(kMapZoneGeometryArea(partial), closeTo(8, 1e-8));
      expect(
        subtractKMapZoneGeometry(
          geometry(rectangle(1, 1, 2, 2)),
          geometry(rectangle(0, 0, 3, 3)),
        ),
        isEmpty,
      );
      final split = subtractKMapZoneGeometry(
        geometry(rectangle(0, 0, 6, 2)),
        geometry(rectangle(2, -1, 4, 3)),
      );
      expect(split, hasLength(2));
      expect(kMapZoneGeometryArea(split), closeTo(8, 1e-8));
      final hole = subtractKMapZoneGeometry(
        geometry(rectangle(0, 0, 10, 10)),
        geometry(rectangle(3, 3, 7, 7)),
      );
      expect(hole, hasLength(1));
      expect(hole.first.holes, hasLength(1));
      expect(kMapZoneGeometryArea(hole), closeTo(84, 1e-8));
      final touching = subtractKMapZoneGeometry(
        geometry(rectangle(10, 10, 11, 11).reversed.toList()),
        geometry(rectangle(11, 10, 12, 11)),
      );
      expect(kMapZoneGeometryArea(touching), closeTo(1, 1e-8));
    },
  );
  test(
    'concave donor splits and holes with islands survive subsequent subtraction',
    () {
      final concave = [
        const KMapCenter(longitude: 0, latitude: 0),
        const KMapCenter(longitude: 6, latitude: 0),
        const KMapCenter(longitude: 6, latitude: 4),
        const KMapCenter(longitude: 4, latitude: 4),
        const KMapCenter(longitude: 4, latitude: 2),
        const KMapCenter(longitude: 2, latitude: 2),
        const KMapCenter(longitude: 2, latitude: 4),
        const KMapCenter(longitude: 0, latitude: 4),
      ];
      final cut = subtractKMapZoneGeometry(
        geometry(concave),
        geometry(rectangle(2, -1, 4, 3)),
      );
      expect(cut, hasLength(2));
      expect(kMapZoneGeometryArea(cut), closeTo(16, 1e-8));
      final donut = [
        KMapPolygon(
          outer: rectangle(0, 0, 10, 10),
          holes: [rectangle(3, 3, 7, 7)],
        ),
        KMapPolygon(outer: rectangle(4, 4, 6, 6)),
      ];
      final islands = subtractKMapZoneGeometry(
        donut,
        geometry(rectangle(9, 0, 12, 10)),
      );
      expect(islands, hasLength(2));
      expect(kMapZoneGeometryArea(islands), closeTo(78, 1e-8));
    },
  );
  test(
    'circle intersections remain finite and reversible with complete snapshot',
    () {
      const a = KMapCenter(longitude: 13.397, latitude: 52.52);
      const b = KMapCenter(longitude: 13.407, latitude: 52.52);
      final subject = geometry(createKMapCircleCoordinates(a, 2));
      final clip = geometry(createKMapCircleCoordinates(b, 2));
      final result = subtractKMapZoneGeometry(subject, clip);
      expect(result, isNotEmpty);
      expect(kMapZoneGeometryArea(result), greaterThan(0));
      expect(
        kMapZoneGeometryArea(result),
        lessThan(kMapZoneGeometryArea(subject)),
      );
      expect(
        subtractKMapZoneGeometry(result, clip).map((p) => p.outer.length),
        result.map((p) => p.outer.length),
      );
      expect(subject.single.outer, hasLength(64));
    },
  );
}
