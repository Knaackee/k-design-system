import 'dart:math' as math;
import 'dart:typed_data';

import 'types.dart';

const cols = 22;
const rows = 14;

class FaceParams {
  FaceParams({
    required this.lookX,
    required this.lookY,
    required this.blink,
    required this.time,
    required this.side,
    required this.seed,
    this.audioLevel,
    this.audioBands,
  });

  double lookX;
  double lookY;
  double blink;
  double time;
  double side;
  final double seed;
  double? audioLevel;
  List<double>? audioBands;

  FaceParams copyWith({
    double? lookX,
    double? lookY,
    double? blink,
    double? time,
    double? side,
    double? seed,
    double? audioLevel,
    List<double>? audioBands,
  }) => FaceParams(
    lookX: lookX ?? this.lookX,
    lookY: lookY ?? this.lookY,
    blink: blink ?? this.blink,
    time: time ?? this.time,
    side: side ?? this.side,
    seed: seed ?? this.seed,
    audioLevel: audioLevel ?? this.audioLevel,
    audioBands: audioBands ?? this.audioBands,
  );
}

class Grid {
  Grid({
    required this.v,
    required this.cols,
    required this.rows,
    required this.ox,
    required this.oy,
  });

  final Float32List v;
  final int cols;
  final int rows;
  final int ox;
  final int oy;
}

Grid makeGrid(int requestedCols, int requestedRows) {
  final gridCols =
      cols + 2 * math.max(0, ((requestedCols - cols) / 2).ceil()).toInt();
  final gridRows =
      rows + 2 * math.max(0, ((requestedRows - rows) / 2).ceil()).toInt();
  return Grid(
    v: Float32List(gridCols * gridRows),
    cols: gridCols,
    rows: gridRows,
    ox: (gridCols - cols) ~/ 2,
    oy: (gridRows - rows) ~/ 2,
  );
}

void _put(Grid grid, int column, int row, double value) {
  final x = column + grid.ox;
  final y = row + grid.oy;
  if (x < 0 || y < 0 || x >= grid.cols || y >= grid.rows) return;
  final index = y * grid.cols + x;
  if (value > grid.v[index]) grid.v[index] = value;
}

void _rect(
  Grid grid,
  int column,
  int row,
  int width,
  int height,
  double value,
) {
  for (var y = row; y < row + height; y++) {
    for (var x = column; x < column + width; x++) {
      _put(grid, x, y, value);
    }
  }
}

void _sprite(
  Grid grid,
  int column,
  int row,
  List<String> spriteRows,
  double value,
) {
  for (var y = 0; y < spriteRows.length; y++) {
    final spriteRow = spriteRows[y];
    for (var x = 0; x < spriteRow.length; x++) {
      if (spriteRow[x] == '#') {
        _put(grid, column + x, row + y, value);
      } else if (spriteRow[x] == '+') {
        _put(grid, column + x, row + y, value * 0.5);
      }
    }
  }
}

const _eyeLeft = 6;
const _eyeRight = 13;
const _eyeTop = 5;

int _round(double value) => (value + 0.5).floor();

void _eyes(
  Grid grid,
  FaceParams face, [
  int height = 4,
  double value = 1,
  int dy = 0,
  double lid = 0,
]) {
  final dx = _round(face.lookX);
  final ly = _round(face.lookY) + dy;
  final open = math.max(1, _round(height - (height - 1) * face.blink));
  final top =
      _eyeTop + ((4 - height) / 2).floor() + ly + ((height - open) / 2).floor();
  for (final column in [_eyeLeft, _eyeRight]) {
    if (lid > 0 && open > 1) {
      _rect(grid, column + dx, top, 3, 1, value * (1 - lid));
      _rect(grid, column + dx, top + 1, 3, open - 1, value);
    } else {
      _rect(grid, column + dx, top, 3, open, value);
    }
  }
}

double _noise(double x) =>
    0.5 +
    0.25 * math.sin(x * 1.7) +
    0.15 * math.sin(x * 3.1 + 1.3) +
    0.1 * math.sin(x * 5.3 + 4.1);

const _caret = ['..#..', '.#.#.', '#...#'];
const _cross = ['#...#', '.#.#.', '..#..', '.#.#.', '#...#'];
const _zBig = ['####', '..#.', '.#..', '####'];
const _zSmall = ['###', '.#.', '###'];

typedef FacePainter = void Function(Grid grid, FaceParams face);

void _idle(Grid grid, FaceParams face) => _eyes(grid, face);

void _thinking(Grid grid, FaceParams face) {
  _eyes(
    grid,
    face.copyWith(lookX: face.lookX + face.side * 1.4, lookY: face.lookY - 1.2),
    3,
    1,
    0,
    0.45,
  );
  for (var i = 0; i < 3; i++) {
    final p = (face.time * 1.6 - i * 0.22).remainder(1);
    final pulse = p < 0.35 ? math.sin((p / 0.35) * math.pi) : 0.0;
    _rect(
      grid,
      6 + i * 4,
      11 - (pulse > 0.5 ? 1 : 0),
      2,
      2,
      0.28 + 0.72 * pulse,
    );
  }
}

void _searching(Grid grid, FaceParams face) {
  _eyes(grid, face);
  final first = -grid.ox;
  final last = cols - 1 + grid.ox;
  final sweep =
      first + (math.sin(face.time * 1.6 + 0.4) * 0.5 + 0.5) * (last - first);
  final direction = math.cos(face.time * 1.6 + 0.4) > 0 ? -1 : 1;
  for (var k = 0; k < 5; k++) {
    final column = _round(sweep + direction * k);
    final value = 0.32 * (1 - k / 5);
    for (var row = -grid.oy; row < rows + grid.oy; row++) {
      _put(grid, column, row, value);
    }
  }
}

void _listening(Grid grid, FaceParams face) {
  _eyes(grid, face, 4, 1, -1);
  for (var i = 0; i < 12; i++) {
    final centre = 1 - (i - 5.5).abs() / 7;
    final bands = face.audioBands;
    final band = bands != null && bands.isNotEmpty
        ? bands[math.min(bands.length - 1, ((i / 12) * bands.length).floor())]
        : face.audioLevel;
    final level = face.audioLevel == null
        ? _noise(face.time * 7 + i * 1.9 + face.seed * 10) * centre
        : (band ?? 0) * centre;
    final height = math.max(1, _round(level * 4));
    for (var k = 0; k < height; k++) {
      _put(grid, 5 + i, 12 - k, 0.75 - k * 0.12);
    }
  }
}

void _speaking(Grid grid, FaceParams face) {
  _eyes(grid, face, 4, 1, -1);
  final envelope = math.max(
    0,
    math.sin(face.time * 2.1) * 0.5 + math.sin(face.time * 3.7 + 1) * 0.5,
  );
  for (var i = 0; i < 8; i++) {
    final centre = 1 - (i - 3.5).abs() / 5;
    final amplitude = face.audioLevel == null
        ? _noise(face.time * 11 + i * 0.9) * centre * (0.35 + envelope)
        : face.audioLevel! * centre;
    final height = amplitude > 0.55
        ? 3
        : amplitude > 0.28
        ? 2
        : 1;
    _rect(grid, 7 + i, height == 3 ? 10 : 11, 1, height, 1);
  }
}

void _working(Grid grid, FaceParams face) {
  _eyes(grid, face.copyWith(lookY: face.lookY + 1), 2);
  final progress = (face.time / 2.6) % 1;
  final fill = _round(progress * 12);
  for (var i = 0; i < 12; i++) {
    _put(grid, 5 + i, 11, i < fill ? 0.95 : 0.16);
  }
  _put(grid, 4, 11, 0.4);
  _put(grid, 17, 11, 0.4);
}

void _happy(Grid grid, FaceParams face) {
  final hop = _round(math.max(0, math.sin(face.time * 5.6)) * -1);
  _sprite(grid, _eyeLeft - 1, _eyeTop + hop, _caret, 1);
  _sprite(grid, _eyeRight - 1, _eyeTop + hop, _caret, 1);
  _sprite(grid, 7, 10 + hop, ['#......#', '.######.'], 0.9);
}

void _error(Grid grid, FaceParams face) {
  final on = math.sin(face.time * 7) > -0.6 ? 1.0 : 0.55;
  _sprite(grid, _eyeLeft - 1, 4, _cross, on);
  _sprite(grid, _eyeRight - 1, 4, _cross, on);
  for (var i = 0; i < 8; i++) {
    _put(grid, 7 + i, i.isOdd ? 11 : 12, 0.8);
  }
}

void _sleeping(Grid grid, FaceParams face) {
  for (final column in [_eyeLeft, _eyeRight]) {
    _put(grid, column - 1, 7, 0.32);
    _rect(grid, column, 8, 3, 1, 0.42);
    _put(grid, column + 3, 7, 0.32);
  }
  for (final entry in [(0.0, true), (1.1, false)]) {
    final progress = ((face.time + entry.$1) / 2.2) % 1;
    final value = math.sin(progress * math.pi) * 0.6;
    final y = _round(5 - progress * 5);
    final x = 16 + _round(progress * 2);
    _sprite(grid, x, y, entry.$2 ? _zBig : _zSmall, value);
  }
}

final Map<KRobotHeadState, FacePainter> faces = {
  KRobotHeadState.idle: _idle,
  KRobotHeadState.thinking: _thinking,
  KRobotHeadState.searching: _searching,
  KRobotHeadState.listening: _listening,
  KRobotHeadState.speaking: _speaking,
  KRobotHeadState.working: _working,
  KRobotHeadState.happy: _happy,
  KRobotHeadState.error: _error,
  KRobotHeadState.sleeping: _sleeping,
};

class StateLight {
  const StateLight({
    required this.screen,
    required this.ball,
    required this.pulse,
  });

  final List<int>? screen;
  final List<int> ball;
  final double Function(double time) pulse;
}

double Function(double) _steady(double value) =>
    (_) => value;

final Map<KRobotHeadState, StateLight> lights = {
  KRobotHeadState.idle: StateLight(
    screen: null,
    ball: const [255, 250, 240],
    pulse: (time) => 0.75 + 0.1 * math.sin(time * 1.4),
  ),
  KRobotHeadState.thinking: StateLight(
    screen: null,
    ball: const [255, 184, 64],
    pulse: (time) => 0.45 + 0.55 * (0.5 + 0.5 * math.sin(time * 4.2)),
  ),
  KRobotHeadState.searching: StateLight(
    screen: null,
    ball: const [90, 220, 255],
    pulse: (time) => (time * 2.4) % 1 < 0.18 ? 1 : 0.25,
  ),
  KRobotHeadState.listening: StateLight(
    screen: null,
    ball: const [96, 255, 150],
    pulse: _steady(0.95),
  ),
  KRobotHeadState.speaking: StateLight(
    screen: null,
    ball: const [255, 250, 240],
    pulse: (time) => 0.55 + 0.45 * _noise(time * 11),
  ),
  KRobotHeadState.working: StateLight(
    screen: null,
    ball: const [110, 160, 255],
    pulse: (time) => (time * 1.7) % 1 < 0.5 ? 1 : 0.35,
  ),
  KRobotHeadState.happy: StateLight(
    screen: null,
    ball: const [255, 130, 200],
    pulse: (time) => 0.8 + 0.2 * math.sin(time * 8),
  ),
  KRobotHeadState.error: StateLight(
    screen: const [255, 70, 64],
    ball: const [255, 60, 50],
    pulse: (time) => (time * 3) % 1 < 0.5 ? 1 : 0.15,
  ),
  KRobotHeadState.sleeping: StateLight(
    screen: null,
    ball: const [255, 250, 240],
    pulse: _steady(0),
  ),
};
