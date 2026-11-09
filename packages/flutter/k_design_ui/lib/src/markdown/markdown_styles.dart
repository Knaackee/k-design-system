import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'k_markdown_renderer.dart';

MarkdownStyleSheet markdownStyles(
  BuildContext context,
  KMarkdownProfile profile,
) {
  final t =
      Theme.of(context).extension<KDesignTokens>() ?? KDesignTokens.orbitLight;
  final chat = profile == KMarkdownProfile.chat;
  final body = TextStyle(
    color: t.colorTextPrimary,
    fontFamily: t.fontFamily,
    fontSize: t.fontBodySize,
    height: t.fontBodyLineHeight / t.fontBodySize,
    fontWeight: t.fontBodyWeight,
  );
  final tableDivider = BorderSide(
    color: t.colorBorderDefault,
    width: t.borderWidthDefault,
  );
  TextStyle heading(double size, double height) => body.copyWith(
    fontSize: size,
    height: height / size,
    fontWeight: t.fontHeadingWeight,
  );
  return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
    p: body,
    h1: heading(
      chat ? t.fontHeading4Size : t.fontHeading2Size,
      chat ? t.fontHeading4LineHeight : t.fontHeading2LineHeight,
    ),
    h2: heading(
      chat ? t.fontHeading4Size : t.fontHeading3Size,
      chat ? t.fontHeading4LineHeight : t.fontHeading3LineHeight,
    ),
    h3: heading(t.fontHeading4Size, t.fontHeading4LineHeight),
    h4: heading(t.fontHeading4Size, t.fontHeading4LineHeight),
    h5: heading(t.fontHeading4Size, t.fontHeading4LineHeight),
    h6: heading(t.fontHeading4Size, t.fontHeading4LineHeight),
    strong: TextStyle(fontWeight: t.fontHeadingWeight),
    em: const TextStyle(fontStyle: FontStyle.italic),
    del: const TextStyle(decoration: TextDecoration.lineThrough),
    a: TextStyle(
      color: t.colorStatusInfoAccent,
      fontWeight: t.fontLabelWeight,
      decoration: TextDecoration.underline,
    ),
    code: body.copyWith(
      fontFamily: 'packages/k_design_ui/KDesignMono',
      fontSize: t.fontBodySmallSize,
      height: t.fontBodySmallLineHeight / t.fontBodySmallSize,
      color: t.colorSyntaxCode,
    ),
    blockSpacing: chat ? t.spaceControlInsetInline : t.spaceMediumInset,
    listIndent: t.spaceLayoutSectionGap,
    listBullet: body,
    // The upstream builder adds bullet padding to listIndent. Keep the complete
    // text inset equal to Web's section-gap list padding, including nested lists.
    listBulletPadding: EdgeInsets.zero,
    blockquote: body.copyWith(color: t.colorTextMuted),
    blockquotePadding: EdgeInsets.only(left: t.spaceMediumInset),
    blockquoteDecoration: BoxDecoration(
      border: BorderDirectional(
        start: BorderSide(
          color: t.colorBorderStrong,
          width: t.borderWidthStrong,
        ),
      ),
    ),
    tableHead: body.copyWith(
      color: t.colorTextMuted,
      fontWeight: t.fontBodyWeight,
      fontSize: t.fontBodySmallSize,
    ),
    tableBody: body,
    tableBorder: TableBorder(
      horizontalInside: tableDivider,
      bottom: tableDivider,
    ),
    tableCellsPadding: EdgeInsets.symmetric(
      horizontal: t.spaceMediumInset,
      vertical: chat ? t.spaceControlGap : t.spaceControlInsetInline,
    ),
    tableColumnWidth: const IntrinsicColumnWidth(),
    tableHeadAlign: TextAlign.start,
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: t.colorBorderDefault,
          width: t.borderWidthDefault,
        ),
      ),
    ),
  );
}
