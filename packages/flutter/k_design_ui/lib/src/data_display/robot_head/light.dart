// Physically-minded studio lighting ported from robot-heads (MIT; see the Web
// package LICENSE.robot-heads). All calculations are in linear light.
import 'dart:math' as math;
import 'dart:ui';

import 'geometry.dart';

final class Material {
  const Material({
    required this.albedo,
    required this.f0,
    required this.metal,
    required this.spec,
    required this.shininess,
    required this.rim,
  });

  final V3 albedo;
  final double f0, metal, spec, shininess, rim;
}

V3 _n3(double x, double y, double z) {
  final l = math.sqrt(x * x + y * y + z * z);
  return (x: x / l, y: y / l, z: z / l);
}

final V3 keyLight = _n3(-0.5, -0.78, 0.62);
final V3 _fill = _n3(0.85, 0.15, 0.5);
final V3 _back = _n3(0.55, -0.55, -0.62);
final V3 _half = _n3(keyLight.x, keyLight.y, keyLight.z + 1);

double _smooth(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _environment(double rx, double ry, double rz) {
  final up = -ry;
  final horizon = 0.05 + 0.12 * _smooth(-0.25, 0.3, up);
  final softbox =
      1.1 * _smooth(0.42, 0.78, up) * _smooth(-0.9, -0.2, rz - 0.6 * rx.abs());
  final window =
      2.6 *
      _smooth(0.86, 0.97, rx * keyLight.x + ry * keyLight.y + rz * keyLight.z);
  final strip =
      0.5 *
      _smooth(0.6, 0.85, -rx) *
      _smooth(-0.35, 0.05, up) *
      (1 - _smooth(0.2, 0.5, up));
  return horizon + softbox + window + strip;
}

double _toLinear(num c) => math.pow(c / 255, 2.2).toDouble();

V3 linear(List<num> rgb) =>
    (x: _toLinear(rgb[0]), y: _toLinear(rgb[1]), z: _toLinear(rgb[2]));

int _display(double x) {
  final t = (x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14);
  return (255 * math.pow(t.clamp(0.0, 1.0), 1 / 2.2)).round();
}

V3 radiance(Material material, double nx, double ny, double nz) {
  final ndl = nx * keyLight.x + ny * keyLight.y + nz * keyLight.z;
  final key = math.max(0.0, (ndl + 0.12) / 1.12);
  final fill = math.max(0.0, nx * _fill.x + ny * _fill.y + nz * _fill.z);
  final sky = 0.5 - 0.5 * ny;
  final ndv = math.max(0.0, nz);
  final fres = material.f0 + (1 - material.f0) * math.pow(1 - ndv, 5);
  final rx = 2 * ndv * nx, ry = 2 * ndv * ny, rz = 2 * ndv * nz - 1;
  final env = _environment(rx, ry, rz) * fres;
  final spec =
      material.spec *
      math.pow(
        math.max(0.0, nx * _half.x + ny * _half.y + nz * _half.z),
        material.shininess,
      );
  final back = math.max(0.0, nx * _back.x + ny * _back.y + nz * _back.z);
  final rim = material.rim * back * back * math.pow(1 - ndv, 1.6);
  final diffuse = 0.05 + 0.1 * sky + 1.25 * key + 0.16 * fill;
  double channel(double albedo, double rimTint) {
    final tint = 1 - material.metal + material.metal * albedo * 2.2;
    return albedo * diffuse * (1 - fres * 0.6) +
        (env + spec) * tint +
        rim * rimTint * (0.35 + albedo);
  }

  return (
    x: channel(material.albedo.x, 0.62),
    y: channel(material.albedo.y, 0.78),
    z: channel(material.albedo.z, 1),
  );
}

Color displayColor(V3 color, [double alpha = 1]) => Color.fromRGBO(
  _display(color.x),
  _display(color.y),
  _display(color.z),
  alpha,
);

Color shadeColor(Material material, double nx, double ny, double nz) =>
    displayColor(radiance(material, nx, ny, nz));

double luma(V3 color) => 0.2126 * color.x + 0.7152 * color.y + 0.0722 * color.z;
