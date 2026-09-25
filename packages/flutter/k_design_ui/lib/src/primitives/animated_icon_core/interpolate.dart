part of 'core.dart';

// Polar interpolation blends residuals in the aligned frame; rotation is
// linear and scale logarithmic. Springs may extrapolate beyond progress 1.

List<Float64List> allocOutputs(MorphPlan plan) =>
    plan.items.map((_) => Float64List(2 * plan.n)).toList();
void interpPolar(MorphPlan plan, double t, List<Float64List> out) {
  for (var k = 0; k < plan.items.length; k++) {
    final it = plan.items[k],
        o = out[k],
        n = plan.n,
        s = math.exp(plan.items[k].lnSigma * t),
        ang = plan.items[k].theta * t;
    final cos = math.cos(ang) * s, sin = math.sin(ang) * s;
    double cx, cy;
    final block = it.block;
    if (block != null) {
      final ox = block.off[0],
          oy = block.off[1],
          dx = block.drift[0],
          dy = block.drift[1];
      cx = it.ca[0] + dx * t + (ox * cos - oy * sin - ox);
      cy = it.ca[1] + dy * t + (ox * sin + oy * cos - oy);
    } else {
      cx = it.ca[0] + (it.cb[0] - it.ca[0]) * t;
      cy = it.ca[1] + (it.cb[1] - it.ca[1]) * t;
    }
    for (var i = 0; i < n; i++) {
      final px = it.aC[2 * i] + (it.bT[2 * i] - it.aC[2 * i]) * t,
          py = it.aC[2 * i + 1] + (it.bT[2 * i + 1] - it.aC[2 * i + 1]) * t;
      o[2 * i] = cx + px * cos - py * sin;
      o[2 * i + 1] = cy + px * sin + py * cos;
    }
  }
}

void interpLinear(MorphPlan plan, double t, List<Float64List> out) {
  for (var k = 0; k < plan.items.length; k++) {
    final it = plan.items[k], o = out[k];
    for (var i = 0; i < plan.n; i++) {
      o[2 * i] = it.a[2 * i] + (it.bO[2 * i] - it.a[2 * i]) * t;
      o[2 * i + 1] = it.a[2 * i + 1] + (it.bO[2 * i + 1] - it.a[2 * i + 1]) * t;
    }
  }
}

String _fmt(double v, double precision) {
  final rounded = _jsRound(v * precision) / precision;
  return rounded == rounded.truncateToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}

String serialize(List<Float64List> subs, [List<bool>? closed]) {
  final d = StringBuffer();
  for (var k = 0; k < subs.length; k++) {
    final o = subs[k];
    d.write('M${_fmt(o[0], 100)} ${_fmt(o[1], 100)}');
    for (var i = 1; i < o.length ~/ 2; i++) {
      d.write('L${_fmt(o[2 * i], 100)} ${_fmt(o[2 * i + 1], 100)}');
    }
    if (closed != null && closed[k]) d.write('Z');
  }
  return d.toString();
}

String cubicsToPathD(List<CubicPath> paths) {
  final d = StringBuffer();
  for (final path in paths) {
    final p = path.pts;
    d.write('M${_fmt(p[0], 1e4)} ${_fmt(p[1], 1e4)}');
    for (var i = 2; i < p.length; i += 6) {
      d.write(
        'C${_fmt(p[i], 1e4)} ${_fmt(p[i + 1], 1e4)} ${_fmt(p[i + 2], 1e4)} ${_fmt(p[i + 3], 1e4)} ${_fmt(p[i + 4], 1e4)} ${_fmt(p[i + 5], 1e4)}',
      );
    }
    if (path.closed) d.write('Z');
  }
  return d.toString();
}

class MorphSpring {
  double x = 1, v = 0, k = 250, c = 24;
  void config(double stiffness, double damping) {
    k = stiffness;
    c = damping;
  }

  void start() {
    x = 0;
    v = v.clamp(-14, 14);
  }

  bool step(double dt) {
    const h = 1 / 240;
    final steps = math.max(1, math.min(16, (dt / h).ceil())),
        s = dt / math.max(1, math.min(16, (dt / h).ceil()));
    for (var i = 0; i < steps; i++) {
      final a = k * (1 - x) - c * v;
      v += a * s;
      x += v * s;
    }
    return (1 - x).abs() < 0.001 && v.abs() < 0.02;
  }
}

const springPresets = <String, ({double k, double c})>{
  'smooth': (k: 170, c: 26),
  'snappy': (k: 420, c: 30),
  'bouncy': (k: 300, c: 14),
};
