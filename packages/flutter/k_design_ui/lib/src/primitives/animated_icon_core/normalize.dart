part of 'core.dart';

// SVG primitives become cubic chains. Arcs use SVG F.6 endpoint-to-center
// conversion and slices no larger than 90 degrees.

final _kappa = (4 / 3) * math.tan(math.pi / 8);

class _Builder {
  _Builder(double x, double y) : cx = x, cy = y, pts = [x, y];
  final List<double> pts;
  double cx, cy;
  void cubic(double x1, double y1, double x2, double y2, double x, double y) {
    pts.addAll([x1, y1, x2, y2, x, y]);
    cx = x;
    cy = y;
  }

  void line(double x, double y) {
    if ((x - cx).abs() < 1e-12 && (y - cy).abs() < 1e-12) return;
    cubic(
      cx + (x - cx) / 3,
      cy + (y - cy) / 3,
      cx + 2 * (x - cx) / 3,
      cy + 2 * (y - cy) / 3,
      x,
      y,
    );
  }

  void quad(double x1, double y1, double x, double y) {
    cubic(
      cx + 2 / 3 * (x1 - cx),
      cy + 2 / 3 * (y1 - cy),
      x + 2 / 3 * (x1 - x),
      y + 2 / 3 * (y1 - y),
      x,
      y,
    );
  }

  void arc(
    double rx0,
    double ry0,
    double rot,
    double large,
    double sweep,
    double x,
    double y,
  ) {
    final x1 = cx, y1 = cy;
    if ((x - x1).abs() < 1e-12 && (y - y1).abs() < 1e-12) return;
    var rx = rx0.abs(), ry = ry0.abs();
    if (rx < 1e-12 || ry < 1e-12) {
      line(x, y);
      return;
    }
    final phi = rot * math.pi / 180, cosP = math.cos(phi), sinP = math.sin(phi);
    final hx = (x1 - x) / 2, hy = (y1 - y) / 2;
    final xp = cosP * hx + sinP * hy, yp = -sinP * hx + cosP * hy;
    final lam = xp * xp / (rx * rx) + yp * yp / (ry * ry);
    if (lam > 1) {
      final s = math.sqrt(lam);
      rx *= s;
      ry *= s;
    }
    final rx2 = rx * rx, ry2 = ry * ry, xp2 = xp * xp, yp2 = yp * yp;
    final rad = math.max(
      0.0,
      (rx2 * ry2 - rx2 * yp2 - ry2 * xp2) / (rx2 * yp2 + ry2 * xp2),
    );
    final co = (large == sweep ? -1 : 1) * math.sqrt(rad);
    final cxp = co * rx * yp / ry, cyp = -co * ry * xp / rx;
    final ccx = cosP * cxp - sinP * cyp + (x1 + x) / 2,
        ccy = sinP * cxp + cosP * cyp + (y1 + y) / 2;
    final th1 = math.atan2((yp - cyp) / ry, (xp - cxp) / rx);
    var dth = math.atan2((-yp - cyp) / ry, (-xp - cxp) / rx) - th1;
    if (sweep == 0 && dth > 0) {
      dth -= 2 * math.pi;
    } else if (sweep == 1 && dth < 0) {
      dth += 2 * math.pi;
    }
    final slices = math.max(1, (dth.abs() / (math.pi / 2) - 1e-9).ceil());
    final delta = dth / slices, alpha = 4 / 3 * math.tan(delta / 4);
    double ex(double t) =>
        ccx + rx * math.cos(t) * cosP - ry * math.sin(t) * sinP;
    double ey(double t) =>
        ccy + rx * math.cos(t) * sinP + ry * math.sin(t) * cosP;
    double dx(double t) => -rx * math.sin(t) * cosP - ry * math.cos(t) * sinP;
    double dy(double t) => -rx * math.sin(t) * sinP + ry * math.cos(t) * cosP;
    var t0 = th1, p0x = x1, p0y = y1;
    for (var s = 1; s <= slices; s++) {
      final t1 = th1 + delta * s,
          p1x = s == slices ? x : ex(th1 + delta * s),
          p1y = s == slices ? y : ey(th1 + delta * s);
      cubic(
        p0x + alpha * dx(t0),
        p0y + alpha * dy(t0),
        p1x - alpha * dx(t1),
        p1y - alpha * dy(t1),
        p1x,
        p1y,
      );
      t0 = t1;
      p0x = p1x;
      p0y = p1y;
    }
  }

  CubicPath? finish(bool closed) {
    if (closed) line(pts[0], pts[1]);
    return pts.length < 8 ? null : CubicPath(Float64List.fromList(pts), closed);
  }
}

CubicPath? _lower(_RawSubpath raw) {
  final b = _Builder(raw.x0, raw.y0);
  for (final (tag, s) in raw.segs) {
    switch (tag) {
      case 'L':
        b.line(s[0], s[1]);
      case 'C':
        b.cubic(s[0], s[1], s[2], s[3], s[4], s[5]);
      case 'Q':
        b.quad(s[0], s[1], s[2], s[3]);
      case 'A':
        b.arc(s[0], s[1], s[2], s[3], s[4], s[5], s[6]);
    }
  }
  return b.finish(raw.closed);
}

double _attr(Map<String, Object?> attrs, String key, [double fallback = 0]) {
  final v = attrs[key];
  if (v == null) return fallback;
  final x = v is num ? v.toDouble() : double.tryParse('$v');
  return x != null && x.isFinite ? x : fallback;
}

List<double> _points(Object? v) {
  final s = (v ?? '').toString().trim();
  if (s.isEmpty) return [];
  final nums = s.split(RegExp(r'[\s,]+')).map(double.parse).toList();
  if (nums.any((x) => !x.isFinite)) {
    throw FormatException('morphicons: invalid points $s');
  }
  return nums;
}

CubicPath? _poly(List<double> nums, bool closed) {
  if (nums.length < 4) return null;
  final b = _Builder(nums[0], nums[1]);
  for (var i = 2; i + 1 < nums.length; i += 2) {
    b.line(nums[i], nums[i + 1]);
  }
  return b.finish(closed);
}

CubicPath? _ellipse(double cx, double cy, double rx, double ry) {
  if (rx < 1e-12 || ry < 1e-12) return null;
  final kx = _kappa * rx,
      ky = _kappa * ry,
      e = cx + rx,
      w = cx - rx,
      s = cy + ry,
      n = cy - ry;
  final b = _Builder(e, cy);
  b.cubic(e, cy + ky, cx + kx, s, cx, s);
  b.cubic(cx - kx, s, w, cy + ky, w, cy);
  b.cubic(w, cy - ky, cx - kx, n, cx, n);
  b.cubic(cx + kx, n, e, cy - ky, e, cy);
  return b.finish(true);
}

CubicPath? _rect(Map<String, Object?> a) {
  final x = _attr(a, 'x'),
      y = _attr(a, 'y'),
      w = _attr(a, 'width'),
      h = _attr(a, 'height');
  if (w < 1e-12 || h < 1e-12) return null;
  var rx = _attr(a, 'rx', double.nan), ry = _attr(a, 'ry', double.nan);
  if (rx.isNaN) rx = ry.isNaN ? 0 : ry;
  if (ry.isNaN) ry = rx;
  rx = math.min(math.max(rx, 0), w / 2);
  ry = math.min(math.max(ry, 0), h / 2);
  if (rx < 1e-12 || ry < 1e-12) {
    return _poly([x, y, x + w, y, x + w, y + h, x, y + h], true);
  }
  final xa = x + rx,
      xb = x + w - rx,
      xr = x + w,
      ya = y + ry,
      yb = y + h - ry,
      yd = y + h,
      kx = _kappa * rx,
      ky = _kappa * ry;
  final b = _Builder(xa, y);
  b.line(xb, y);
  b.cubic(xb + kx, y, xr, ya - ky, xr, ya);
  b.line(xr, yb);
  b.cubic(xr, yb + ky, xb + kx, yd, xb, yd);
  b.line(xa, yd);
  b.cubic(xa - kx, yd, x, yb + ky, x, yb);
  b.line(x, ya);
  b.cubic(x, ya - ky, xa - kx, y, xa, y);
  return b.finish(true);
}

List<CubicPath> iconToCubics(Object input) {
  final out = <CubicPath>[];
  void push(CubicPath? p) {
    if (p != null) out.add(p);
  }

  if (input is String) {
    for (final s in _parsePath(input)) {
      push(_lower(s));
    }
    return out;
  }
  for (final node in input as List<IconNode>) {
    final a = node.attrs;
    switch (node.tag) {
      case 'path':
        for (final s in _parsePath('${a['d'] ?? ''}')) {
          push(_lower(s));
        }
      case 'line':
        final b = _Builder(_attr(a, 'x1'), _attr(a, 'y1'));
        b.line(_attr(a, 'x2'), _attr(a, 'y2'));
        push(b.finish(false));
      case 'circle':
        final r = _attr(a, 'r');
        push(_ellipse(_attr(a, 'cx'), _attr(a, 'cy'), r, r));
      case 'ellipse':
        push(
          _ellipse(
            _attr(a, 'cx'),
            _attr(a, 'cy'),
            _attr(a, 'rx'),
            _attr(a, 'ry'),
          ),
        );
      case 'rect':
        push(_rect(a));
      case 'polyline':
        push(_poly(_points(a['points']), false));
      case 'polygon':
        push(_poly(_points(a['points']), true));
      default:
        throw FormatException('morphicons: unsupported tag ${node.tag}');
    }
  }
  return out;
}

String fitIcon(Object input, Object viewBox, [double grid = 24]) {
  final List<double> v = viewBox is num
      ? [0, 0, viewBox.toDouble(), viewBox.toDouble()]
      : viewBox is String
      ? _points(viewBox)
      : (viewBox as List<num>).map((x) => x.toDouble()).toList();
  if (v.length != 4 ||
      !(v[2] > 0) ||
      !(v[3] > 0) ||
      !v[0].isFinite ||
      !v[1].isFinite) {
    throw FormatException('morphicons: invalid viewBox $viewBox');
  }
  final s = math.min(grid / v[2], grid / v[3]),
      tx =
          (grid - v[2] * math.min(grid / v[2], grid / v[3])) / 2 -
          v[0] * math.min(grid / v[2], grid / v[3]);
  final ty = (grid - v[3] * s) / 2 - v[1] * s, paths = iconToCubics(input);
  for (final path in paths) {
    for (var i = 0; i < path.pts.length; i += 2) {
      path.pts[i] = path.pts[i] * s + tx;
      path.pts[i + 1] = path.pts[i + 1] * s + ty;
    }
  }
  return cubicsToPathD(paths);
}
