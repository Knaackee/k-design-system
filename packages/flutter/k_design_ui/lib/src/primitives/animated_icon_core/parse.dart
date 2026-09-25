part of 'core.dart';

// Resolves SVG relative commands, implicit repetitions, packed arc flags and
// reflected shorthand controls before cubic normalization.

List<_RawSubpath> _parsePath(String d) {
  final subs = <_RawSubpath>[];
  final n = d.length;
  var i = 0;
  var cx = 0.0, cy = 0.0, sx = 0.0, sy = 0.0, px = 0.0, py = 0.0;
  _RawSubpath? cur;
  var cmd = '', prev = '';
  var started = false, rel = false;
  Never err(String msg) => throw FormatException('morphicons: $msg at d[$i]');
  bool digit(int c) => c >= 48 && c <= 57;
  void skip() {
    while (i < n && const [32, 9, 10, 13, 12, 44].contains(d.codeUnitAt(i))) {
      i++;
    }
  }

  double num() {
    skip();
    final start = i;
    if (i < n && (d[i] == '+' || d[i] == '-')) i++;
    var dig = false;
    while (i < n && digit(d.codeUnitAt(i))) {
      i++;
      dig = true;
    }
    if (i < n && d[i] == '.') {
      i++;
      while (i < n && digit(d.codeUnitAt(i))) {
        i++;
        dig = true;
      }
    }
    if (!dig) err('expected number');
    if (i < n && (d[i] == 'e' || d[i] == 'E')) {
      final save = i;
      i++;
      if (i < n && (d[i] == '+' || d[i] == '-')) i++;
      var ed = false;
      while (i < n && digit(d.codeUnitAt(i))) {
        i++;
        ed = true;
      }
      if (!ed) i = save;
    }
    return double.parse(d.substring(start, i));
  }

  double flag() {
    skip();
    if (i < n && (d[i] == '0' || d[i] == '1')) return d[i++] == '1' ? 1 : 0;
    return err('expected arc flag (0|1)');
  }

  _RawSubpath open() {
    if (!started) err('path must start with M/m');
    if (cur == null) {
      cur = _RawSubpath(cx, cy);
      subs.add(cur!);
    }
    return cur!;
  }

  double nx() => num() + (rel ? cx : 0);
  double ny() => num() + (rel ? cy : 0);
  while (true) {
    skip();
    if (i >= n) break;
    final ch = d[i];
    if ('MmLlHhVvCcSsQqTtAaZz'.contains(ch)) {
      cmd = ch;
      i++;
    } else if (cmd == '') {
      err('path must start with M/m');
    } else if (cmd == 'M') {
      cmd = 'L';
    } else if (cmd == 'm') {
      cmd = 'l';
    } else if (cmd == 'Z' || cmd == 'z') {
      err('stray data after Z');
    }
    rel = cmd.compareTo('a') >= 0;
    switch (cmd.toUpperCase()) {
      case 'M':
        started = true;
        final x = nx(), y = ny();
        cx = x;
        cy = y;
        sx = x;
        sy = y;
        cur = _RawSubpath(x, y);
        subs.add(cur!);
        prev = '';
      case 'L':
        final x = nx(), y = ny();
        open().segs.add(('L', [x, y]));
        cx = x;
        cy = y;
        prev = '';
      case 'H':
        final x = nx();
        open().segs.add(('L', [x, cy]));
        cx = x;
        prev = '';
      case 'V':
        final y = ny();
        open().segs.add(('L', [cx, y]));
        cy = y;
        prev = '';
      case 'C':
      case 'S':
        final direct = cmd.toUpperCase() == 'C';
        final x1 = direct ? nx() : (prev == 'C' ? 2 * cx - px : cx);
        final y1 = direct ? ny() : (prev == 'C' ? 2 * cy - py : cy);
        final x2 = nx(), y2 = ny(), x = nx(), y = ny();
        open().segs.add(('C', [x1, y1, x2, y2, x, y]));
        px = x2;
        py = y2;
        cx = x;
        cy = y;
        prev = 'C';
      case 'Q':
      case 'T':
        final direct = cmd.toUpperCase() == 'Q';
        final x1 = direct ? nx() : (prev == 'Q' ? 2 * cx - px : cx);
        final y1 = direct ? ny() : (prev == 'Q' ? 2 * cy - py : cy);
        final x = nx(), y = ny();
        open().segs.add(('Q', [x1, y1, x, y]));
        px = x1;
        py = y1;
        cx = x;
        cy = y;
        prev = 'Q';
      case 'A':
        final rx = num(),
            ry = num(),
            rot = num(),
            large = flag(),
            sweep = flag(),
            x = nx(),
            y = ny();
        open().segs.add(('A', [rx, ry, rot, large, sweep, x, y]));
        cx = x;
        cy = y;
        prev = '';
      case 'Z':
        cur?.closed = true;
        cur = null;
        cx = sx;
        cy = sy;
        prev = '';
      default:
        err('unsupported command $cmd');
    }
  }
  return subs.where((s) => s.segs.isNotEmpty).toList();
}
