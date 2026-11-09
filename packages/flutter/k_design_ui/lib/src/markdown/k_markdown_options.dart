import 'package:flutter/widgets.dart';

/// Host-owned presentation and actions shared by editor previews and chat.
class KMarkdownOptions {
  const KMarkdownOptions({
    this.allowedElements,
    this.onLinkActivate,
    this.imageBuilder,
    this.selectable,
    this.onCopy,
    this.copyLabel = 'Copy',
    this.tableLabel = 'Table',
    this.completedTaskLabel = 'Completed',
    this.incompleteTaskLabel = 'Not completed',
    this.alertLabels = const {},
  });
  final Set<String>? allowedElements;
  final ValueChanged<Uri>? onLinkActivate;
  final Widget Function(Uri uri, String? alt, String? title)? imageBuilder;
  final bool? selectable;
  final ValueChanged<String>? onCopy;
  final String copyLabel;
  final String tableLabel;
  final String completedTaskLabel;
  final String incompleteTaskLabel;
  final Map<String, String> alertLabels;
}
