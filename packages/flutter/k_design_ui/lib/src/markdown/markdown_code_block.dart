part of 'k_markdown_renderer.dart';

final _highlight = Highlight()
  ..registerLanguage('javascript', langJavascript)
  ..registerLanguage('typescript', langTypescript)
  ..registerLanguage('json', langJson);

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.element,
    required this.style,
    required this.tokens,
    required this.selectable,
    required this.copyLabel,
    this.onCopy,
  });
  final md.Element element;
  final TextStyle style;
  final KDesignTokens tokens;
  final bool selectable;
  final String copyLabel;
  final ValueChanged<String>? onCopy;

  @override
  Widget build(BuildContext context) {
    final code = element.textContent.replaceFirst(RegExp(r'\n$'), '');
    final child = element.children?.firstOrNull;
    var language = child is md.Element
        ? (child.attributes['class'] ?? '').replaceFirst('language-', '')
        : '';
    final displayLanguage = language;
    language = switch (language) {
      'js' => 'javascript',
      'ts' => 'typescript',
      _ => language,
    };
    final codeStyle = style.copyWith(color: tokens.colorTextPrimary);
    TextSpan span = TextSpan(text: code, style: codeStyle);
    if (const {'javascript', 'typescript', 'json'}.contains(language)) {
      final renderer = TextSpanRenderer(codeStyle, {
        'keyword': TextStyle(color: tokens.colorSyntaxKeyword),
        'string': TextStyle(color: tokens.colorSyntaxString),
        'number': TextStyle(color: tokens.colorSyntaxNumber),
        'comment': TextStyle(color: tokens.colorSyntaxComment),
      });
      _highlight.highlight(code: code, language: language).render(renderer);
      span = renderer.span ?? span;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.colorSurfaceSubtle,
        borderRadius: BorderRadius.circular(tokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (language.isNotEmpty || onCopy != null)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceMediumInset,
                vertical: tokens.spaceControlGap,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      displayLanguage,
                      style: TextStyle(
                        color: tokens.colorTextMuted,
                        fontFamily: tokens.fontFamily,
                        fontSize: tokens.fontCaptionSize,
                        height:
                            tokens.fontCaptionLineHeight /
                            tokens.fontCaptionSize,
                      ),
                    ),
                  ),
                  if (onCopy != null)
                    KButton(
                      label: copyLabel,
                      variant: KButtonVariant.ghost,
                      onPressed: () => onCopy!(code),
                    ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.all(tokens.spaceMediumInset),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: selectable ? SelectableText.rich(span) : Text.rich(span),
            ),
          ),
        ],
      ),
    );
  }
}
