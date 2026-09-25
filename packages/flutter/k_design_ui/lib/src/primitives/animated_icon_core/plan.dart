part of 'core.dart';

// Closed-form 2D Procrustes with minimum-rotation tie-breaking and circular
// correspondence. Congruent whole icons share a rigid block transform.

class Similarity {
  const Similarity(this.theta, this.sigma, this.res);
  final double theta, sigma, res;
}

class Alignment extends Similarity {
  Alignment(this.ca, this.cb, this.a, this.b, Similarity s)
    : super(s.theta, s.sigma, s.res);
  final List<double> ca, cb;
  final Float64List a, b;
}

class PlanItem {
  PlanItem({
    required this.a,
    required this.aC,
    required this.bT,
    required this.bO,
    required this.ca,
    required this.cb,
    required this.theta,
    required this.lnSigma,
    required this.res,
    required this.closed,
  });
  final Float64List a, aC, bT, bO;
  final List<double> ca, cb;
  double theta, lnSigma, res;
  final bool closed;
  ({List<double> off, List<double> drift})? block;
}

class MorphPlan {
  MorphPlan(this.items, this.n);
  final List<PlanItem> items;
  final int n;
}

List<double> centroid(Float64List p) {
  final n = p.length ~/ 2;
  var cx = 0.0, cy = 0.0;
  for (var i = 0; i < n; i++) {
    cx += p[2 * i];
    cy += p[2 * i + 1];
  }
  return [cx / n, cy / n];
}

double polyLen(Float64List p) {
  var length = 0.0;
  for (var i = 1; i < p.length ~/ 2; i++) {
    length += _hypot(p[2 * i] - p[2 * i - 2], p[2 * i + 1] - p[2 * i - 1]);
  }
  return length;
}

Float64List reversePts(Float64List p) {
  final n = p.length ~/ 2, out = Float64List(p.length);
  for (var i = 0; i < n; i++) {
    out[2 * i] = p[2 * (n - 1 - i)];
    out[2 * i + 1] = p[2 * (n - 1 - i) + 1];
  }
  return out;
}

Float64List rotatePts(Float64List p, int off) {
  final n = p.length ~/ 2, out = Float64List(p.length);
  for (var i = 0; i < n; i++) {
    final j = (i + off) % n;
    out[2 * i] = p[2 * j];
    out[2 * i + 1] = p[2 * j + 1];
  }
  return out;
}

Similarity procrustes(
  Float64List a,
  Float64List b,
  List<double> ca,
  List<double> cb,
) {
  final n = a.length ~/ 2;
  var sxx = 0.0, sxy = 0.0, syx = 0.0, syy = 0.0, na = 0.0, nb = 0.0;
  for (var i = 0; i < n; i++) {
    final ax = a[2 * i] - ca[0],
        ay = a[2 * i + 1] - ca[1],
        bx = b[2 * i] - cb[0],
        by = b[2 * i + 1] - cb[1];
    sxx += ax * bx;
    syy += ay * by;
    sxy += ax * by;
    syx += ay * bx;
    na += ax * ax + ay * ay;
    nb += bx * bx + by * by;
  }
  final theta = math.atan2(sxy - syx, sxx + syy),
      num =
          math.cos(math.atan2(sxy - syx, sxx + syy)) * (sxx + syy) +
          math.sin(math.atan2(sxy - syx, sxx + syy)) * (sxy - syx);
  var sigma = na > 1e-12 ? num / na : 1.0;
  if (!(sigma > 1e-6)) sigma = 1e-6;
  final res2 = math.max(0.0, sigma * sigma * na - 2 * sigma * num + nb);
  return Similarity(theta, sigma, nb > 1e-12 ? math.sqrt(res2 / nb) : 0);
}

Alignment alignPair(
  Float64List a,
  Float64List b, [
  bool aClosed = false,
  bool bClosed = false,
]) {
  final ca = centroid(a),
      cb = centroid(b),
      varyA = aClosed && !bClosed,
      base = aClosed && !bClosed ? a : b;
  final offs = aClosed || bClosed ? base.length ~/ 2 : 1;
  var bestScore = double.infinity, best = base, sim = const Similarity(0, 1, 0);
  for (var dir = 0; dir < 2; dir++) {
    final walk = dir != 0 ? reversePts(base) : base;
    for (var off = 0; off < offs; off++) {
      final cand = off != 0 ? rotatePts(walk, off) : walk;
      final s = varyA
          ? procrustes(cand, b, ca, cb)
          : procrustes(a, cand, ca, cb);
      final score = s.res + 0.05 * s.theta.abs() / math.pi;
      if (score < bestScore) {
        bestScore = score;
        best = cand;
        sim = s;
      }
    }
  }
  return Alignment(ca, cb, varyA ? best : a, varyA ? b : best, sim);
}

void _applyGlobal(List<PlanItem> items, int n) {
  final total = items.length * n,
      ga = Float64List(2 * total),
      gb = Float64List(2 * total);
  for (var k = 0; k < items.length; k++) {
    ga.setRange(2 * n * k, 2 * n * (k + 1), items[k].a);
    gb.setRange(2 * n * k, 2 * n * (k + 1), items[k].bO);
  }
  final gca = centroid(ga), g = procrustes(ga, gb, gca, centroid(gb));
  if (g.res >= 5e-3) return;
  final cos = math.cos(-g.theta),
      sin = math.sin(-g.theta),
      rc = math.cos(g.theta),
      rs = math.sin(g.theta);
  for (final it in items) {
    var e2 = 0.0, nb = 0.0;
    for (var i = 0; i < n; i++) {
      final bx = it.bO[2 * i] - it.cb[0], by = it.bO[2 * i + 1] - it.cb[1];
      it.bT[2 * i] = (bx * cos - by * sin) / g.sigma;
      it.bT[2 * i + 1] = (bx * sin + by * cos) / g.sigma;
      final ex = g.sigma * (rc * it.aC[2 * i] - rs * it.aC[2 * i + 1]) - bx,
          ey = g.sigma * (rs * it.aC[2 * i] + rc * it.aC[2 * i + 1]) - by;
      e2 += ex * ex + ey * ey;
      nb += bx * bx + by * by;
    }
    it.theta = g.theta;
    it.lnSigma = math.log(g.sigma);
    it.res = nb > 1e-12 ? math.sqrt(e2 / nb) : 0;
    final s1 = math.exp(it.lnSigma),
        c1 = math.cos(it.theta) * s1,
        n1 = math.sin(it.theta) * s1;
    final ox = it.ca[0] - gca[0],
        oy = it.ca[1] - gca[1],
        rx =
            (it.ca[0] - gca[0]) * c1 -
            (it.ca[1] - gca[1]) * n1 -
            (it.ca[0] - gca[0]),
        ry =
            (it.ca[0] - gca[0]) * n1 +
            (it.ca[1] - gca[1]) * c1 -
            (it.ca[1] - gca[1]);
    it.block = (
      off: [ox, oy],
      drift: [it.cb[0] - it.ca[0] - rx, it.cb[1] - it.ca[1] - ry],
    );
  }
}

MorphPlan buildPlan(List<Sampled> src, List<Sampled> dst) {
  final p = src.length, q = dst.length;
  if (p == 0 || q == 0) throw ArgumentError('morphicons: icon has no subpaths');
  final a = src.map((s) => s.pts).toList(),
      b = dst.map((s) => s.pts).toList(),
      pairs = <(int, int)>[];
  if (p == q) {
    final perm = _bestPermutation(_costMatrix(a, b));
    for (var i = 0; i < p; i++) {
      pairs.add((i, perm[i]));
    }
  } else if (p < q) {
    final f = _bestSurjection(_costMatrix(b, a));
    for (var j = 0; j < q; j++) {
      pairs.add((f[j], j));
    }
  } else {
    final f = _bestSurjection(_costMatrix(a, b));
    for (var i = 0; i < p; i++) {
      pairs.add((i, f[i]));
    }
  }
  final n = a[0].length ~/ 2;
  final items = pairs.map((pair) {
    final (si, di) = pair;
    final al = alignPair(a[si], b[di], src[si].closed, dst[di].closed);
    final ac = Float64List(2 * n),
        bt = Float64List(2 * n),
        bo = Float64List(2 * n),
        cos = math.cos(-al.theta),
        sin = math.sin(-al.theta);
    for (var i = 0; i < n; i++) {
      ac[2 * i] = al.a[2 * i] - al.ca[0];
      ac[2 * i + 1] = al.a[2 * i + 1] - al.ca[1];
      final bx = al.b[2 * i] - al.cb[0], by = al.b[2 * i + 1] - al.cb[1];
      bt[2 * i] = (bx * cos - by * sin) / al.sigma;
      bt[2 * i + 1] = (bx * sin + by * cos) / al.sigma;
      bo[2 * i] = al.b[2 * i];
      bo[2 * i + 1] = al.b[2 * i + 1];
    }
    return PlanItem(
      a: al.a,
      aC: ac,
      bT: bt,
      bO: bo,
      ca: al.ca,
      cb: al.cb,
      theta: al.theta,
      lnSigma: math.log(al.sigma),
      res: al.res,
      closed: src[si].closed && dst[di].closed,
    );
  }).toList();
  if (items.length > 1) _applyGlobal(items, n);
  return MorphPlan(items, n);
}
