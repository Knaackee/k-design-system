import 'package:k_design_ui/src/editors/k_code_source_map.dart';

void check(bool value, String message) {
  if (!value) throw StateError(message);
}

void main() {
  for (final separator in ['\n', '\r\n', '\r']) {
    for (final line in [
      'TXT A😀B',
      '## MD A😀B',
      'const ts = "A😀B";',
      'print("A😀B")',
      '{"json":"A😀B"}',
    ]) {
      final raw = 'first$separator$line${separator}last';
      final map = KCodeSourceMap(raw);
      check(map.rendered == 'first\n$line\nlast', 'rendering');
      for(var offset=0;offset<=map.rendered.length;offset++){
        check(map.toRendered(map.toRaw(offset))==offset,'all rendered UTF16 positions');
      }
      final afterEmoji = raw.indexOf('😀') + 2;
      check(
        map.toRaw(map.toRendered(afterEmoji)) == afterEmoji,
        'UTF16 emoji offset',
      );
      map.acceptRendered(map.rendered);
      check(map.raw == raw, 'focus must not mutate separators');
      map.acceptRendered(map.rendered.replaceFirst('A😀B', 'A😀X'));
      check(
        map.raw == raw.replaceFirst('A😀B', 'A😀X'),
        'local edit retains separators',
      );
      map.acceptRendered('${map.rendered}\nnew');
      check(map.raw.endsWith('${separator}new'), 'new line preserves style');
    }
  }
  final mixed = KCodeSourceMap('one\r\ntwo\nthree\rfour');
  mixed.acceptRendered('one\ntwo changed\nthree\nfour');
  check(
    mixed.raw == 'one\r\ntwo changed\nthree\rfour',
    'mixed separators retained',
  );
}
