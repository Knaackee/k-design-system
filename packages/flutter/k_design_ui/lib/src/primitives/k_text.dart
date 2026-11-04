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

enum KTextWrap { wrap, balance }

class KText extends StatelessWidget {
  const KText(
    this.data, {
    this.variant = KTextVariant.body,
    this.align,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.style,
    this.textWrap = KTextWrap.wrap,
    super.key,
  });

  final String data;
  final KTextVariant variant;
  final TextAlign? align;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextStyle? style;
  final KTextWrap textWrap;

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

    // Decision 0010: headings grow less than body text under system scaling.
    final scaler = MediaQuery.textScalerOf(context).clamp(
      maxScaleFactor: headingLevel == null
          ? tokens.textScaleMaxBody
          : tokens.textScaleMaxHeading,
    );
    final text = Text(
      data,
      textScaler: scaler,
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
          FontVariation.weight((style?.fontWeight ?? weight).value.toDouble()),
          FontVariation.opticalSize(
            scaler.scale(style?.fontSize ?? size).clamp(14, 32),
          ),
        ],
        height: lineHeight / size,
        letterSpacing: letterSpacing,
      ).merge(style),
    );

    final Widget content = textWrap == KTextWrap.balance
        ? _BalancedText(text: text)
        : text;
    return headingLevel == null
        ? content
        : Semantics(headingLevel: headingLevel, child: content);
  }
}

// Keep the natural line count, then find the narrowest fitting paragraph.
// This is intentionally bounded to headings/short paragraphs, not body layouts.
class _BalancedText extends StatelessWidget {
  const _BalancedText({required this.text});
  final Text text;

  @override
  Widget build(BuildContext context) {
    final defaults = DefaultTextStyle.of(context);
    final direction = Directionality.of(context);
    final alignment = text.textAlign ?? defaults.textAlign ?? TextAlign.start;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth ||
            constraints.maxWidth <= 0 ||
            text.data!.contains('\n') ||
            !(text.softWrap ?? defaults.softWrap)) {
          return text;
        }
        var effectiveStyle = text.style == null || text.style!.inherit
            ? defaults.style.merge(text.style)
            : text.style!;
        if (MediaQuery.boldTextOf(context)) {
          effectiveStyle = effectiveStyle.merge(
            const TextStyle(fontWeight: FontWeight.bold),
          );
        }
        final painter = TextPainter(
          text: TextSpan(text: text.data, style: effectiveStyle),
          textDirection: direction,
          textAlign: alignment,
          textScaler: text.textScaler ?? MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
          textHeightBehavior: defaults.textHeightBehavior,
          maxLines: text.maxLines ?? defaults.maxLines,
          ellipsis:
              (text.overflow ?? defaults.overflow) == TextOverflow.ellipsis
              ? '\u2026'
              : null,
        );
        double width = constraints.maxWidth;
        try {
          painter.layout(maxWidth: width);
          final lines = painter.computeLineMetrics().length;
          if (painter.didExceedMaxLines || lines < 2 || lines > 6) return text;
          // Balancing must not introduce a mid-word break for a word that
          // fits at the natural width. Keep the engine's Unicode break rules.
          double lower = painter.minIntrinsicWidth.clamp(0.0, width);
          double upper = width;
          for (
            var iteration = 0;
            iteration < 16 && upper - lower > .25;
            iteration++
          ) {
            final candidate = (lower + upper) / 2;
            painter.layout(maxWidth: candidate);
            final metrics = painter.computeLineMetrics();
            if (!painter.didExceedMaxLines &&
                metrics.length == lines &&
                metrics.every((line) => line.width <= candidate + .01)) {
              upper = candidate;
            } else {
              lower = candidate;
            }
          }
          width = upper;
        } finally {
          painter.dispose();
        }
        final resolved = switch (alignment) {
          TextAlign.center => Alignment.center,
          TextAlign.right => Alignment.centerRight,
          TextAlign.left => Alignment.centerLeft,
          TextAlign.end =>
            direction == TextDirection.ltr
                ? Alignment.centerRight
                : Alignment.centerLeft,
          _ =>
            direction == TextDirection.ltr
                ? Alignment.centerLeft
                : Alignment.centerRight,
        };
        return Align(
          alignment: resolved,
          heightFactor: 1,
          child: SizedBox(width: width, child: text),
        );
      },
    );
  }
}
