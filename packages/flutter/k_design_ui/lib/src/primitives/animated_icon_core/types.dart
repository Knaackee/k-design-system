part of 'core.dart';

class IconNode {
  const IconNode(this.tag, this.attrs);
  final String tag;
  final Map<String, Object?> attrs;
}

class CubicPath {
  CubicPath(this.pts, this.closed);
  final Float64List pts;
  final bool closed;
}

class Sampled {
  Sampled(this.pts, this.closed);
  final Float64List pts;
  final bool closed;
}

class _RawSubpath {
  _RawSubpath(this.x0, this.y0);
  final double x0, y0;
  final List<(String, List<double>)> segs = [];
  bool closed = false;
}

double _hypot(double x, double y) => math.sqrt(x * x + y * y);
int _jsRound(double x) => (x + 0.5).floor();
