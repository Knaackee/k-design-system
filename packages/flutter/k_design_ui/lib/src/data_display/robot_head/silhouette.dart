import 'dart:typed_data';
import 'dart:ui';

/// Exact projected envelope of the convex robot shell. A simple contour avoids
/// tessellating hundreds of overlapping face contours just to clip the grain.
Path shellSilhouette(Float32List xyz, int count) {
  final points = List.generate(
    count,
    (i) => Offset(xyz[i * 3], xyz[i * 3 + 1]),
  );
  points.sort((a, b) {
    final x = a.dx.compareTo(b.dx);
    return x == 0 ? a.dy.compareTo(b.dy) : x;
  });
  double cross(Offset a, Offset b, Offset c) =>
      (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
  final hull = <Offset>[];
  for (final p in points) {
    while (hull.length >= 2 &&
        cross(hull[hull.length - 2], hull.last, p) <= 0) {
      hull.removeLast();
    }
    hull.add(p);
  }
  final lower = hull.length;
  for (var i = points.length - 2; i >= 0; i--) {
    final p = points[i];
    while (hull.length > lower &&
        cross(hull[hull.length - 2], hull.last, p) <= 0) {
      hull.removeLast();
    }
    hull.add(p);
  }
  if (hull.isNotEmpty) hull.removeLast();
  return Path()..addPolygon(hull, true);
}
