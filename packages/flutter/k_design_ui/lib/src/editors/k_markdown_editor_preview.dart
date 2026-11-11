part of 'k_markdown_editor.dart';

class _MarkdownPreview extends StatefulWidget {
  const _MarkdownPreview({
    required this.markdown,
    required this.initialScrollOffset,
    required this.onScrollOffsetChanged,
    required this.semanticLabel,
    required this.topInset,
    this.bottomInset = 0,
    this.contentMaxWidth,
    this.imageBuilder,
    this.onLinkPressed,
    required this.markdownOptions,
  });

  final String markdown;
  final double initialScrollOffset;
  final ValueChanged<double> onScrollOffsetChanged;
  final String semanticLabel;
  final KMarkdownOptions markdownOptions;
  final double topInset;
  final double bottomInset;
  final double? contentMaxWidth;
  final Widget Function(Uri uri, String? alt, String? title)? imageBuilder;
  final ValueChanged<String>? onLinkPressed;

  @override
  State<_MarkdownPreview> createState() => _MarkdownPreviewState();
}

class _MarkdownPreviewState extends State<_MarkdownPreview> {
  late final _scrollController = ScrollController(
    initialScrollOffset: widget.initialScrollOffset,
    keepScrollOffset: false,
  )..addListener(_rememberOffset);

  void _rememberOffset() {
    if (_scrollController.hasClients) {
      widget.onScrollOffsetChanged(_scrollController.offset);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_rememberOffset);
    _scrollController.dispose();
    super.dispose();
  }

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
            maxWidth: widget.contentMaxWidth ?? double.infinity,
          ),
          child: SizedBox.expand(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                t.spaceMediumInset,
                widget.topInset,
                t.spaceMediumInset,
                t.spaceMediumInset + widget.bottomInset,
              ),
              child: KMarkdownPreview(
                content: widget.markdown,
                semanticLabel: widget.semanticLabel,
                imageBuilder:
                    widget.imageBuilder ?? widget.markdownOptions.imageBuilder,
                onLinkActivate: widget.onLinkPressed == null
                    ? widget.markdownOptions.onLinkActivate
                    : (uri) => widget.onLinkPressed!(uri.toString()),
                allowedElements: widget.markdownOptions.allowedElements,
                selectable: widget.markdownOptions.selectable ?? true,
                onCopy: widget.markdownOptions.onCopy,
                copyLabel: widget.markdownOptions.copyLabel,
                tableLabel: widget.markdownOptions.tableLabel,
                completedTaskLabel: widget.markdownOptions.completedTaskLabel,
                incompleteTaskLabel: widget.markdownOptions.incompleteTaskLabel,
                alertLabels: widget.markdownOptions.alertLabels,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
