// Native Flutter port of robot-heads' TV geometry (MIT; see the Web package
// LICENSE.robot-heads). Coordinates are head units: x right, y down, z forward.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'types.dart';

typedef V3 = ({double x, double y, double z});
typedef Screw = ({double x, double y, double angle});

abstract final class HeadGeometry {
  static const bevel = 0.075;
  static const margin = 0.045;
  static const gasket = 0.022;
  static const recess = 0.03;
  static const earY = 0.03;
  static const stem = 0.2;
  static const ball = 0.052;
}

abstract final class HeadInset {
  static const plate = HeadGeometry.bevel;
  static const hole = HeadGeometry.bevel + HeadGeometry.margin;
  static const glass =
      HeadGeometry.bevel + HeadGeometry.margin + HeadGeometry.gasket;
}

final class Mesh {
  const Mesh(this.pos, this.quads, this.normals);
  final Float32List pos;
  final Uint16List quads;
  final Float32List normals;
}

List<double> rotation(double yaw, double pitch, double roll) {
  final cy = math.cos(yaw), sy = math.sin(yaw);
  final cp = math.cos(pitch), sp = math.sin(pitch);
  final cr = math.cos(roll), sr = math.sin(roll);
  final a = <double>[cy, sy * sp, sy * cp, 0, cp, -sp, -sy, cy * sp, cy * cp];
  return <double>[
    cr * a[0] - sr * a[3],
    cr * a[1] - sr * a[4],
    cr * a[2] - sr * a[5],
    sr * a[0] + cr * a[3],
    sr * a[1] + cr * a[4],
    sr * a[2] + cr * a[5],
    a[6],
    a[7],
    a[8],
  ];
}

V3 rotate(List<double> m, double x, double y, double z) => (
  x: m[0] * x + m[1] * y + m[2] * z,
  y: m[3] * x + m[4] * y + m[5] * z,
  z: m[6] * x + m[7] * y + m[8] * z,
);

V3 _norm(double x, double y, double z) {
  final l = math.sqrt(x * x + y * y + z * z);
  final d = l == 0 ? 1.0 : l;
  return (x: x / d, y: y / d, z: z / d);
}

final class ShapeCorner {
  const ShapeCorner(this.x, this.y, this.a0, this.a1);
  final double x, y, a0, a1;
}

final class Shape {
  const Shape({
    required this.name,
    required this.r,
    required this.depth,
    required this.corners,
    required this.hx,
    required this.hy,
    required this.pitch,
    required this.earX,
    required this.screws,
    required this.backScrews,
    required this.signedDistance,
  });
  final KRobotHeadShape name;
  final double r, depth, hx, hy, pitch, earX;
  final List<ShapeCorner> corners;
  final List<Screw> screws, backScrews;
  final double Function(double x, double y, double inset) signedDistance;

  double sd(double x, double y, double inset) => signedDistance(x, y, inset);

  Path path(double inset) {
    final path = Path();
    final rr = math.max(0.0005, r - inset);
    for (var i = 0; i < corners.length; i++) {
      final c = corners[i];
      if (i == 0) {
        path.moveTo(c.x + rr * math.cos(c.a0), c.y + rr * math.sin(c.a0));
      }
      path.arcTo(
        Rect.fromCircle(center: Offset(c.x, c.y), radius: rr),
        c.a0,
        c.a1 - c.a0,
        false,
      );
    }
    return path..close();
  }
}

const _tau = math.pi * 2;
const _faceShare = 0.6;
const _corners = <double>[45, 135];
const _backCorners = <double>[-135, -45, 45, 135];

Shape _makeShape(
  KRobotHeadShape name,
  List<Offset> centres,
  double radius,
  double depth,
  List<double> screwAt,
  List<double> backScrewAt,
) {
  final pts =
      centres.map((p) => (x: p.dx, y: p.dy, t: math.atan2(p.dy, p.dx))).toList()
        ..sort((a, b) => a.t.compareTo(b.t));
  final n = pts.length;
  final edge = <double>[];
  for (var i = 0; i < n; i++) {
    final a = pts[i], b = pts[(i + 1) % n];
    edge.add(math.atan2(-(b.x - a.x), b.y - a.y));
  }
  final corners = <ShapeCorner>[];
  for (var i = 0; i < n; i++) {
    final p = pts[i];
    if (n == 1) {
      corners.add(ShapeCorner(p.x, p.y, -math.pi, math.pi));
      continue;
    }
    final a0 = edge[(i - 1 + n) % n];
    var a1 = edge[i];
    while (a1 < a0) {
      a1 += _tau;
    }
    corners.add(ShapeCorner(p.x, p.y, a0, a1));
  }
  double sdPoly(double x, double y) {
    if (n == 1) {
      return math.sqrt(math.pow(x - pts[0].x, 2) + math.pow(y - pts[0].y, 2));
    }
    var d = double.infinity;
    var inside = true;
    for (var i = 0; i < n; i++) {
      final a = pts[i], b = pts[(i + 1) % n];
      final ex = b.x - a.x, ey = b.y - a.y, px = x - a.x, py = y - a.y;
      final t = ((px * ex + py * ey) / (ex * ex + ey * ey)).clamp(0.0, 1.0);
      d = math.min(
        d,
        math.sqrt(math.pow(px - ex * t, 2) + math.pow(py - ey * t, 2)),
      );
      if (ex * py - ey * px < 0) inside = false;
    }
    return inside ? -d : d;
  }

  double sd(double x, double y, double inset) =>
      sdPoly(x, y) - (radius - inset);
  var hx = 0.0, hy = 0.0;
  for (final p in pts) {
    hx = math.max(hx, p.x.abs() + radius);
    hy = math.max(hy, p.y.abs() + radius);
  }
  var lo = 0.0, hi = hx + 0.1;
  for (var i = 0; i < 40; i++) {
    final mid = (lo + hi) / 2;
    if (sd(mid, HeadGeometry.earY, 0) < 0) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  List<Screw> place(List<double> dirs, double inward) => [
    for (var i = 0; i < dirs.length; i++)
      () {
        final a = dirs[i] * math.pi / 180;
        final c = corners.firstWhere(
          (k) => [
            a,
            a + _tau,
            a - _tau,
          ].any((x) => x >= k.a0 - 1e-6 && x <= k.a1 + 1e-6),
          orElse: () => corners[0],
        );
        return (
          x: c.x + math.cos(a) * (radius - inward),
          y: c.y + math.sin(a) * (radius - inward),
          angle: 0.5 + i * 0.9,
        );
      }(),
  ];
  final gw = 2 * (hx - HeadInset.glass), gh = 2 * (hy - HeadInset.glass);
  return Shape(
    name: name,
    r: radius,
    depth: depth,
    corners: corners,
    hx: hx,
    hy: hy,
    pitch: math.min((_faceShare * gw) / 14, (0.65 * gh) / 10),
    earX: lo - 0.008,
    screws: place(screwAt, (HeadInset.hole - 0.018 + HeadInset.plate) / 2),
    backScrews: place(backScrewAt, HeadInset.plate + 0.07),
    signedDistance: sd,
  );
}

final _shapeCache = <KRobotHeadShape, Shape>{};
Shape getShape(KRobotHeadShape name) => _shapeCache.putIfAbsent(
  name,
  () => switch (name) {
    KRobotHeadShape.rectangle => _makeShape(
      name,
      const [
        Offset(-.29, -.17),
        Offset(.29, -.17),
        Offset(.29, .17),
        Offset(-.29, .17),
      ],
      .21,
      .6,
      _corners,
      _backCorners,
    ),
    KRobotHeadShape.square => _makeShape(
      name,
      const [
        Offset(-.22, -.22),
        Offset(.22, -.22),
        Offset(.22, .22),
        Offset(-.22, .22),
      ],
      .2,
      .6,
      _corners,
      _backCorners,
    ),
    KRobotHeadShape.circle => _makeShape(
      name,
      const [Offset.zero],
      .46,
      .56,
      _corners,
      _backCorners,
    ),
    KRobotHeadShape.hexagon => _makeShape(
      name,
      [
        for (final d in [0, 60, 120, 180, 240, 300])
          Offset(
            .35 * math.cos(d * math.pi / 180),
            .35 * math.sin(d * math.pi / 180),
          ),
      ],
      .16,
      .58,
      const [60, 120],
      const [-120, -60, 60, 120],
    ),
  },
);

Mesh _finish(List<double> pos, List<int> quads, List<double> vn) {
  final normals = Float32List((quads.length ~/ 4) * 3);
  for (var q = 0; q < quads.length ~/ 4; q++) {
    var x = 0.0, y = 0.0, z = 0.0;
    for (var k = 0; k < 4; k++) {
      final i = quads[q * 4 + k] * 3;
      x += vn[i];
      y += vn[i + 1];
      z += vn[i + 2];
    }
    final v = _norm(x, y, z);
    normals.setAll(q * 3, [v.x, v.y, v.z]);
  }
  return Mesh(Float32List.fromList(pos), Uint16List.fromList(quads), normals);
}

List<int> _stitch(int rings, int samples, [bool closed = true]) {
  final q = <int>[];
  final span = closed ? samples : samples - 1;
  for (var k = 0; k < rings - 1; k++) {
    for (var j = 0; j < span; j++) {
      final j2 = (j + 1) % samples;
      q.addAll([
        k * samples + j,
        k * samples + j2,
        (k + 1) * samples + j2,
        (k + 1) * samples + j,
      ]);
    }
  }
  return q;
}

Mesh buildBody(Shape shape, [int bevelSteps = 10]) {
  final outline = <({double cx, double cy, double nx, double ny})>[];
  for (final c in shape.corners) {
    final sweep = c.a1 - c.a0;
    final steps = math.max(2, (sweep / (math.pi / 2) * 14).ceil());
    final last = sweep >= _tau - 1e-6 ? steps - 1 : steps;
    for (var i = 0; i <= last; i++) {
      final a = c.a0 + i / steps * sweep;
      outline.add((cx: c.x, cy: c.y, nx: math.cos(a), ny: math.sin(a)));
    }
  }
  final profile = <({double z, double inset, double t})>[];
  final b = HeadGeometry.bevel, zf = shape.depth / 2;
  for (var i = bevelSteps; i >= 0; i--) {
    final t = i / bevelSteps * (math.pi / 2);
    profile.add((
      z: -zf + b - b * math.sin(t),
      inset: b * (1 - math.cos(t)),
      t: -t,
    ));
  }
  for (var i = 0; i <= bevelSteps; i++) {
    final t = i / bevelSteps * (math.pi / 2);
    profile.add((
      z: zf - b + b * math.sin(t),
      inset: b * (1 - math.cos(t)),
      t: t,
    ));
  }
  final pos = <double>[], vn = <double>[];
  for (final p in profile) {
    for (final o in outline) {
      pos.addAll([
        o.cx + (shape.r - p.inset) * o.nx,
        o.cy + (shape.r - p.inset) * o.ny,
        p.z,
      ]);
      vn.addAll([o.nx * math.cos(p.t), o.ny * math.cos(p.t), math.sin(p.t)]);
    }
  }
  return _finish(pos, _stitch(profile.length, outline.length), vn);
}

Mesh buildLathe(List<Offset> profile, V3 origin, V3 axis, [int segments = 36]) {
  final e1 = axis.y.abs() > .9
      ? (x: 1.0, y: 0.0, z: 0.0)
      : (x: 0.0, y: 1.0, z: 0.0);
  final e2 = _norm(
    axis.y * e1.z - axis.z * e1.y,
    axis.z * e1.x - axis.x * e1.z,
    axis.x * e1.y - axis.y * e1.x,
  );
  final pos = <double>[], vn = <double>[];
  for (var k = 0; k < profile.length; k++) {
    final p = profile[k],
        prev = profile[math.max(0, k - 1)],
        next = profile[math.min(profile.length - 1, k + 1)];
    final dr = next.dx - prev.dx,
        dt = next.dy - prev.dy,
        l = math.sqrt(dr * dr + dt * dt);
    final nr = dt / (l == 0 ? 1 : l), na = -dr / (l == 0 ? 1 : l);
    for (var j = 0; j < segments; j++) {
      final a = j / segments * _tau,
          ca = math.cos(a),
          sa = math.sin(a),
          rx = ca * e1.x + sa * e2.x,
          ry = ca * e1.y + sa * e2.y,
          rz = ca * e1.z + sa * e2.z;
      pos.addAll([
        origin.x + axis.x * p.dy + p.dx * rx,
        origin.y + axis.y * p.dy + p.dx * ry,
        origin.z + axis.z * p.dy + p.dx * rz,
      ]);
      vn.addAll([
        rx * nr + axis.x * na,
        ry * nr + axis.y * na,
        rz * nr + axis.z * na,
      ]);
    }
  }
  return _finish(pos, _stitch(profile.length, segments), vn);
}

const _earProfile = [
  Offset(.06, -.012),
  Offset(.068, 0),
  Offset(.074, .006),
  Offset(.08, .018),
  Offset(.084, .032),
  Offset(.084, .048),
  Offset(.079, .06),
  Offset(.068, .07),
  Offset(.052, .077),
  Offset(.032, .081),
  Offset(.014, .083),
  Offset(0, .0835),
];
const _collarProfile = [
  Offset(.05, -.012),
  Offset(.052, .006),
  Offset(.05, .016),
  Offset(.042, .024),
  Offset(.026, .029),
  Offset(.014, .031),
  Offset(0, .032),
];

final class HeadMeshes {
  const HeadMeshes({
    required this.body,
    required this.earL,
    required this.earR,
    required this.collar,
  });
  final Mesh body, earL, earR, collar;
}

final _meshCache = <KRobotHeadShape, HeadMeshes>{};
HeadMeshes headMeshes(Shape s) => _meshCache.putIfAbsent(
  s.name,
  () => HeadMeshes(
    body: buildBody(s),
    earL: buildLathe(
      _earProfile,
      (x: -s.earX, y: HeadGeometry.earY, z: 0),
      (x: -1, y: 0, z: 0),
    ),
    earR: buildLathe(
      _earProfile,
      (x: s.earX, y: HeadGeometry.earY, z: 0),
      (x: 1, y: 0, z: 0),
    ),
    collar: buildLathe(
      _collarProfile,
      (x: 0, y: -s.hy, z: 0),
      (x: 0, y: -1, z: 0),
      16,
    ),
  ),
);
