final _lineBreak = RegExp(r'\r\n?');
final _fenceLine = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');
final _blank = RegExp(r'^[ \t]*$');

/// Keep the final unfinished block literal until its block boundary is known.
/// An open top-level fence can safely render as code through the current EOF.
(String, String) splitStreamingMarkdown(String content) {
  final source = content.replaceAll(_lineBreak, '\n');
  var committedEnd = 0;
  String? fence;
  for (var start = 0; start < source.length;) {
    final end = source.indexOf('\n', start);
    if (end == -1) break;
    final line = source.substring(start, end);
    start = end + 1;
    final match = _fenceLine.firstMatch(line);
    if (fence != null) {
      if (match != null &&
          match[1]!.startsWith(fence) &&
          _blank.hasMatch(match[2]!)) {
        fence = null;
        committedEnd = start;
      }
    } else if (match != null &&
        (!match[1]!.startsWith('`') || !match[2]!.contains('`'))) {
      fence = match[1];
    } else if (_blank.hasMatch(line)) {
      committedEnd = start;
    }
  }
  if (fence != null) return (source, '');
  return (source.substring(0, committedEnd), source.substring(committedEnd));
}
