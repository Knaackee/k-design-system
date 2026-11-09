part of 'k_markdown_editor.dart';

class _MarkdownPreview extends StatelessWidget {
  const _MarkdownPreview({
    required this.markdown,
    required this.semanticLabel,
    required this.topInset,
    this.contentMaxWidth,
    this.imageBuilder,
    this.onLinkPressed,
    required this.markdownOptions,
  });

  final String markdown;
  final String semanticLabel;
  final KMarkdownOptions markdownOptions;
  final double topInset;
  final double? contentMaxWidth;
  final Widget Function(Uri uri, String? alt, String? title)? imageBuilder;
  final ValueChanged<String>? onLinkPressed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.colorSurfaceCanvas,
        border: Border.all(color: t.colorBorderDefault),
        borderRadius: BorderRadius.circular(t.radiusCard),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: contentMaxWidth ?? double.infinity,
          ),
          child: SizedBox.expand(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                t.spaceMediumInset,
                topInset,
                t.spaceMediumInset,
                t.spaceMediumInset,
              ),
              child: KMarkdownPreview(
                content: markdown,
                semanticLabel: semanticLabel,
                imageBuilder: imageBuilder ?? markdownOptions.imageBuilder,
                onLinkActivate: onLinkPressed == null
                    ? markdownOptions.onLinkActivate
                    : (uri) => onLinkPressed!(uri.toString()),
                allowedElements: markdownOptions.allowedElements,
                selectable: markdownOptions.selectable ?? true,
                onCopy: markdownOptions.onCopy,
                copyLabel: markdownOptions.copyLabel,
                tableLabel: markdownOptions.tableLabel,
                completedTaskLabel: markdownOptions.completedTaskLabel,
                incompleteTaskLabel: markdownOptions.incompleteTaskLabel,
                alertLabels: markdownOptions.alertLabels,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
