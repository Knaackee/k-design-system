/// Keep raw document bytes while re_editor uses LF paragraphs internally.
class KCodeSourceMap {
  KCodeSourceMap(this.raw);
  String raw;
  String get rendered => raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  int toRaw(int offset) {
    var visual = 0, source = 0;
    while (source < raw.length && visual < offset) {
      if (raw.codeUnitAt(source) == 13 &&
          source + 1 < raw.length &&
          raw.codeUnitAt(source + 1) == 10) {
        source++;
      }
      source++;
      visual++;
    }
    return source;
  }

  int toRendered(int offset) {
    var visual = 0, source = 0;
    while (source < raw.length && source < offset) {
      if (raw.codeUnitAt(source) == 13 &&
          source + 1 < raw.length &&
          raw.codeUnitAt(source + 1) == 10) {
        source++;
      }
      source++;
      visual++;
    }
    return visual;
  }

  void acceptRendered(String next) {
    final old = rendered;
    if (next == old) return;
    var from = 0, endOld = old.length, endNext = next.length;
    while (from < endOld &&
        from < endNext &&
        old.codeUnitAt(from) == next.codeUnitAt(from)) {
      from++;
    }
    while (endOld > from &&
        endNext > from &&
        old.codeUnitAt(endOld - 1) == next.codeUnitAt(endNext - 1)) {
      endOld--;
      endNext--;
    }
    final separator = RegExp(r'\r\n|\r|\n').firstMatch(raw)?.group(0) ?? '\n';
    final insert = next.substring(from, endNext).replaceAll('\n', separator);
    raw = raw.replaceRange(toRaw(from), toRaw(endOld), insert);
  }
}
