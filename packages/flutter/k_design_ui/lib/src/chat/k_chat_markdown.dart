import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

class KChatMarkdown extends StatelessWidget {
  const KChatMarkdown({
    required this.text,
    this.streaming = false,
    this.onLinkActivate,
    super.key,
  });

  final String text;
  final bool streaming;
  final ValueChanged<Uri>? onLinkActivate;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final body = TextStyle(
      color: t.colorTextPrimary,
      fontFamily: t.fontFamily,
      fontSize: KDesignTokenVariants.typeScaleCompactFontBodySize,
      height: KDesignTokenVariants.typeScaleCompactFontBodyLineHeight /
          KDesignTokenVariants.typeScaleCompactFontBodySize,
    );
    return Semantics(
      liveRegion: streaming,
      child: MarkdownBody(
        data: text,
        selectable: true,
        softLineBreak: true,
        styleSheet: MarkdownStyleSheet(
          p: body,
          h1: body.copyWith(
            fontSize: t.fontHeading2Size,
            fontWeight: t.fontHeadingWeight,
          ),
          h2: body.copyWith(
            fontSize: t.fontHeading3Size,
            fontWeight: t.fontHeadingWeight,
          ),
          h3: body.copyWith(
            fontSize: t.fontHeading4Size,
            fontWeight: t.fontHeadingWeight,
          ),
          strong: body.copyWith(fontWeight: t.fontLabelWeight),
          code: body.copyWith(
            fontFamily: t.fontFamily,
            fontSize: t.fontBodySmallSize,
            backgroundColor: t.colorSurfaceSubtle,
          ),
          codeblockDecoration: BoxDecoration(
            color: t.colorSurfaceSubtle,
            border: Border.all(color: t.colorBorderDefault),
            borderRadius: BorderRadius.circular(t.radiusControl),
          ),
          codeblockPadding: EdgeInsets.all(t.spaceControlInsetInline),
          blockquoteDecoration: BoxDecoration(
            color: t.colorSurfaceSubtle,
            border: BorderDirectional(
              start: BorderSide(color: t.colorBorderStrong),
            ),
          ),
          tableBorder: TableBorder.all(color: t.colorBorderDefault),
          tableCellsPadding: EdgeInsets.all(t.spaceControlGap),
          a: body.copyWith(
            color: t.colorActionPrimaryBackground,
            decoration: TextDecoration.underline,
          ),
        ),
        onTapLink: (_, href, _) {
          final uri = href == null ? null : Uri.tryParse(href);
          if (uri != null) onLinkActivate?.call(uri);
        },
      ),
    );
  }
}
