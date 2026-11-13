import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../basic_display.dart';
import '../extended_components.dart' show KProgress;
import '../primitives/k_text.dart';

enum KMetricSentiment { positive, negative, neutral }

class KMetricComparison {
  const KMetricComparison({
    required this.label,
    required this.description,
    required this.sentiment,
  });
  final String label;
  final String description;
  final KMetricSentiment sentiment;
}

class KMetricTrend {
  const KMetricTrend({required this.values, required this.label});
  final List<double?> values;
  final String label;
}

class KMetricProgress {
  const KMetricProgress({
    required this.value,
    required this.label,
    this.max = 100,
  });
  final double value;
  final double max;
  final String label;
}

/// Compact dashboard KPI with isolated layout tokens and shared card corners.
class KMetricCard extends StatelessWidget {
  const KMetricCard({
    required this.label,
    required this.value,
    required this.description,
    this.comparison,
    this.trend,
    this.progress,
    super.key,
  });
  final String label;
  final String value;
  final String description;
  final KMetricComparison? comparison;
  final KMetricTrend? trend;
  final KMetricProgress? progress;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final gap = t.spaceControlGap;
    final validTrend =
        trend != null &&
        trend!.values.whereType<double>().where((v) => v.isFinite).length >= 2;
    final visual = progress != null
        ? Semantics(
            label: progress!.label,
            child: Center(
              child: KProgress(value: progress!.value, max: progress!.max),
            ),
          )
        : validTrend
        ? Semantics(
            image: true,
            label: trend!.label,
            child: CustomPaint(
              painter: _MetricTrendPainter(
                trend!.values,
                t.componentMetricCardTrendColor,
                t.componentChartLineWidth,
              ),
            ),
          )
        : null;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.colorSurfaceRaised,
          borderRadius: BorderRadius.circular(t.componentMetricCardRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(t.spaceCardPadding),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                KText(
                  label,
                  variant: KTextVariant.bodySmall,
                  style: TextStyle(color: t.colorTextMuted),
                ),
                SizedBox(height: gap),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        t.componentBadgeMinHeight +
                        2 * t.componentBadgePaddingBlock +
                        2 * t.borderWidthDefault,
                  ),
                  child: Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      KText(
                        value,
                        variant: KTextVariant.heading2,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: t.componentMetricCardValueSize,
                          height:
                              t.componentMetricCardValueLineHeight /
                              t.componentMetricCardValueSize,
                        ),
                      ),
                      if (comparison case final c?)
                        Semantics(
                          label: '${c.label}: ${c.description}',
                          excludeSemantics: true,
                          child: Tooltip(
                            message: c.description,
                            child: KBadge(
                              variant: switch (c.sentiment) {
                                KMetricSentiment.positive =>
                                  KBadgeVariant.success,
                                KMetricSentiment.negative =>
                                  KBadgeVariant.destructive,
                                KMetricSentiment.neutral =>
                                  KBadgeVariant.secondary,
                              },
                              child: Text(c.label),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: gap),
                SizedBox(
                  height: t.componentMetricCardTrendHeight,
                  child: visual,
                ),
                SizedBox(height: gap),
                const Spacer(),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.textScalerOf(
                          context,
                        ).scale(t.fontBodySmallLineHeight) *
                        2,
                  ),
                  child: KText(
                    description,
                    variant: KTextVariant.bodySmall,
                    style: TextStyle(color: t.colorTextMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTrendPainter extends CustomPainter {
  _MetricTrendPainter(this.values, this.color, this.width);
  final List<double?> values;
  final Color color;
  final double width;
  @override
  void paint(Canvas canvas, Size size) {
    final finite = values.whereType<double>().where((v) => v.isFinite).toList();
    if (finite.length < 2) return;
    final low = finite.reduce(math.min), high = finite.reduce(math.max);
    final path = Path();
    var connected = false;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null || !value.isFinite) {
        connected = false;
        continue;
      }
      // Same normalized viewBox (-1,-2,102,28) as the Web projection.
      final x =
          (1 + i / math.max(values.length - 1, 1) * 100) / 102 * size.width;
      final y =
          (2 + (high == low ? 12 : 24 - (value - low) / (high - low) * 24)) /
          28 *
          size.height;
      if (connected) {
        path.lineTo(x, y);
      } else {
        path.moveTo(x, y);
      }
      connected = true;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MetricTrendPainter old) =>
      old.values != values || old.color != color || old.width != width;
}
