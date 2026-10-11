import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum KEditorMode { source, read }

enum KEditorTransactionOrigin { local, remote }

enum KCodeLanguage { plain, javascript, typescript, json, markdown }

enum KCodeCompletionType { keyword, function, variable, property, text }

@immutable
class KCodeCompletion {
  const KCodeCompletion({
    required this.label,
    this.detail,
    this.apply,
    this.type = KCodeCompletionType.text,
  });

  final String label;
  final String? detail;
  final String? apply;
  final KCodeCompletionType type;
}

@immutable
class KEditorSelection {
  const KEditorSelection({required this.anchor, required this.head});

  final int anchor;
  final int head;

  bool get isCollapsed => anchor == head;
  int get start => anchor < head ? anchor : head;
  int get end => anchor > head ? anchor : head;

  @override
  bool operator ==(Object other) =>
      other is KEditorSelection && other.anchor == anchor && other.head == head;

  @override
  int get hashCode => Object.hash(anchor, head);
}

@immutable
class KEditorTransaction {
  const KEditorTransaction({
    required this.value,
    required this.selection,
    required this.origin,
  });

  final String value;
  final KEditorSelection selection;
  final KEditorTransactionOrigin origin;
}

@immutable
class KEditorParticipant {
  const KEditorParticipant({
    required this.id,
    required this.name,
    required this.color,
    this.foregroundColor,
  });

  final String id;
  final String name;
  final Color color;
  final Color? foregroundColor;
}

@immutable
class KRemoteSelection extends KEditorSelection {
  const KRemoteSelection({
    required super.anchor,
    required super.head,
    required this.participant,
  });

  final KEditorParticipant participant;
}

@immutable
class KEditorCollaborationSnapshot {
  const KEditorCollaborationSnapshot({
    required this.value,
    this.selection = const KEditorSelection(anchor: 0, head: 0),
    this.remoteSelections = const [],
    this.participants = const [],
  });

  final String value;
  final KEditorSelection selection;
  final List<KRemoteSelection> remoteSelections;
  final List<KEditorParticipant> participants;
}

/// Transport-neutral bridge for Yjs, Automerge or a consumer-owned CRDT.
///
/// Durable document updates travel through [applyLocalTransaction]. Ephemeral
/// cursors and presence remain in [snapshot] and are never persisted by the UI.
abstract interface class KEditorCollaborationAdapter {
  ValueListenable<KEditorCollaborationSnapshot> get snapshot;

  void applyLocalTransaction(KEditorTransaction transaction);
}

@immutable
class KCodeDiagnostic {
  const KCodeDiagnostic({
    required this.from,
    required this.to,
    required this.severity,
    required this.message,
  });

  final int from;
  final int to;
  final KCodeDiagnosticSeverity severity;
  final String message;
}

enum KCodeDiagnosticSeverity { info, warning, error }

@immutable
class KEditorLabels {
  const KEditorLabels({
    this.source = 'Markdown',
    this.read = 'Preview',
    this.bold = 'Bold',
    this.italic = 'Italic',
    this.strike = 'Strikethrough',
    this.code = 'Inline code',
    this.link = 'Link',
    this.bulletList = 'Bullet list',
    this.orderedList = 'Numbered list',
    this.taskList = 'Task list',
    this.quote = 'Quote',
    this.codeBlock = 'Code block',
    this.undo = 'Undo',
    this.redo = 'Redo',
    this.search = 'Search',
    this.searchFind = 'Find',
    this.searchReplace = 'Replace',
    this.searchReplaceAll = 'Replace all',
    this.searchNext = 'Next result',
    this.searchPrevious = 'Previous result',
    this.searchAll = 'Select all',
    this.searchClose = 'Close search',
    this.searchOptions = 'Search options',
    this.searchShowReplace = 'Show replace',
    this.searchMatchCase = 'Match case',
    this.searchRegexp = 'Regular expression',
    this.searchWholeWord = 'Whole word',
    this.wrap = 'Wrap long lines',
    this.lineNumbers = 'Line numbers',
    this.noResults = 'No results',
  });

  final String source;
  final String read;
  final String bold;
  final String italic;
  final String strike;
  final String code;
  final String link;
  final String bulletList;
  final String orderedList;
  final String taskList;
  final String quote;
  final String codeBlock;
  final String undo;
  final String redo;
  final String search;
  final String searchFind;
  final String searchReplace;
  final String searchReplaceAll;
  final String searchNext;
  final String searchPrevious;
  final String searchAll;
  final String searchClose;
  final String searchOptions;
  final String searchShowReplace;
  final String searchMatchCase;
  final String searchRegexp;
  final String searchWholeWord;
  final String wrap;
  final String lineNumbers;
  final String noResults;
}

enum KMarkdownFormatAction {
  undo,
  redo,
  bold,
  italic,
  strike,
  code,
  link,
  bulletList,
  orderedList,
  taskList,
  quote,
  codeBlock,
}

const kDefaultMarkdownFormatActions = KMarkdownFormatAction.values;
