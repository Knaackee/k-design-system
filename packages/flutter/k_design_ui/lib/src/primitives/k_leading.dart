import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'k_icon.dart';
import 'k_text.dart';

/// Places a leading visual (icon, checkbox, avatar dot) on the optical centre
/// of the *first line* of the adjacent text, never on the centre of a
/// multi-line block (Decision 0010).
///
/// Use inside a `Row(crossAxisAlignment: CrossAxisAlignment.start)`. The
/// offset follows the text role's line height and the capped system text
/// scale, so alignment survives larger type.
class KLeading extends StatelessWidget {
  const KLeading({
    required this.child,
    this.size = 16,
    this.textVariant = KTextVariant.body,
    super.key,
  });

  /// Convenience for the common icon case.
  KLeading.icon(
    KIconName name, {
    this.size = 16,
    this.textVariant = KTextVariant.body,
    Color? color,
    super.key,
  }) : child = KIcon(name, size: size, color: color);

  final Widget child;

  /// Rendered height of [child] in logical pixels.
  final double size;

  /// Role of the text whose first line the child aligns to.
  final KTextVariant textVariant;

  /// Top offset that centres an item of [size] on the first line of
  /// [textVariant] text.
  static double offsetFor(
    BuildContext context, {
    required double size,
    KTextVariant textVariant = KTextVariant.body,
  }) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final (lineHeight, heading) = switch (textVariant) {
      KTextVariant.heading1 => (t.fontHeading1LineHeight, true),
      KTextVariant.heading2 => (t.fontHeading2LineHeight, true),
      KTextVariant.heading3 => (t.fontHeading3LineHeight, true),
      KTextVariant.heading4 => (t.fontHeading4LineHeight, true),
      KTextVariant.heading5 => (t.fontHeading5LineHeight, true),
      KTextVariant.heading6 => (t.fontHeading6LineHeight, true),
      KTextVariant.label => (t.fontLabelLineHeight, false),
      KTextVariant.bodySmall => (t.fontBodySmallLineHeight, false),
      KTextVariant.caption => (t.fontCaptionLineHeight, false),
      _ => (t.fontBodyLineHeight, false),
    };
    final scaled = MediaQuery.textScalerOf(context)
        .clamp(
          maxScaleFactor: heading ? t.textScaleMaxHeading : t.textScaleMaxBody,
        )
        .scale(lineHeight);
    return math.max(0, (scaled - size) / 2);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: offsetFor(context, size: size, textVariant: textVariant),
    ),
    child: child,
  );
}
