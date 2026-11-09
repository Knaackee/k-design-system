import 'package:flutter/material.dart';
import 'k_markdown_renderer.dart';

/// Document presentation without owning navigation or editor state.
class KMarkdownPreview extends StatelessWidget {
  const KMarkdownPreview({
    required this.content,
    this.semanticLabel = 'Markdown preview',
    this.contentMaxWidth,
    this.loading = false,
    this.loadingContent,
    this.emptyContent,
    this.profile = KMarkdownProfile.document,
    this.streaming = false,
    this.allowedElements,
    this.onLinkActivate,
    this.imageBuilder,
    this.selectable = true,
    this.copyLabel = 'Copy',
    this.tableLabel = 'Table',
    this.completedTaskLabel = 'Completed',
    this.incompleteTaskLabel = 'Not completed',
    this.alertLabels = const {},
    this.onCopy,
    super.key,
  });
  final String content;
  final String semanticLabel;
  final double? contentMaxWidth;
  final bool loading;
  final Widget? loadingContent;
  final Widget? emptyContent;
  final KMarkdownProfile profile;
  final bool streaming;
  final Set<String>? allowedElements;
  final ValueChanged<Uri>? onLinkActivate;
  final Widget Function(Uri uri, String? alt, String? title)? imageBuilder;
  final bool selectable;
  final String copyLabel;
  final String tableLabel;
  final String completedTaskLabel;
  final String incompleteTaskLabel;
  final Map<String, String> alertLabels;
  final ValueChanged<String>? onCopy;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    readOnly: true,
    child: Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: contentMaxWidth ?? double.infinity,
        ),
        child: loading
            ? loadingContent ?? const SizedBox.shrink()
            : content.trim().isEmpty
            ? emptyContent ?? const SizedBox.shrink()
            : KMarkdownRenderer(
                content: content,
                profile: profile,
                streaming: streaming,
                allowedElements: allowedElements,
                onLinkActivate: onLinkActivate,
                imageBuilder: imageBuilder,
                selectable: selectable,
                copyLabel: copyLabel,
                tableLabel: tableLabel,
                completedTaskLabel: completedTaskLabel,
                incompleteTaskLabel: incompleteTaskLabel,
                alertLabels: alertLabels,
                onCopy: onCopy,
              ),
      ),
    ),
  );
}
