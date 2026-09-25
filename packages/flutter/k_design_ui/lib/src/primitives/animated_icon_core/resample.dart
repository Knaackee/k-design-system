part of 'core.dart';

// Eight-point Gauss-Legendre arc length, safeguarded Newton inversion and
// largest-remainder allocation preserve corners in the 64-point clouds.

const _gx = [
  0.18343464249564978,
  0.525532409916329,
  0.7966664774136267,
  0.9602898564975363,
];
const _gw = [
  0.362683783378362,
  0.31370664587788727,
  0.22238103445337448,
  0.10122853629037626,
];
const cornerThreshold = math.pi / 8;
double _speed(Float64List p, int k, double t) {
  final i = 6 * k, u = 1 - t, c0 = 3 * u * u, c1 = 6 * u * t, c2 = 3 * t * t;
  return _hypot(
    c0 * (p[i + 2] - p[i]) +
        c1 * (p[i + 4] - p[i + 2]) +
        c2 * (p[i + 6] - p[i + 4]),
    c0 * (p[i + 3] - p[i + 1]) +
        c1 * (p[i + 5] - p[i + 3]) +
        c2 * (p[i + 7] - p[i + 5]),
  );
}

double _segLen(Float64List p, int k, [double t1 = 1]) {
  final half = t1 / 2;
  var s = 0.0;
  for (var j = 0; j < 4; j++) {
    s +=
        _gw[j] *
        (_speed(p, k, half + half * _gx[j]) +
            _speed(p, k, half - half * _gx[j]));
  }
  return s * half;
}

void _point(Float64List p, int k, double t, Float64List out, int o) {
  final i = 6 * k,
      u = 1 - t,
      b0 = u * u * u,
      b1 = 3 * u * u * t,
      b2 = 3 * u * t * t,
      b3 = t * t * t;
  out[o] = b0 * p[i] + b1 * p[i + 2] + b2 * p[i + 4] + b3 * p[i + 6];
  out[o + 1] = b0 * p[i + 1] + b1 * p[i + 3] + b2 * p[i + 5] + b3 * p[i + 7];
}

List<double>? _tangent(Float64List p, int k, bool atEnd) {
  final i = 6 * k, b = atEnd ? 6 * k + 6 : 6 * k, s = atEnd ? -1 : 1;
  for (final j in atEnd ? [4, 2, 0] : [2, 4, 6]) {
    final dx = s * (p[i + j] - p[b]), dy = s * (p[i + j + 1] - p[b + 1]);
    if (dx * dx + dy * dy > 1e-18) return [dx, dy];
  }
  return null;
}

List<int> detectCorners(CubicPath path, [double threshold = cornerThreshold]) {
  final p = path.pts, m = (p.length ~/ 2 - 1) ~/ 3, active = <int>[];
  for (var k = 0; k < m; k++) {
    if (_segLen(p, k) > 1e-9) active.add(k);
  }
  if (active.isEmpty) return [];
  final corners = <int>{};
  void test(int a, int b) {
    final u = _tangent(p, a, true), v = _tangent(p, b, false);
    if (u == null || v == null) return;
    final ang = math
        .atan2(u[0] * v[1] - u[1] * v[0], u[0] * v[0] + u[1] * v[1])
        .abs();
    if (ang > threshold) corners.add(b);
  }

  for (var j = 0; j + 1 < active.length; j++) {
    test(active[j], active[j + 1]);
  }
  if (path.closed && active.length > 1) test(active.last, active.first);
  return corners.toList()..sort();
}

double arcLength(CubicPath path) {
  var length = 0.0;
  for (var k = 0; k < (path.pts.length ~/ 2 - 1) ~/ 3; k++) {
    length += _segLen(path.pts, k);
  }
  return length;
}

double _invert(Float64List p, int k, double s, double ls) {
  if (s <= 0) return 0;
  if (s >= ls) return 1;
  var lo = 0.0, hi = 1.0, t = s / ls;
  for (var it = 0; it < 12; it++) {
    final f = _segLen(p, k, t) - s;
    if (f.abs() < 1e-10 * ls + 1e-14) break;
    if (f > 0) {
      hi = t;
    } else {
      lo = t;
    }
    final sp = _speed(p, k, t);
    var nt = sp > 1e-12 ? t - f / sp : (lo + hi) / 2;
    if (!(nt > lo && nt < hi)) nt = (lo + hi) / 2;
    t = nt;
  }
  return t;
}

Float64List resamplePath(
  CubicPath path, [
  int count = 64,
  double threshold = cornerThreshold,
]) {
  final p = path.pts,
      m = (p.length ~/ 2 - 1) ~/ 3,
      out = Float64List(2 * count);
  Float64List fill() {
    for (var i = 0; i < count; i++) {
      out[2 * i] = p[0];
      out[2 * i + 1] = p[1];
    }
    return out;
  }

  if (m < 1) return fill();
  final lens = List<double>.filled(m, 0);
  var length = 0.0;
  for (var k = 0; k < m; k++) {
    lens[k] = _segLen(p, k);
    length += lens[k];
  }
  if (length < 1e-12) return fill();
  final cs = detectCorners(path, threshold);
  final anchors = path.closed
      ? (cs.isNotEmpty ? cs : [0])
      : (<int>{0, ...cs, m}.toList()..sort());
  final runs = <(int, int)>[];
  if (path.closed) {
    for (var j = 0; j < anchors.length; j++) {
      runs.add((
        anchors[j],
        j + 1 < anchors.length ? anchors[j + 1] : anchors[0] + m,
      ));
    }
  } else {
    for (var j = 0; j + 1 < anchors.length; j++) {
      runs.add((anchors[j], anchors[j + 1]));
    }
  }
  final rl = runs.map((r) {
    var s = 0.0;
    for (var k = r.$1; k < r.$2; k++) {
      s += lens[k % m];
    }
    return s;
  }).toList();
  final intervals = path.closed ? count : count - 1;
  if (runs.length > intervals) {
    throw ArgumentError('morphicons: N=$count too small (${runs.length} runs)');
  }
  var total = rl.fold(0.0, (a, b) => a + b);
  if (total == 0) total = 1;
  final ideal = rl.map((l) => intervals * l / total).toList(),
      counts = rl
          .map((l) => math.max(1, (intervals * l / total).floor()))
          .toList();
  var remainder = intervals - counts.fold(0, (a, b) => a + b);
  if (remainder > 0) {
    final order = List.generate(
      ideal.length,
      (idx) => (_jsRound((ideal[idx] - ideal[idx].floor()) * 1e9), idx),
    );
    order.sort((a, b) {
      final diff = b.$1.compareTo(a.$1);
      return diff != 0 ? diff : a.$2.compareTo(b.$2);
    });
    for (var j = 0; j < remainder; j++) {
      counts[order[j % counts.length].$2]++;
    }
  }
  while (remainder < 0) {
    var bi = 0;
    for (var idx = 1; idx < counts.length; idx++) {
      if (counts[idx] > counts[bi]) bi = idx;
    }
    if (counts[bi] <= 1) break;
    counts[bi]--;
    remainder++;
  }
  var w = 0;
  for (var r = 0; r < runs.length; r++) {
    final (k0, k1) = runs[r];
    final cnt = counts[r], lr = rl[r], vi = 6 * (k0 % m);
    out[2 * w] = p[vi];
    out[2 * w + 1] = p[vi + 1];
    w++;
    var seg = k0, acc = 0.0;
    for (var j = 1; j < cnt; j++) {
      final target = lr * j / cnt;
      while (seg < k1 - 1 && acc + lens[seg % m] < target) {
        acc += lens[seg % m];
        seg++;
      }
      final k = seg % m,
          ls = lens[seg % m],
          t = ls > 1e-12 ? _invert(p, k, target - acc, ls) : 0.0;
      _point(p, k, t, out, 2 * w);
      w++;
    }
  }
  if (!path.closed) {
    final vi = 6 * m;
    out[2 * w] = p[vi];
    out[2 * w + 1] = p[vi + 1];
  }
  return out;
}

List<Sampled> resampleIcon(Object input, [int count = 64]) => iconToCubics(
  input,
).map((p) => Sampled(resamplePath(p, count), p.closed)).toList();
