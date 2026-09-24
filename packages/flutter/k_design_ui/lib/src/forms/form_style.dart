import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

KDesignTokens formTokens(BuildContext context) =>
    Theme.of(context).extension<KDesignTokens>() ?? KDesignTokens.orbitLight;

TextStyle formTextStyle(BuildContext context, {Color? color}) {
  final t = formTokens(context);
  final scaled = MediaQuery.textScalerOf(context).scale(t.fontControlSize);
  return TextStyle(
    fontFamily: t.fontFamily,
    fontSize: t.fontControlSize,
    fontWeight: t.fontControlWeight,
    height: t.fontTightHeight,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: -.01 * scaled,
    color: color ?? t.colorTextPrimary,
    fontVariations: [
      FontVariation.weight(t.fontControlWeight.value.toDouble()),
      FontVariation.opticalSize(scaled.clamp(14, 32)),
    ],
  );
}

InputDecoration formDecoration(
  BuildContext context, {
  String? placeholder,
  bool invalid = false,
  Widget? prefix,
  Widget? suffix,
}) {
  final t = formTokens(context);
  final scaled = MediaQuery.textScalerOf(context).scale(t.fontControlSize);
  // Chromium's native inputs center the rounded font bounding box. Flutter's
  // editable uses the strut ascent and rounds the paragraph's line height.
  // Native inputs snap their local baseline to logical pixels; field labels use
  // the same shared pixel grid. Measure fonts instead of scale-specific offsets.
  final style = formTextStyle(context).copyWith(inherit: false);
  final line = TextPainter(
    text: TextSpan(text: ' ', style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final natural = TextPainter(
    text: TextSpan(
      text: ' ',
      style: style.copyWith(height: kTextHeightNone),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final lineMetrics = line.computeLineMetrics().single;
  final fontMetrics = natural.computeLineMetrics().single;
  final lineHeight = line.height;
  final controlHeight = math.max(t.sizeControl, scaled + 2);
  final nativeBaseline =
      (controlHeight / 2 +
              (fontMetrics.ascent.round() - fontMetrics.descent.round()) / 2)
          .roundToDouble();
  final baselineAdjustment =
      nativeBaseline - ((controlHeight - lineHeight) / 2 + lineMetrics.ascent);
  final padding = math.max(0.0, (controlHeight - lineHeight) / 2);
  line.dispose();
  natural.dispose();
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    gapPadding: 0,
    borderRadius: BorderRadius.circular(t.radiusControl),
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    isDense: true,
    visualDensity: VisualDensity.standard,
    filled: true,
    hoverColor: Colors.transparent,
    focusColor: Colors.transparent,
    fillColor: t.colorSurfaceRaised,
    hint: placeholder == null
        ? null
        : ExcludeSemantics(
            child: Text(
              placeholder,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: formTextStyle(context, color: t.colorTextMuted),
              strutStyle: StrutStyle.fromTextStyle(
                formTextStyle(context),
                forceStrutHeight: true,
              ),
            ),
          ),
    hintStyle: formTextStyle(context, color: t.colorTextMuted),
    contentPadding: EdgeInsets.fromLTRB(
      t.spaceControlInsetInline + 1,
      math.max(0, padding + baselineAdjustment),
      t.spaceControlInsetInline + 1,
      math.max(0, padding - baselineAdjustment),
    ),
    constraints: BoxConstraints(minHeight: t.sizeControl),
    border: border(t.colorBorderDefault),
    enabledBorder: border(
      invalid ? t.colorStatusErrorBorder : t.colorBorderDefault,
    ),
    disabledBorder: border(t.colorBorderDefault),
    focusedBorder: border(
      invalid ? t.colorStatusErrorBorder : t.colorBorderFocus,
    ),
    prefixIcon: prefix,
    suffixIcon: suffix,
    prefixIconConstraints: const BoxConstraints(),
    suffixIconConstraints: const BoxConstraints(),
  );
}

// Outline alignment clamps top/bottom against the centered baseline. Choose the
// side of the measured padding adjustment so that it is not clamped away.
TextAlignVertical formInputAlignment(InputDecoration decoration) {
  final padding = decoration.contentPadding! as EdgeInsets;
  return padding.top >= padding.bottom
      ? TextAlignVertical.bottom
      : TextAlignVertical.top;
}
