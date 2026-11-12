import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

/// Measure the same wrapped prose and action clearance as the existing editor.
double emailDraftBodyHeight(
  BuildContext context,
  String markdown,
  double width, {
  required bool expand,
  required bool toolbar,
}) {
  final t = Theme.of(context).extension<KDesignTokens>()!;
  final painter = TextPainter(
    text: TextSpan(
      text: markdown.isEmpty ? ' ' : markdown,
      style: TextStyle(
        fontFamily: t.fontFamily,
        fontFamilyFallback: const ['sans-serif'],
        fontSize: t.fontControlSize,
        height: t.fontBodySmallLineHeight / t.fontBodySmallSize,
      ),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 3),
  )..layout(maxWidth: math.max(t.sizeContent, width));
  final clearance = expand
      ? math.max(t.sizeHitTarget, t.sizeControl) +
            t.spaceControlGap * 2 +
            t.spaceSmallInset
      : 0;
  final height =
      painter.height +
      t.spaceControlGap * 2 +
      clearance +
      (toolbar
          ? math.max(t.sizeHitTarget, t.sizeControl) +
                t.spaceControlGap * 4 +
                MediaQuery.paddingOf(context).bottom
          : 0);
  painter.dispose();
  final viewport = MediaQuery.sizeOf(context).height;
  return math.max(
    t.sizeHitTarget,
    viewport > 0 ? math.min(height, viewport) : height,
  );
}
