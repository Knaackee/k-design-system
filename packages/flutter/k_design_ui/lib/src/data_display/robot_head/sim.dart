import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'faces.dart';
import 'types.dart';

class _Spring {
  double x = 0;
  double v = 0;

  void step(double target, double dt, double frequency, double damping) {
    final w = frequency * math.pi * 2;
    v += (w * w * (target - x) - 2 * damping * w * v) * dt;
    x += v * dt;
  }
}

const _uint32Mask = 0xffffffff;

int _uint32(int value) => value & _uint32Mask;

int _imul(int a, int b) {
  final aLow = a & 0xffff;
  final aHigh = (a >> 16) & 0xffff;
  final bLow = b & 0xffff;
  final bHigh = (b >> 16) & 0xffff;
  return _uint32(aLow * bLow + ((aHigh * bLow + aLow * bHigh) << 16));
}

double Function() _rng(double seed) {
  var a = _uint32((seed * 4294967295).floor());
  if (a == 0) a = 1;
  return () {
    a = _uint32(a + 0x6d2b79f5);
    var t = a;
    t = _imul(t ^ (t >> 15), t | 1);
    t = _uint32(t ^ _uint32(t + _imul(t ^ (t >> 7), t | 61)));
    return _uint32(t ^ (t >> 14)) / 4294967296;
  };
}

double _clamp(double value, double low, double high) =>
    math.min(high, math.max(low, value));

double _easeInOut(double progress) => progress < 0.5
    ? 4 * progress * progress * progress
    : 1 - math.pow(-2 * progress + 2, 3) / 2;

int _round(double value) => (value + 0.5).floor();

class _Jump {
  _Jump({
    required this.height,
    required this.spin,
    required this.lean,
    required this.air,
  });

  double age = 0;
  final double height;
  final double spin;
  final double lean;
  final double air;
  bool landed = false;
}

const _crouch = 0.11;

class RobotPose {
  const RobotPose({
    this.yaw = 0,
    this.pitch = 0,
    this.roll = 0,
    this.x = 0,
    this.lift = 0,
    this.sx = 1,
    this.sy = 1,
    this.antennaX = 0,
    this.antennaZ = 0,
  });

  final double yaw;
  final double pitch;
  final double roll;
  final double x;
  final double lift;
  final double sx;
  final double sy;
  final double antennaX;
  final double antennaZ;
}

class RobotSim {
  RobotSim(double seed, KRobotHeadState initialState)
    : state = initialState,
      shown = initialState,
      previous = initialState,
      face = FaceParams(
        lookX: 0,
        lookY: 0,
        blink: 0,
        time: 0,
        side: 1,
        seed: seed,
      ),
      _random = _rng(seed) {
    _nextBlink = 1 + _random() * 3;
    _nextHop = 6 + _random() * 6;
  }

  KRobotHeadState state;
  KRobotHeadState shown;
  KRobotHeadState previous;
  double switched = 10;
  double age = 0;
  double time = 0;
  double since = 0;
  RobotPose pose = const RobotPose();
  final FaceParams face;
  Offset? pointer;

  final _yaw = _Spring();
  final _pitch = _Spring();
  final _roll = _Spring();
  final _sway = _Spring();
  final _squash = _Spring();
  final _antX = _Spring();
  final _antZ = _Spring();
  double _lastRollV = 0;
  double _lastPitchV = 0;
  double _lastSwayV = 0;
  _Jump? _jump;
  final double Function() _random;
  double _lookYaw = 0;
  double _lookPitch = 0;
  double _lookX = 0;
  double _lookY = 0;
  double _nextLook = 0.6;
  double _nextBlink = 1.5;
  double _blinkAge = -1;
  double _nextHop = 8;
  double _nextSide = 4;
  double _reactUntil = -1;
  double _nextNod = 2.5;

  void setState(KRobotHeadState newState) {
    if (newState == state) return;
    state = newState;
    since = 0;
    _nextLook = 0;
    _nextHop =
        time + (newState == KRobotHeadState.happy ? 0.2 : 3 + _random() * 4);
    if (newState == KRobotHeadState.happy) hop(0.22, 1);
  }

  void poke() {
    hop(0.24, _random() < 0.5 ? 1 : -1);
    _reactUntil = time + 1.6;
  }

  void hop(double height, double spin) {
    if (_jump != null) return;
    _jump = _Jump(
      height: height,
      spin: spin,
      lean: (_random() - 0.5) * 0.3,
      air: 0.42 + height * 0.45,
    );
  }

  void update(double dt) {
    if (!(dt > 0)) return;
    final steps = math.max(1, (dt / (1 / 120)).ceil());
    for (var i = 0; i < steps; i++) {
      _step(dt / steps);
    }
  }

  void _step(double dt) {
    time += dt;
    since += dt;
    age += dt;
    switched += dt;
    final t = time;

    final stateToShow = t < _reactUntil ? KRobotHeadState.happy : state;
    if (stateToShow != shown) {
      previous = shown;
      shown = stateToShow;
      switched = 0;
    }

    var yaw = 0.0;
    var pitch = 0.0;
    var roll = 0.0;
    const sway = 0.0;
    var bob = math.sin(t * 1.9) * 0.008;
    var lookX = 0.0;
    var lookY = 0.0;
    var frequency = 1.3;
    var damping = 0.62;
    var shake = 0.0;
    final currentPointer = pointer;
    final follows =
        currentPointer != null &&
        (state == KRobotHeadState.idle ||
            state == KRobotHeadState.listening ||
            state == KRobotHeadState.happy ||
            state == KRobotHeadState.speaking);

    if (t > _nextLook) {
      _lookYaw = (_random() - 0.5) * 0.75;
      _lookPitch = (_random() - 0.5) * 0.24;
      _lookX = _clamp(_round(_lookYaw * 5).toDouble(), -2, 2);
      _lookY = _random() < 0.3
          ? -1
          : _random() < 0.2
          ? 1
          : 0;
      _nextLook = t + 1.4 + _random() * 2.6;
    }

    switch (state) {
      case KRobotHeadState.idle:
        yaw = _lookYaw;
        pitch = _lookPitch;
        roll = -_lookYaw * 0.16;
        lookX = _lookX;
        lookY = _lookY;
        if (t > _nextHop) {
          hop(
            0.15 + _random() * 0.07,
            _random() < 0.35 ? (_random() < 0.5 ? 1 : -1) : 0,
          );
          _nextHop = t + 7 + _random() * 7;
        }
      case KRobotHeadState.thinking:
        if (t > _nextSide) {
          face.side = -face.side;
          _nextSide = t + 3 + _random() * 2;
        }
        final side = face.side;
        yaw = 0.24 * side + math.sin(t * 0.9) * 0.05;
        pitch = 0.17 + math.sin(t * 1.3) * 0.03;
        roll = -0.13 * side;
        frequency = 0.9;
      case KRobotHeadState.searching:
        final phase = t * 1.6;
        yaw = math.sin(phase) * 0.55;
        pitch = -0.04 + math.sin(phase * 2) * 0.04;
        roll = math.sin(phase) * -0.06;
        lookX = _clamp(math.sin(phase + 0.4) * 3, -3, 3);
        frequency = 2.2;
        damping = 0.8;
      case KRobotHeadState.listening:
        yaw = -0.14;
        pitch = 0.02;
        roll = 0.17;
        if (t > _nextNod) {
          _pitch.v -= 0.9;
          _nextNod = t + 2 + _random() * 2.5;
        }
      case KRobotHeadState.speaking:
        yaw = math.sin(t * 0.7) * 0.12;
        pitch =
            0.03 + math.sin(t * 6.3) * 0.025 * (0.5 + 0.5 * math.sin(t * 2.1));
        roll = math.sin(t * 0.9) * 0.05;
        bob += math.sin(t * 6.3).abs() * 0.01;
        frequency = 1.8;
      case KRobotHeadState.working:
        yaw = math.sin(t * 0.8) * 0.08;
        pitch = -0.16;
        roll = math.sin(t * 0.5) * 0.04;
        bob += math.sin(t * 7).abs() * 0.012;
        if (t > _nextHop) {
          hop(0.2, _random() < 0.5 ? 1 : -1);
          _nextHop = t + 5 + _random() * 3;
        }
      case KRobotHeadState.happy:
        yaw = math.sin(t * 2.2) * 0.18;
        roll = math.sin(t * 4.4) * 0.12;
        pitch = 0.08;
        if (t > _nextHop) {
          hop(0.17, _random() < 0.34 ? (_random() < 0.5 ? 1 : -1) : 0);
          _nextHop = t + 1.05 + _random() * 0.4;
        }
      case KRobotHeadState.error:
        final cycle = (t % 2.4) / 0.7;
        shake = cycle < 1
            ? math.sin(cycle * math.pi * 7) * 0.22 * (1 - cycle)
            : 0;
        pitch = -0.06;
        roll = -0.05;
        frequency = 1.6;
      case KRobotHeadState.sleeping:
        pitch = -0.34;
        roll = 0.13;
        yaw = 0.06;
        bob = math.sin(t * 1.15) * 0.016;
        frequency = 0.55;
        damping = 0.9;
        if (t > _nextNod) {
          _pitch.v -= 0.5;
          _nextNod = t + 5 + _random() * 4;
        }
    }

    if (follows) {
      yaw = _clamp(currentPointer.dx / 260, -1, 1) * 0.55;
      pitch = -_clamp(currentPointer.dy / 260, -1, 1) * 0.32;
      roll = -yaw * 0.12 + (state == KRobotHeadState.listening ? 0.12 : 0);
      lookX = _clamp(currentPointer.dx / 120, -2.4, 2.4);
      lookY = _clamp(currentPointer.dy / 160, -1.4, 1.4);
    }

    _yaw.step(yaw, dt, frequency, damping);
    _pitch.step(pitch, dt, frequency, damping);
    _roll.step(roll, dt, frequency, damping);
    _sway.step(sway, dt, 1.2, 0.7);

    var lift = 0.0;
    var spin = 0.0;
    var lean = 0.0;
    var squashTarget = 0.0;
    final jump = _jump;
    if (jump != null) {
      jump.age += dt;
      if (jump.age < _crouch) {
        squashTarget = 0.14;
      } else {
        final airProgress = (jump.age - _crouch) / jump.air;
        if (airProgress < 1) {
          if (airProgress < 0.06 && _squash.x > 0.05) {
            _squash.v = -2.6;
            _antZ.v -= 3;
          }
          lift = 4 * jump.height * airProgress * (1 - airProgress);
          spin =
              jump.spin *
              math.pi *
              2 *
              _easeInOut(_clamp(airProgress * 1.08, 0, 1));
          lean = jump.lean * math.sin(airProgress * math.pi);
          squashTarget = airProgress < 0.5 ? -0.05 : 0;
        } else if (!jump.landed) {
          jump.landed = true;
          _squash.v += 3.2;
          _antX.v += (_random() < 0.5 ? -1 : 1) * (2.5 + _random() * 2);
          _antZ.v += 3.5;
        } else if (jump.age - _crouch - jump.air > 0.35) {
          _jump = null;
        }
      }
    }
    _squash.step(squashTarget, dt, 3.2, 0.32);

    if (t > _nextBlink) {
      _blinkAge = 0;
      _nextBlink = t + 2.2 + _random() * 3.5;
      if (_random() < 0.2) _nextBlink = t + 0.35;
    }
    var blink = 0.0;
    if (_blinkAge >= 0) {
      _blinkAge += dt;
      blink = math.sin(_clamp(_blinkAge / 0.17, 0, 1) * math.pi);
      if (_blinkAge > 0.17) _blinkAge = -1;
    }

    final rollAcceleration = (_roll.v - _lastRollV) / dt;
    final pitchAcceleration = (_pitch.v - _lastPitchV) / dt;
    final swayAcceleration = (_sway.v - _lastSwayV) / dt;
    _lastRollV = _roll.v;
    _lastPitchV = _pitch.v;
    _lastSwayV = _sway.v;
    const antennaFrequency = 2.3;
    _antX.v -= (rollAcceleration * 0.05 + swayAcceleration * 0.3) * dt * 6;
    _antZ.v -= pitchAcceleration * 0.05 * dt * 6;
    _antX.step(0, dt, antennaFrequency, 0.09);
    _antZ.step(0, dt, antennaFrequency, 0.09);
    _antX.x = _clamp(_antX.x, -0.7, 0.7);
    _antZ.x = _clamp(_antZ.x, -0.7, 0.7);

    final squash = _squash.x;
    pose = RobotPose(
      yaw: _yaw.x + spin + shake,
      pitch: _pitch.x,
      roll: _roll.x + lean,
      x: _sway.x,
      lift: lift + bob,
      sx: 1 + squash * 0.55,
      sy: 1 - squash,
      antennaX: _antX.x,
      antennaZ: _antZ.x,
    );
    face.lookX = lookX;
    face.lookY = lookY;
    face.blink = state == KRobotHeadState.sleeping ? 0 : blink;
    face.time = since;
  }
}

RobotPose restPose(KRobotHeadState state) {
  switch (state) {
    case KRobotHeadState.thinking:
      return const RobotPose(yaw: 0.24, pitch: 0.17, roll: -0.13);
    case KRobotHeadState.searching:
      return const RobotPose(yaw: 0.3, roll: -0.04);
    case KRobotHeadState.listening:
      return const RobotPose(yaw: -0.14, pitch: 0.02, roll: 0.17);
    case KRobotHeadState.working:
      return const RobotPose(pitch: -0.16);
    case KRobotHeadState.happy:
      return const RobotPose(pitch: 0.08, roll: 0.06);
    case KRobotHeadState.error:
      return const RobotPose(pitch: -0.06, roll: -0.05);
    case KRobotHeadState.sleeping:
      return const RobotPose(yaw: 0.06, pitch: -0.34, roll: 0.13);
    case KRobotHeadState.idle:
    case KRobotHeadState.speaking:
      return const RobotPose(yaw: -0.18, pitch: 0.04, roll: 0.03);
  }
}
