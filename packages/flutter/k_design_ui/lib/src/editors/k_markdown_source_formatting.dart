import 'k_editor_types.dart';

class KMarkdownSourceChange {
  const KMarkdownSourceChange({
    required this.from,
    required this.to,
    required this.insert,
    required this.selection,
  });

  final int from;
  final int to;
  final String insert;
  final KEditorSelection selection;
}

KMarkdownSourceChange _wrap(
  String source,
  KEditorSelection selection,
  String before, [
  String? after,
]) {
  final selected = source.substring(selection.start, selection.end);
  final suffix = after ?? before;
  return KMarkdownSourceChange(
    from: selection.start,
    to: selection.end,
    insert: '$before$selected$suffix',
    selection: KEditorSelection(
      anchor: selection.start + before.length,
      head: selection.start + before.length + selected.length,
    ),
  );
}

KMarkdownSourceChange _prefixLines(
  String source,
  KEditorSelection selection,
  String Function(int index) prefix,
) {
  final lineStart = selection.start == 0
      ? 0
      : source.lastIndexOf('\n', selection.start - 1) + 1;
  final nextBreak = source.indexOf('\n', selection.end);
  final lineEnd = nextBreak < 0 ? source.length : nextBreak;
  final insert = source
      .substring(lineStart, lineEnd)
      .split('\n')
      .indexed
      .map((entry) => '${prefix(entry.$1)}${entry.$2}')
      .join('\n');
  return KMarkdownSourceChange(
    from: lineStart,
    to: lineEnd,
    insert: insert,
    selection: KEditorSelection(
      anchor: lineStart,
      head: lineStart + insert.length,
    ),
  );
}

KMarkdownSourceChange kMarkdownSourceChange(
  String source,
  KEditorSelection selection,
  KMarkdownFormatAction action, {
  String? href,
}) => switch (action) {
  KMarkdownFormatAction.undo || KMarkdownFormatAction.redo => throw StateError(
    'History actions are handled by the editor controller.',
  ),
  KMarkdownFormatAction.bold => _wrap(source, selection, '**'),
  KMarkdownFormatAction.italic => _wrap(source, selection, '_'),
  KMarkdownFormatAction.strike => _wrap(source, selection, '~~'),
  KMarkdownFormatAction.code => _wrap(source, selection, '`'),
  KMarkdownFormatAction.link => _link(source, selection, href!),
  KMarkdownFormatAction.bulletList => _prefixLines(
    source,
    selection,
    (_) => '- ',
  ),
  KMarkdownFormatAction.orderedList => _prefixLines(
    source,
    selection,
    (index) => '${index + 1}. ',
  ),
  KMarkdownFormatAction.taskList => _prefixLines(
    source,
    selection,
    (_) => '- [ ] ',
  ),
  KMarkdownFormatAction.quote => _prefixLines(source, selection, (_) => '> '),
  KMarkdownFormatAction.codeBlock => _wrap(source, selection, '```\n', '\n```'),
};

KMarkdownSourceChange _link(
  String source,
  KEditorSelection selection,
  String href,
) {
  final label = source
      .substring(selection.start, selection.end)
      .replaceAllMapped(RegExp(r'[\\\[\]]'), (match) => '\\${match[0]}');
  final destination = href.replaceAllMapped(
    RegExp(r'[\\()]'),
    (match) => '\\${match[0]}',
  );
  return KMarkdownSourceChange(
    from: selection.start,
    to: selection.end,
    insert: '[$label]($destination)',
    selection: KEditorSelection(
      anchor: selection.start + 1,
      head: selection.start + 1 + label.length,
    ),
  );
}
