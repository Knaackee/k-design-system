part of 'core.dart';

// Minimum-cost permutation or surjection. Surjection duplicates paths when
// counts differ instead of creating/disappearing strokes during interpolation.

List<List<double>> _costMatrix(List<Float64List> a, List<Float64List> b) {
  final cbs = b.map(centroid).toList(), lbs = b.map(polyLen).toList();
  return a.map((path) {
    final ca = centroid(path), la = polyLen(path);
    return List.generate(
      b.length,
      (j) =>
          _hypot(ca[0] - cbs[j][0], ca[1] - cbs[j][1]) +
          0.35 * (la - lbs[j]).abs(),
    );
  }).toList();
}

List<int> _bestPermutation(List<List<double>> c) {
  final n = c.length;
  if (n > 8) {
    final pairs = <(double, int, int)>[];
    for (var i = 0; i < n; i++) {
      for (var j = 0; j < n; j++) {
        pairs.add((c[i][j], i, j));
      }
    }
    pairs.sort((x, y) {
      final diff = x.$1.compareTo(y.$1);
      if (diff != 0) return diff;
      final i = x.$2.compareTo(y.$2);
      return i != 0 ? i : x.$3.compareTo(y.$3);
    });
    final out = List.filled(n, -1), used = List.filled(n, false);
    for (final (_, i, j) in pairs) {
      if (out[i] < 0 && !used[j]) {
        out[i] = j;
        used[j] = true;
      }
    }
    return out;
  }
  final idx = List.generate(n, (i) => i);
  var best = List<int>.of(idx), bc = double.infinity;
  void perm(List<int> arr, int k, double acc) {
    if (acc >= bc) return;
    if (k == n) {
      bc = acc;
      best = List.of(arr);
      return;
    }
    for (var i = k; i < n; i++) {
      final temp = arr[k];
      arr[k] = arr[i];
      arr[i] = temp;
      perm(arr, k + 1, acc + c[k][arr[k]]);
      final restore = arr[k];
      arr[k] = arr[i];
      arr[i] = restore;
    }
  }

  perm(idx, 0, 0);
  return best;
}

List<int> _bestSurjection(List<List<double>> c) {
  final big = c.length, small = c[0].length;
  if (math.pow(small, big) > 1e5) {
    final f = c.map((row) {
      var m = 0;
      for (var j = 1; j < row.length; j++) {
        if (row[j] < row[m]) m = j;
      }
      return m;
    }).toList();
    final mult = List.filled(small, 0);
    for (final s in f) {
      mult[s]++;
    }
    for (var s = 0; s < small; s++) {
      if (mult[s] > 0) continue;
      var bi = -1, bc = double.infinity;
      for (var i = 0; i < big; i++) {
        if (mult[f[i]] < 2) continue;
        final extra = c[i][s] - c[i][f[i]];
        if (extra < bc) {
          bc = extra;
          bi = i;
        }
      }
      mult[f[bi]]--;
      f[bi] = s;
      mult[s]++;
    }
    return f;
  }
  List<int>? best;
  var bc = double.infinity;
  final f = List.filled(big, 0), mult = List.filled(small, 0);
  void rec(int i, double acc, int covered) {
    if (acc >= bc || small - covered > big - i) return;
    if (i == big) {
      bc = acc;
      best = List.of(f);
      return;
    }
    for (var s = 0; s < small; s++) {
      f[i] = s;
      mult[s]++;
      rec(i + 1, acc + c[i][s], covered + (mult[s] == 1 ? 1 : 0));
      mult[s]--;
    }
  }

  rec(0, 0, 0);
  if (best == null) throw StateError('morphicons: no valid surjection (B < S)');
  return best!;
}
