// Native Flutter Canvas renderer ported from robot-heads' TV renderer (MIT;
// see packages/web/ui/LICENSE.robot-heads). It intentionally keeps the source
// renderer's geometry, lighting, face transitions and visual layering together.
// Vendored-port exception (>500 lines): splitting the ordered 3D/2D draw pass
// would obscure source parity and introduce mutable cross-module render state.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'faces.dart';
import 'geometry.dart';
import 'light.dart' as lighting;
import 'sim.dart';
import 'silhouette.dart';
import 'textures.dart';
import 'types.dart';

typedef RGB = ({double r, double g, double b});

final class Palette {
  const Palette({required this.shell, required this.trim, required this.led});
  final lighting.Material shell;
  final lighting.Material trim;
  final List<num> led;
}

final class RenderOptions {
  const RenderOptions({required this.floorShadow, required this.antenna});
  final bool floorShadow, antenna;
}

final class Frame {
  const Frame({
    required this.box,
    required this.padTop,
    required this.padBottom,
    required this.padSide,
    required this.unit,
    required this.cx,
    required this.cy,
  });
  final double box, padTop, padBottom, padSide, unit, cx, cy;
}

abstract final class _HeadTravel {
  static const antenna = 0.028 + HeadGeometry.stem + HeadGeometry.ball * 1.8;
  static const knob = 0.035;
  static const ear = 0.105;
  static const glow = 0.18;
  static const hop = 0.3;
  static const overshoot = 0.13;
  static const shadow = 0.22;
  static const side = 0.12;
}

Frame frameFor(Shape shape, bool antenna, double box) {
  final top = antenna ? _HeadTravel.antenna : _HeadTravel.knob;
  final tall = 2 * shape.hy + top;
  final wide = 2 * (shape.earX + _HeadTravel.ear);
  final inner = box * 0.9;
  final unit = math.min(inner / tall, inner / wide);
  final above = (box - tall * unit) / 2;
  final centreY = above + (shape.hy + top) * unit;
  final reachUp =
      (antenna
          ? _HeadTravel.glow + _HeadTravel.hop
          : _HeadTravel.hop + _HeadTravel.overshoot) *
      unit;
  final reachDown = centreY + (shape.hy + _HeadTravel.shadow) * unit;
  final reachSide =
      box / 2 + (shape.earX + _HeadTravel.ear + _HeadTravel.side) * unit;
  final padTop = math.max(0, reachUp - above).ceilToDouble() + 1;
  final padBottom = math.max(0, reachDown - box).ceilToDouble() + 1;
  final padSide = math.max(0, reachSide - box).ceilToDouble() + 1;
  return Frame(
    box: box,
    padTop: padTop,
    padBottom: padBottom,
    padSide: padSide,
    unit: unit,
    cx: padSide + box / 2,
    cy: padTop + centreY,
  );
}

double _smooth(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

RGB _rgb(List<num> c) =>
    (r: c[0].toDouble(), g: c[1].toDouble(), b: c[2].toDouble());
RGB _mix(RGB a, RGB b, double t) => (
  r: a.r + (b.r - a.r) * t,
  g: a.g + (b.g - a.g) * t,
  b: a.b + (b.b - a.b) * t,
);
Color _color(RGB c, [double opacity = 1]) =>
    Color.fromRGBO(c.r.round(), c.g.round(), c.b.round(), opacity);
Color _rgba(int red, int green, int blue, double opacity) =>
    Color.fromRGBO(red, green, blue, opacity);

final class RobotRenderer {
  RobotRenderer({this.onInvalidate}) {
    _rendererCount++;
  }

  static int _rendererCount = 0;

  final VoidCallback? onInvalidate;
  Shape? _shape;
  HeadMeshes? _meshes;
  Grid _grid = makeGrid(cols, rows);
  Grid _previousGrid = makeGrid(cols, rows);
  Float32List _projected = Float32List(2048 * 3);
  (KRobotHeadShape, double)? _lensKey;
  Path _lensCells = Path(), _lensHighlights = Path();
  final Set<RobotBakes> _watchedBakes = {};
  void _invalidate() {
    if (!_disposed) onInvalidate?.call();
  }

  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    for (final bakes in _watchedBakes) {
      bakes.removeListener(_invalidate);
    }
    _watchedBakes.clear();
    removeGrainListener(_invalidate);
    _disposed = true;
    _rendererCount--;
    if (_rendererCount == 0) clearRobotBakeCache();
  }

  void _prepare(Shape shape) {
    if (identical(shape, _shape)) return;
    _shape = shape;
    _meshes = headMeshes(shape);
    final glass = glassOf(shape);
    _grid = makeGrid(
      (glass.hx * 2 / shape.pitch).ceil(),
      (glass.hy * 2 / shape.pitch).ceil(),
    );
    _previousGrid = makeGrid(_grid.cols, _grid.rows);
  }

  Grid _compose(RobotSim? sim, KRobotHeadState state) {
    final grid = _grid;
    grid.v.fillRange(0, grid.v.length, 0);
    if (sim == null) {
      faces[state]!(
        grid,
        FaceParams(lookX: 0, lookY: 0, blink: 0, time: 0.4, side: 1, seed: 0),
      );
      return grid;
    }
    faces[sim.shown]!(grid, sim.face);
    if (sim.switched < 0.3) {
      final old = _previousGrid;
      old.v.fillRange(0, old.v.length, 0);
      faces[sim.previous]!(old, sim.face.copyWith(time: sim.face.time + 10));
      final blend = sim.switched / 0.3;
      for (var i = 0; i < grid.v.length; i++) {
        grid.v[i] = grid.v[i] * blend + old.v[i] * (1 - blend);
      }
      if (sim.switched < 0.13) {
        final seed = (sim.time * 30).floor();
        final row = Float32List(grid.cols);
        for (var r = 0; r < grid.rows; r++) {
          final shift =
              ((math.sin(seed * 12.9 + r * 78.2) * .5 + .5) * 3).floor() - 1;
          if (shift == 0) continue;
          row.setAll(0, grid.v.sublist(r * grid.cols, (r + 1) * grid.cols));
          for (var c = 0; c < grid.cols; c++) {
            grid.v[r * grid.cols + c] =
                row[(c - shift + grid.cols) % grid.cols];
          }
        }
        for (var i = 0; i < grid.v.length; i++) {
          if (math.sin(i * 91.7 + seed * 3.1) > .93) {
            grid.v[i] = math.max(grid.v[i], .3);
          }
        }
      }
    }
    if (sim.age < .55) {
      final open = _smooth(.08, .5, sim.age) * (grid.rows / 2 + .5);
      for (var r = 0; r < grid.rows; r++) {
        final distance = (r - (grid.rows - 1) / 2).abs();
        for (var c = 0; c < grid.cols; c++) {
          final i = r * grid.cols + c;
          if (distance > open) {
            grid.v[i] = 0;
          } else if (distance > open - 1.2) {
            grid.v[i] = math.max(grid.v[i], .85 * (1 - sim.age / .55));
          }
        }
      }
    }
    return grid;
  }

  void draw(
    Canvas canvas,
    Frame frame,
    double dpr,
    RobotPose pose,
    RobotSim? sim,
    KRobotHeadState state,
    Shape shape,
    Palette palette,
    RenderOptions options,
  ) {
    if (_disposed) return;
    _prepare(shape);
    final renderBounds = Rect.fromLTWH(
      0,
      0,
      frame.box + frame.padSide * 2,
      frame.box + frame.padTop + frame.padBottom,
    );
    // Match the Web renderer's transparent backing canvas: additive LED and
    // antenna glow blend inside this bounded layer, then the finished robot is
    // composited normally over its Flutter parent.
    canvas.saveLayer(renderBounds, Paint());
    final unit = frame.unit, plate = plateOf(shape), glass = glassOf(shape);
    final shown = sim?.shown ?? state;
    final stateLight = lights[shown]!;
    var led = _rgb(stateLight.screen ?? palette.led);
    if (sim != null && sim.switched < .3) {
      led = _mix(
        _rgb(lights[sim.previous]!.screen ?? palette.led),
        led,
        sim.switched / .3,
      );
    }
    final bakes = bakesFor(shape, unit * dpr, _invalidate);
    if (!bakes.ready) _watchedBakes.add(bakes);
    final grain = grainFor(_invalidate);
    final matrix = rotation(pose.yaw, pose.pitch, pose.roll);
    final cx = frame.cx + pose.x * unit,
        rest = frame.cy,
        cy = rest - pose.lift * unit;
    final baseY = cy + shape.hy * unit;
    V3 project(double x, double y, double z) {
      final p = rotate(matrix, x, y, z);
      return (
        x: cx + p.x * unit * pose.sx,
        y: baseY + (cy + p.y * unit - baseY) * pose.sy,
        z: p.z,
      );
    }

    Float64List planeMatrix(double z, bool flip) {
      final o = project(0, 0, z),
          ex = project(flip ? -1 : 1, 0, z),
          ey = project(0, 1, z);
      return Float64List.fromList([
        ex.x - o.x,
        ex.y - o.y,
        0,
        0,
        ey.x - o.x,
        ey.y - o.y,
        0,
        0,
        0,
        0,
        1,
        0,
        o.x,
        o.y,
        0,
        1,
      ]);
    }

    void plane(double z, bool flip) => canvas.transform(planeMatrix(z, flip));

    if (options.floorShadow) _drawFloor(canvas, frame, shape, pose, unit, rest);
    final meshes = _meshes!;
    final leftZ = rotate(matrix, -shape.earX - .05, HeadGeometry.earY, 0).z;
    final rightZ = rotate(matrix, shape.earX + .05, HeadGeometry.earY, 0).z;
    final topZ = rotate(matrix, 0, -shape.hy, 0).z;
    final behind = topZ < -.012;
    void antenna() => _drawAntenna(
      canvas,
      project,
      unit,
      pose,
      palette,
      sim,
      shown,
      stateLight,
      meshes.collar,
      options.antenna,
      matrix,
    );
    if (behind) antenna();
    if (leftZ < 0) {
      _drawMesh(canvas, meshes.earL, palette.trim, matrix, project, unit);
    }
    if (rightZ < 0) {
      _drawMesh(canvas, meshes.earR, palette.trim, matrix, project, unit);
    }
    final frontZ = matrix[8], zf = shape.depth / 2;
    final facing = frontZ.abs() > .005 ? (frontZ > 0 ? 1 : -1) : 0;
    final layerBounds = renderBounds;
    final shellCoverage = Path();
    _drawMesh(
      canvas,
      meshes.body,
      palette.shell,
      matrix,
      project,
      unit,
      coverage: shellCoverage,
    );
    if (facing != 0) {
      canvas.save();
      plane(facing * zf, facing < 0);
      final dome = .17;
      Color at(double dx, double dy) {
        final w = rotate(
          matrix,
          dx * (facing < 0 ? -1 : 1),
          dy,
          facing.toDouble(),
        );
        final l = math.sqrt(w.x * w.x + w.y * w.y + w.z * w.z);
        return lighting.displayColor(
          lighting.radiance(palette.shell, w.x / l, w.y / l, w.z / l),
        );
      }

      final path = shape.path(HeadInset.plate - .002);
      canvas.drawPath(
        path,
        Paint()
          ..shader = Gradient.linear(
            Offset(0, -plate.hy),
            Offset(0, plate.hy),
            [at(0, -dome), at(0, 0), at(0, dome)],
            [0, .5, 1],
          ),
      );
      canvas.drawPath(
        path,
        Paint()
          ..shader = Gradient.linear(
            Offset(-plate.hx, 0),
            Offset(plate.hx, 0),
            [at(-dome, 0), at(0, 0), at(dome, 0)],
            [0, .5, 1],
          )
          ..color = const Color.fromRGBO(255, 255, 255, .5)
          ..blendMode = BlendMode.srcOver,
      );
      canvas.restore();
    }
    final left = math.max(0, cx - shape.hx * unit * 1.4).floor();
    final right = math
        .min(layerBounds.right, cx + shape.hx * unit * 1.4)
        .ceil();
    final top = math.max(0, cy - shape.hy * unit * 1.5).floor();
    final bottom = math
        .min(layerBounds.bottom, cy + shape.hy * unit * 1.5)
        .ceil();
    if (grain != null) {
      final transform = Float64List.fromList([
        1 / dpr,
        0,
        0,
        0,
        0,
        1 / dpr,
        0,
        0,
        0,
        0,
        1,
        0,
        cx,
        cy,
        0,
        1,
      ]);
      canvas.save();
      canvas.clipPath(shellCoverage);
      canvas.drawRect(
        Rect.fromLTRB(
          left.toDouble(),
          top.toDouble(),
          right.toDouble(),
          bottom.toDouble(),
        ),
        Paint()
          ..shader = ImageShader(
            grain,
            TileMode.repeated,
            TileMode.repeated,
            transform,
          )
          ..blendMode = BlendMode.srcOver,
      );
      canvas.restore();
    }
    if (facing > 0) {
      canvas.save();
      plane(zf, false);
      canvas.drawPath(
        shape.path(HeadInset.hole),
        Paint()..color = _rgba(6, 7, 9, 1),
      );
      canvas.save();
      canvas.clipPath(shape.path(HeadInset.glass));
      canvas.save();
      final frontOrigin = project(0, 0, zf);
      final recessOrigin = project(0, 0, zf - HeadGeometry.recess);
      final frontX = project(1, 0, zf);
      final frontY = project(0, 1, zf);
      final ax = frontX.x - frontOrigin.x;
      final ay = frontX.y - frontOrigin.y;
      final bx = frontY.x - frontOrigin.x;
      final by = frontY.y - frontOrigin.y;
      final dx = recessOrigin.x - frontOrigin.x;
      final dy = recessOrigin.y - frontOrigin.y;
      final determinant = ax * by - ay * bx;
      if (determinant.abs() > 1e-9) {
        canvas.translate(
          (dx * by - dy * bx) / determinant,
          (dy * ax - dx * ay) / determinant,
        );
      }
      _drawScreen(canvas, _compose(sim, state), shape, led, glass, unit * dpr);
      canvas.restore();
      final slide = -.05 - pose.yaw * .9 + pose.pitch * .5;
      canvas.drawRect(
        Rect.fromLTRB(-glass.hx, -glass.hy, glass.hx, glass.hy),
        Paint()
          ..shader = Gradient.linear(
            Offset(-.55 + slide, -.35),
            Offset(.15 + slide, .35),
            [
              _rgba(255, 255, 255, 0),
              _rgba(255, 255, 255, 0),
              _rgba(220, 232, 255, .075),
              _rgba(255, 255, 255, 0),
              _rgba(255, 255, 255, 0),
              _rgba(220, 232, 255, .04),
              _rgba(255, 255, 255, 0),
            ],
            [0, .36, .43, .5, .58, .61, .65],
          ),
      );
      canvas.restore();
      final frontBake = bakes.front;
      if (frontBake != null) {
        canvas.drawImageRect(
          frontBake,
          Rect.fromLTWH(
            0,
            0,
            frontBake.width.toDouble(),
            frontBake.height.toDouble(),
          ),
          Rect.fromLTRB(-plate.hx, -plate.hy, plate.hx, plate.hy),
          Paint()..filterQuality = FilterQuality.none,
        );
      }
      canvas.restore();
    } else if (facing < 0) {
      canvas.save();
      plane(-zf, true);
      final backBake = bakes.back;
      if (backBake != null) {
        canvas.drawImageRect(
          backBake,
          Rect.fromLTWH(
            0,
            0,
            backBake.width.toDouble(),
            backBake.height.toDouble(),
          ),
          Rect.fromLTRB(-plate.hx, -plate.hy, plate.hx, plate.hy),
          Paint()..filterQuality = FilterQuality.none,
        );
      }
      canvas.restore();
    }
    if (leftZ >= 0) {
      _drawMesh(canvas, meshes.earL, palette.trim, matrix, project, unit);
    }
    if (rightZ >= 0) {
      _drawMesh(canvas, meshes.earR, palette.trim, matrix, project, unit);
    }
    if (!behind) antenna();
    canvas.restore();
  }

  void _drawFloor(
    Canvas canvas,
    Frame frame,
    Shape shape,
    RobotPose pose,
    double unit,
    double rest,
  ) {
    final up = math.max(0.0, pose.lift), y = rest + (shape.hy + .11) * unit;
    final radius = unit * shape.hx * (1 - up * .9) * pose.sx;
    final alpha = .55 * math.max(0.0, 1 - up * 1.6);
    canvas.save();
    canvas.translate(frame.cx + pose.x * unit, y);
    canvas.scale(1, .16);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..shader = Gradient.radial(
          Offset.zero,
          radius,
          [
            Color.fromRGBO(0, 0, 0, alpha),
            Color.fromRGBO(0, 0, 0, alpha * .45),
            _rgba(0, 0, 0, 0),
          ],
          [0, .55, 1],
        ),
    );
    canvas.restore();
  }

  void _drawMesh(
    Canvas canvas,
    Mesh mesh,
    lighting.Material material,
    List<double> matrix,
    V3 Function(double, double, double) project,
    double unit, {
    Path? coverage,
  }) {
    final count = mesh.pos.length ~/ 3;
    if (_projected.length < mesh.pos.length) {
      _projected = Float32List(mesh.pos.length);
    }
    for (var i = 0; i < count; i++) {
      final p = project(
        mesh.pos[i * 3],
        mesh.pos[i * 3 + 1],
        mesh.pos[i * 3 + 2],
      );
      _projected[i * 3] = p.x;
      _projected[i * 3 + 1] = p.y;
      _projected[i * 3 + 2] = p.z;
    }
    final order = <({double z, int index})>[];
    for (var k = 0; k < mesh.quads.length ~/ 4; k++) {
      final nz =
          matrix[6] * mesh.normals[k * 3] +
          matrix[7] * mesh.normals[k * 3 + 1] +
          matrix[8] * mesh.normals[k * 3 + 2];
      if (nz < -.03) continue;
      var z = 0.0;
      for (var j = 0; j < 4; j++) {
        z += _projected[mesh.quads[k * 4 + j] * 3 + 2];
      }
      order.add((z: z, index: k));
    }
    order.sort((a, b) => a.z.compareTo(b.z));
    final batch = Path();
    Color? batchColor;
    final fillPaint = Paint();
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(.6, unit / 260)
      ..strokeJoin = StrokeJoin.round;
    void flush() {
      if (batchColor == null) return;
      canvas.drawPath(batch, fillPaint..color = batchColor);
      canvas.drawPath(batch, strokePaint..color = batchColor);
    }

    for (final item in order) {
      final k = item.index,
          n = rotate(
            matrix,
            mesh.normals[k * 3],
            mesh.normals[k * 3 + 1],
            mesh.normals[k * 3 + 2],
          );
      final color = lighting.shadeColor(material, n.x, n.y, n.z);
      // Preserve depth order and reuse native Path storage. Canvas records a
      // snapshot on draw; reset does not change previously submitted faces.
      if (color != batchColor) {
        flush();
        batch.reset();
        batchColor = color;
      }
      for (var j = 0; j < 4; j++) {
        final i = mesh.quads[k * 4 + j] * 3;
        if (j == 0) {
          batch.moveTo(_projected[i], _projected[i + 1]);
        } else {
          batch.lineTo(_projected[i], _projected[i + 1]);
        }
      }
      batch.close();
    }
    flush();
    coverage?.addPath(shellSilhouette(_projected, count), Offset.zero);
  }

  void _drawScreen(
    Canvas canvas,
    Grid grid,
    Shape shape,
    RGB led,
    Extents glass,
    double pixelsPerUnit,
  ) {
    final screen = screenOf(shape), pitch = shape.pitch;
    final x0 = -grid.cols * pitch / 2, y0 = -grid.rows * pitch / 2;
    final bounds = Rect.fromLTRB(-screen.hx, -screen.hy, screen.hx, screen.hy);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = Gradient.radial(
          const Offset(0, -.02),
          math.max(screen.hx, screen.hy),
          [_rgba(17, 20, 23, 1), _rgba(5, 6, 7, 1)],
        ),
    );
    final cell = pitch * .8, off = (pitch - cell) / 2;
    final lens = Color.fromRGBO(
      (60 + led.r * .12).round(),
      (64 + led.g * .12).round(),
      (70 + led.b * .12).round(),
      .34,
    );
    final lensPaint = Paint()..color = lens,
        highlight = Paint()..color = _rgba(255, 255, 255, .05);
    // The unlit LED lattice is static. Batch its disjoint rectangles into two
    // paths instead of submitting hundreds of individual draws every frame.
    final lensKey = (shape.name, pixelsPerUnit);
    if (_lensKey != lensKey) {
      _lensKey = lensKey;
      _lensCells = Path();
      _lensHighlights = Path();
      final c0 = (-(-screen.hx - x0) / pitch).floor() - 1,
          c1 = ((screen.hx - x0) / pitch).ceil() + 1;
      final r0 = (-(-screen.hy - y0) / pitch).floor() - 1,
          r1 = ((screen.hy - y0) / pitch).ceil() + 1;
      for (var r = r0; r < r1; r++) {
        for (var c = c0; c < c1; c++) {
          final rect = Rect.fromLTWH(
            x0 + c * pitch + off,
            y0 + r * pitch + off,
            cell,
            cell,
          );
          _lensCells.addRect(rect);
          _lensHighlights.addRect(
            Rect.fromLTWH(
              rect.left,
              rect.top,
              cell,
              math.max(1 / pixelsPerUnit, cell * .16),
            ),
          );
        }
      }
    }
    canvas.drawPath(_lensCells, lensPaint);
    canvas.drawPath(_lensHighlights, highlight);
    final core = _mix(led, (r: 255, g: 255, b: 255), .6);
    final bloomPath = Path(),
        corePaint = Paint()..color = _color(core),
        bleedPaint = Paint()..color = _color(led);
    for (var r = 0; r < grid.rows; r++) {
      for (var c = 0; c < grid.cols; c++) {
        final value = grid.v[r * grid.cols + c];
        if (value < .01) continue;
        final x = x0 + c * pitch, y = y0 + r * pitch;
        canvas.drawRect(
          Rect.fromLTWH(
            x + off * .4,
            y + off * .4,
            pitch - off * .8,
            pitch - off * .8,
          ),
          bleedPaint..color = _color(led, math.min(1, value * .4)),
        );
        final rect = Rect.fromLTWH(x + off, y + off, cell, cell);
        canvas.drawRect(
          rect,
          corePaint..color = _color(core, math.min(1, value)),
        );
        bloomPath.addRect(rect);
      }
    }
    canvas.saveLayer(
      bounds.inflate(pitch * 2),
      Paint()
        ..blendMode = BlendMode.plus
        ..imageFilter = ImageFilter.blur(
          sigmaX: pitch * .65,
          sigmaY: pitch * .65,
        ),
    );
    canvas.drawPath(bloomPath, Paint()..color = _color(led, .7));
    canvas.restore();
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = Gradient.radial(
          Offset.zero,
          math.sqrt(screen.hx * screen.hx + screen.hy * screen.hy),
          [_rgba(0, 0, 0, 0), _rgba(0, 0, 0, .5)],
        ),
    );
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = Gradient.linear(
          Offset(0, -screen.hy),
          Offset(0, screen.hy),
          [
            _rgba(190, 210, 255, .09),
            _rgba(190, 210, 255, .015),
            _rgba(190, 210, 255, 0),
          ],
          [0, .42, .43],
        ),
    );
  }

  void _drawAntenna(
    Canvas canvas,
    V3 Function(double, double, double) project,
    double unit,
    RobotPose pose,
    Palette palette,
    RobotSim? sim,
    KRobotHeadState shown,
    StateLight current,
    Mesh collar,
    bool stem,
    List<double> matrix,
  ) {
    _drawMesh(canvas, collar, palette.trim, matrix, project, unit);
    if (!stem) return;
    final top = -_shape!.hy - .028, length = HeadGeometry.stem;
    final dir = (
      x: math.sin(pose.antennaX),
      y: -math.cos(pose.antennaX) * math.cos(pose.antennaZ),
      z: math.sin(pose.antennaZ),
    );
    final base = project(0, top, 0),
        ctrl = project(0, top - length * .55, 0),
        tip = project(dir.x * length, top + dir.y * length, dir.z * length);
    final path = Path()
      ..moveTo(base.x, base.y)
      ..quadraticBezierTo(ctrl.x, ctrl.y, tip.x, tip.y);
    canvas.drawPath(
      path,
      Paint()
        ..color = _rgba(74, 82, 96, 1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * .02
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _rgba(154, 163, 177, 1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * .009
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _rgba(255, 255, 255, .75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit * .004
        ..strokeCap = StrokeCap.round,
    );
    final centre = project(
      dir.x * (length + HeadGeometry.ball * .8),
      top + dir.y * (length + HeadGeometry.ball * .8),
      dir.z * (length + HeadGeometry.ball * .8),
    );
    var colour = _rgb(current.ball),
        level = current.pulse(sim?.face.time ?? .3);
    if (shown == KRobotHeadState.speaking && sim?.face.audioLevel != null) {
      level = .25 + .75 * sim!.face.audioLevel!;
    }
    if (sim != null && sim.switched < .3) {
      final old = lights[sim.previous]!, k = sim.switched / .3;
      colour = _mix(_rgb(old.ball), colour, k);
      level = old.pulse(sim.face.time + 10) * (1 - k) + level * k;
    }
    if (sim != null && sim.age < .55) level *= _smooth(.1, .5, sim.age);
    final radius = HeadGeometry.ball * unit * pose.sx,
        frost = (r: 168.0, g: 174.0, b: 186.0),
        white = (r: 255.0, g: 255.0, b: 255.0);
    final lit = _mix(frost, _mix(colour, white, .35), level),
        glassTint = _mix((r: 150, g: 158, b: 172), colour, .5),
        shoulder = _mix(lit, glassTint, .48),
        edge = _mix(
          (r: 70, g: 76, b: 88),
          _mix(colour, (r: 90, g: 96, b: 108), .5),
          level * .55,
        );
    if (level > .01) {
      canvas.saveLayer(
        Rect.fromCircle(
          center: Offset(centre.x, centre.y),
          radius: radius * 4.2,
        ),
        Paint()..blendMode = BlendMode.plus,
      );
      canvas.drawCircle(
        Offset(centre.x, centre.y),
        radius * 4.2,
        Paint()
          ..shader = Gradient.radial(
            Offset(centre.x, centre.y),
            radius * 4.2,
            [
              _color(colour, .5 * level),
              _color(colour, .14 * level),
              _color(colour, 0),
            ],
            [.14, .35, 1],
          ),
      );
      canvas.restore();
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centre.x, centre.y + radius * .9),
        width: radius * 1.4,
        height: radius * .45,
      ),
      Paint()
        ..shader = Gradient.radial(
          Offset(centre.x, centre.y + radius * .9),
          radius * .7,
          [_rgba(20, 24, 32, .28), _rgba(20, 24, 32, 0)],
        ),
    );
    canvas.drawCircle(
      Offset(centre.x, centre.y),
      radius,
      Paint()
        ..shader = Gradient.radial(
          Offset(centre.x - radius * .18, centre.y - radius * .22),
          radius,
          [
            _color(_mix(lit, white, .6 + level * .3)),
            _color(lit),
            _color(shoulder),
            _color(edge),
          ],
          [0, .38, .78, 1],
        ),
    );
    canvas.drawCircle(
      Offset(centre.x, centre.y),
      radius,
      Paint()
        ..color = _rgba(28, 32, 42, .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.75, radius * .07),
    );
    canvas.drawCircle(
      Offset(centre.x - radius * .38, centre.y - radius * .42),
      radius * .38,
      Paint()
        ..shader = Gradient.radial(
          Offset(centre.x - radius * .38, centre.y - radius * .42),
          radius * .38,
          [_rgba(255, 255, 255, .95), _rgba(255, 255, 255, 0)],
        ),
    );
  }
}
