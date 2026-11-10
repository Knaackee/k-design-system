// Baked plate relief and glass overlays. This is a native Canvas port of the
// robot-heads raster bakes (MIT; see the Web package LICENSE.robot-heads).
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'geometry.dart';
import 'light.dart';

typedef Extents = ({double hx, double hy});

Extents plateOf(Shape shape) =>
    (hx: shape.hx - HeadInset.plate, hy: shape.hy - HeadInset.plate);
Extents glassOf(Shape shape) =>
    (hx: shape.hx - HeadInset.glass, hy: shape.hy - HeadInset.glass);

const screenOver = 0.035;
Extents screenOf(Shape shape) {
  final glass = glassOf(shape);
  return (
    hx: math.max(glass.hx, 11 * shape.pitch) + screenOver,
    hy: math.max(glass.hy, 7 * shape.pitch) + screenOver,
  );
}

double _smooth(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

double _hash(int x, int y) {
  var h = (_imul(x, 374761393) + _imul(y, 668265263)) & 0xffffffff;
  h = _imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) & 0xffffffff) / 4294967296;
}

int _imul(int a, int b) {
  final aLow = a & 0xffff, aHigh = (a >> 16) & 0xffff;
  final bLow = b & 0xffff, bHigh = (b >> 16) & 0xffff;
  return (aLow * bLow + ((aHigh * bLow + aLow * bHigh) << 16)) & 0xffffffff;
}

final V3 _half = (() {
  final l = math.sqrt(
    keyLight.x * keyLight.x +
        keyLight.y * keyLight.y +
        math.pow(keyLight.z + 1, 2),
  );
  return (x: keyLight.x / l, y: keyLight.y / l, z: (keyLight.z + 1) / l);
})();

double _tilt(
  double nx,
  double ny,
  double nz, [
  double gloss = 0.55,
  double power = 36,
]) {
  final l = math.sqrt(nx * nx + ny * ny + nz * nz);
  nx /= l;
  ny /= l;
  nz /= l;
  final diffuse =
      (nx * keyLight.x + ny * keyLight.y + nz * keyLight.z - keyLight.z) * 0.95;
  final spec =
      gloss *
      math.pow(
        math.max(0.0, nx * _half.x + ny * _half.y + nz * _half.z),
        power,
      );
  return diffuse + spec - gloss * math.pow(_half.z, power);
}

Offset _gradient(double Function(double, double) fn, double u, double v) {
  const e = 0.0015;
  final gx = fn(u + e, v) - fn(u - e, v);
  final gy = fn(u, v + e) - fn(u, v - e);
  final l = math.sqrt(gx * gx + gy * gy);
  return Offset(gx / (l == 0 ? 1 : l), gy / (l == 0 ? 1 : l));
}

double? _screw(double u, double v, Screw screw) {
  const radius = 0.013;
  final dx = u - screw.x, dy = v - screw.y;
  final distance = math.sqrt(dx * dx + dy * dy);
  if (distance > radius + 0.006) return null;
  if (distance > radius) return -0.5 * (1 - (distance - radius) / 0.006);
  final nz = math.sqrt(math.max(0, 1 - math.pow(distance / radius, 2))) + 0.6;
  var value = _tilt(dx / radius, dy / radius, nz, 0.9, 30) * 1.3 + 0.08;
  final c = math.cos(screw.angle), s = math.sin(screw.angle);
  final across = (dx * -s + dy * c).abs();
  if (across < 0.0026 && distance < radius * 0.8) value = -0.65;
  return value;
}

Future<Image> _decode(Uint8List pixels, int width, int height) {
  final completer = Completer<Image>();
  decodeImageFromPixels(
    pixels,
    width,
    height,
    PixelFormat.rgba8888,
    completer.complete,
    rowBytes: width * 4,
  );
  return completer.future;
}

Future<Image> _bakeRelief(
  Shape shape,
  double pixelsPerUnit,
  double Function(double u, double v, double px, int ix, int iy) relief,
) {
  final extents = plateOf(shape);
  final width = math.max(1, (extents.hx * 2 * pixelsPerUnit).ceil());
  final height = math.max(1, (extents.hy * 2 * pixelsPerUnit).ceil());
  final px = extents.hx * 2 / width;
  final pixels = Uint8List(width * height * 4);
  for (var iy = 0; iy < height; iy++) {
    final v = -extents.hy + (iy + 0.5) * px;
    for (var ix = 0; ix < width; ix++) {
      final u = -extents.hx + (ix + 0.5) * px;
      final edge = shape.sd(u, v, HeadInset.plate);
      final cover = (0.5 - edge / px).clamp(0.0, 1.0);
      if (cover <= 0) continue;
      final value = relief(u, v, px, ix, iy);
      final alpha = (value.abs().clamp(0.0, 1.0) * cover);
      final offset = (iy * width + ix) * 4;
      final alphaByte = (alpha * 255).round();
      // PixelFormat.rgba8888 expects premultiplied color channels.
      final channel = value > 0 ? alphaByte : 0;
      pixels[offset] = channel;
      pixels[offset + 1] = channel;
      pixels[offset + 2] = channel;
      pixels[offset + 3] = alphaByte;
    }
  }
  return _decode(pixels, width, height);
}

Future<Image> _bakeFront(Shape shape, double pixelsPerUnit) {
  const lip = 0.018;
  double hole(double u, double v) => shape.sd(u, v, HeadInset.hole);
  double glass(double u, double v) => shape.sd(u, v, HeadInset.glass);
  return _bakeRelief(shape, pixelsPerUnit, (u, v, px, ix, iy) {
    final grain = (_hash(ix, iy) - 0.5) * 0.07;
    for (final item in shape.screws) {
      final value = _screw(u, v, item);
      if (value != null) return value;
    }
    final dh = hole(u, v);
    if (dh >= 0) {
      if (dh < lip) {
        final g = _gradient(hole, u, v);
        final s = 1 - dh / lip, angle = s * s * 1.25;
        return _tilt(
              -g.dx * math.sin(angle),
              -g.dy * math.sin(angle),
              math.cos(angle),
            ) +
            grain;
      }
      return grain;
    }
    final dg = glass(u, v);
    if (dg >= 0) {
      final s = dg / HeadGeometry.gasket;
      final g = _gradient(glass, u, v), angle = (s - 0.45) * 2.2;
      return _tilt(
                g.dx * math.sin(angle),
                g.dy * math.sin(angle),
                math.cos(angle),
                0.22,
                14,
              ) *
              0.7 +
          grain * 0.4;
    }
    const k = 0.05;
    final blocked = _smooth(
      -0.012,
      0.012,
      glass(u - keyLight.x * k, v - keyLight.y * k),
    );
    return -(0.5 * blocked + 0.32 * math.exp(dg / 0.014));
  });
}

Future<Image> _bakeBack(Shape shape, double pixelsPerUnit) {
  const vents = [-0.12, -0.065, -0.01, 0.045, 0.1];
  double panel(double u, double v) => shape.sd(u, v, HeadInset.plate + 0.04);
  return _bakeRelief(shape, pixelsPerUnit, (u, v, px, ix, iy) {
    final grain = (_hash(ix, iy) - 0.5) * 0.07;
    for (final item in shape.backScrews) {
      final value = _screw(u, v, item);
      if (value != null) return value;
    }
    final dp = panel(u, v);
    if (dp.abs() < 0.006) {
      final g = _gradient(panel, u, v), angle = dp / 0.006 * 1.1;
      return _tilt(
                -g.dx * math.sin(angle),
                -g.dy * math.sin(angle),
                math.cos(angle),
              ) *
              0.9 -
          0.18;
    }
    for (final ventY in vents) {
      double slot(double a, double b) =>
          math.sqrt(
            math.pow(math.max(0, a.abs() - 0.196), 2) + math.pow(b - ventY, 2),
          ) -
          0.014;
      final distance = slot(u, v);
      if (distance < 0) {
        return -0.72 - 0.15 * _smooth(-0.014, 0, -(v - ventY));
      }
      if (distance < 0.01) {
        final g = _gradient(slot, u, v);
        final angle = math.pow(1 - distance / 0.01, 2) * 1.2;
        return _tilt(
              -g.dx * math.sin(angle),
              -g.dy * math.sin(angle),
              math.cos(angle),
            ) +
            grain;
      }
    }
    return grain;
  });
}

final class RobotBakes {
  RobotBakes(Shape shape, double pixelsPerUnit) {
    Future.wait([
      _bakeFront(shape, pixelsPerUnit),
      _bakeBack(shape, pixelsPerUnit),
    ]).then((images) {
      if (_disposed) {
        for (final image in images) {
          image.dispose();
        }
        return;
      }
      front = images[0];
      back = images[1];
      final listeners = List<VoidCallback>.of(_listeners);
      _listeners.clear();
      for (final listener in listeners) {
        listener();
      }
    });
  }

  Image? front, back;
  final Set<VoidCallback> _listeners = {};
  bool _disposed = false;

  bool get ready => front != null && back != null;

  void addListener(VoidCallback? listener) {
    if (!ready && !_disposed && listener != null) _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _listeners.clear();
    front?.dispose();
    back?.dispose();
    front = null;
    back = null;
  }
}

final _cache = <String, RobotBakes>{};

RobotBakes bakesFor(
  Shape shape,
  double pixelsPerUnit, [
  VoidCallback? onReady,
]) {
  final rounded = pixelsPerUnit.round();
  final key = '${shape.name.name}:$rounded';
  final cached = _cache[key];
  if (cached != null) {
    cached.addListener(onReady);
    return cached;
  }
  final result = RobotBakes(shape, rounded.toDouble())..addListener(onReady);
  _cache[key] = result;
  if (_cache.length > 24) {
    final oldest = _cache.keys.first;
    _cache.remove(oldest)?.dispose();
  }
  return result;
}

Image? _grain;
Future<Image>? _grainPending;
final Set<VoidCallback> _grainListeners = {};
var _grainGeneration = 0;

Image? grainFor([VoidCallback? onReady]) {
  if (_grain != null) return _grain;
  if (onReady != null) _grainListeners.add(onReady);
  if (_grainPending != null) return null;
  final pixels = Uint8List(128 * 128 * 4);
  for (var i = 0; i < 128 * 128; i++) {
    final alpha = (_hash(i, 13) * 9).round();
    // PixelFormat.rgba8888 expects premultiplied color channels.
    final channel = _hash(i, 7) > .5 ? alpha : 0;
    pixels[i * 4] = channel;
    pixels[i * 4 + 1] = channel;
    pixels[i * 4 + 2] = channel;
    pixels[i * 4 + 3] = alpha;
  }
  final generation = _grainGeneration;
  _grainPending = _decode(pixels, 128, 128)
    ..then((image) {
      _grainPending = null;
      if (generation != _grainGeneration) {
        image.dispose();
        return;
      }
      _grain = image;
      final listeners = List<VoidCallback>.of(_grainListeners);
      _grainListeners.clear();
      for (final listener in listeners) {
        listener();
      }
    });
  return null;
}

void removeGrainListener(VoidCallback listener) =>
    _grainListeners.remove(listener);

void clearRobotBakeCache() {
  for (final bake in _cache.values) {
    bake.dispose();
  }
  _cache.clear();
  _grainGeneration++;
  _grainListeners.clear();
  _grain?.dispose();
  _grain = null;
}
