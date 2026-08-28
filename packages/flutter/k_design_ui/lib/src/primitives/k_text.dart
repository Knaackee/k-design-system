import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

enum KTextVariant {
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  body,
  bodySmall,
  label,
  caption,
}

class KText extends StatelessWidget {
  const KText(
    this.data, {
    this.variant = KTextVariant.body,
    this.align,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.style,
    super.key,
  });

  final String data;
  final KTextVariant variant;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final (size, lineHeight, letterSpacing, weight) = switch (variant) {
      KTextVariant.heading1 => (
        tokens.fontHeading1Size,
        tokens.fontHeading1LineHeight,
        tokens.fontHeading1LetterSpacing,
        tokens.fontHeadingWeight,
      ),
      KTextVariant.heading2 => (
        tokens.fontHeading2Size,
        tokens.fontHeading2LineHeight,
        tokens.fontHeading2LetterSpacing,
        tokens.fontHeadingWeight,
      ),
      KTextVariant.heading3 => (
        tokens.fontHeading3Size,
        tokens.fontHeading3LineHeight,
        tokens.fontHeading3LetterSpacing,
        tokens.fontHeadingWeight,
      ),
      KTextVariant.heading4 => (
        tokens.fontHeading4Size,
        tokens.fontHeading4LineHeight,
        tokens.fontHeading4LetterSpacing,
        tokens.fontHeadingWeight,
      ),
      KTextVariant.heading5 => (
        tokens.fontHeading5Size,
        tokens.fontHeading5LineHeight,
        tokens.fontHeading5LetterSpacing,
        tokens.fontHeadingWeight,
      ),
      KTextVariant.heading6 => (
        tokens.fontHeading6Size,
        tokens.fontHeading6LineHeight,
        tokens.fontHeading6LetterSpacing,
        tokens.fontHeadingWeight,
      ),
      KTextVariant.body => (
        tokens.fontBodySize,
        tokens.fontBodyLineHeight,
        tokens.fontBodyLetterSpacing,
        tokens.fontBodyWeight,
      ),
      KTextVariant.bodySmall => (
        tokens.fontBodySmallSize,
        tokens.fontBodySmallLineHeight,
        tokens.fontBodySmallLetterSpacing,
        tokens.fontBodyWeight,
      ),
      KTextVariant.label => (
        tokens.fontLabelSize,
        tokens.fontLabelLineHeight,
        tokens.fontLabelLetterSpacing,
        tokens.fontLabelWeight,
      ),
      KTextVariant.caption => (
        tokens.fontCaptionSize,
        tokens.fontCaptionLineHeight,
        tokens.fontCaptionLetterSpacing,
        tokens.fontBodyWeight,
      ),
    };
    final headingLevel = switch (variant) {
      KTextVariant.heading1 => 1,
      KTextVariant.heading2 => 2,
      KTextVariant.heading3 => 3,
      KTextVariant.heading4 => 4,
      KTextVariant.heading5 => 5,
      KTextVariant.heading6 => 6,
      _ => null,
    };

    final text = Text(
      data,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: TextStyle(
        color: tokens.colorTextPrimary,
        fontFamily: tokens.fontFamily,
        fontSize: size,
        fontWeight: weight,
        fontVariations: [
          FontVariation.weight(weight.value.toDouble()),
          FontVariation.opticalSize(size.clamp(14, 32)),
        ],
        height: lineHeight / size,
        letterSpacing: letterSpacing,
      ).merge(style),
    );

    return headingLevel == null
        ? text
        : Semantics(headingLevel: headingLevel, child: text);
  }
}
