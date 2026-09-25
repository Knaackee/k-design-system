import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_text.dart';
import 'k_chart_types.dart';

Color familyColor(KDesignTokens t, int index) => [
  t.componentChartSeriesPrimary,
  t.componentChartSeriesSecondary,
  t.colorStatusSuccessAccent,
  t.colorStatusWarningAccent,
  t.colorStatusInfoAccent,
  t.colorStatusErrorAccent,
][index.abs() % 6];

double familyValue(
  List<KChartSeries> series,
  KChartSeries current,
  KChartPoint point,
  bool stacked,
) {
  var value = point.y ?? 0;
  if (!stacked) return value;
  for (final s in series) {
    if (s.id == current.id) break;
    for (final p in s.points.where(
      (p) => p.x == point.x && p.y != null && p.y!.isFinite,
    )) {
      if ((p.y! >= 0) == (value >= 0)) value += p.y!;
    }
  }
  return value;
}

class KFamilyPlot extends StatelessWidget {
  const KFamilyPlot({
    required this.series,
    required this.xAxis,
    required this.yAxis,
    required this.activeX,
    required this.area,
    required this.stacked,
    required this.orientation,
    super.key,
  });
  final List<KChartSeries> series;
  final KChartAxis xAxis, yAxis;
  final double? activeX;
  final bool area, stacked;
  final KChartOrientation orientation;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final horizontal = orientation == KChartOrientation.horizontal;
    return LayoutBuilder(
      builder: (context, c) {
        final w = math.max(
          1.0,
          c.maxWidth - t.componentChartInsetLeft - t.componentChartInsetRight,
        );
        final h = math.max(
          1.0,
          c.maxHeight - t.componentChartInsetTop - t.componentChartInsetBottom,
        );
        final xs =
            series
                .expand((s) => s.points)
                .where(
                  (p) => p.x.isFinite && p.x >= xAxis.min && p.x <= xAxis.max,
                )
                .map((p) => p.x)
                .toSet()
                .toList()
              ..sort();
        var spacing = xAxis.max - xAxis.min;
        for (var i = 1; i < xs.length; i++) {
          spacing = math.min(spacing, xs[i] - xs[i - 1]);
        }
        final band =
            .72 * spacing / (xAxis.max - xAxis.min) * (horizontal ? h : w);
        Widget label(String text) => KText(
          text,
          variant: KTextVariant.bodySmall,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(color: t.colorTextMuted),
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final tick in (horizontal ? xAxis : yAxis).ticks)
              Positioned(
                left: 0,
                top:
                    t.componentChartInsetTop +
                    (horizontal
                            ? xAxis.fraction(tick)
                            : 1 - yAxis.fraction(tick)) *
                        h -
                    t.fontBodySmallLineHeight / 2,
                width: t.componentChartInsetLeft - t.spaceControlGap,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: label((horizontal ? xAxis : yAxis).format(tick)),
                ),
              ),
            for (final tick in (horizontal ? yAxis : xAxis).ticks)
              Positioned(
                left: 0,
                top: t.componentChartInsetTop + h + t.spaceControlGap,
                child: Transform.translate(
                  offset: Offset(
                    t.componentChartInsetLeft +
                        (horizontal ? yAxis : xAxis).fraction(tick) * w,
                    0,
                  ),
                  child: FractionalTranslation(
                    translation: Offset(
                      tick == (horizontal ? yAxis : xAxis).min
                          ? 0
                          : tick == (horizontal ? yAxis : xAxis).max
                          ? -1
                          : -.5,
                      0,
                    ),
                    child: label((horizontal ? yAxis : xAxis).format(tick)),
                  ),
                ),
              ),
            Positioned(
              left: t.componentChartInsetLeft,
              top: t.componentChartInsetTop,
              width: w,
              height: h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final tick in yAxis.ticks)
                    if (horizontal)
                      Positioned(
                        left: yAxis.fraction(tick) * w,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: t.borderWidthDefault,
                          color: t.componentChartGridColor,
                        ),
                      )
                    else
                      Positioned(
                        left: 0,
                        right: 0,
                        top: (1 - yAxis.fraction(tick)) * h,
                        child: Container(
                          height: t.borderWidthDefault,
                          color: t.componentChartGridColor,
                        ),
                      ),
                  Positioned.fill(
                    child: ClipRect(
                      child: IgnorePointer(
                        child: area
                            ? _area(context, t)
                            : Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  for (final x in xs)
                                    if (horizontal)
                                      Positioned(
                                        left: 0,
                                        top: xAxis.fraction(x) * h - band / 2,
                                        width: w,
                                        height: band,
                                        child: RotatedBox(
                                          quarterTurns: 1,
                                          child: _bar(context, t, x, band),
                                        ),
                                      )
                                    else
                                      Positioned(
                                        left: xAxis.fraction(x) * w - band / 2,
                                        top: 0,
                                        width: band,
                                        height: h,
                                        child: _bar(context, t, x, band),
                                      ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  if (activeX != null)
                    if (horizontal)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: xAxis.fraction(activeX!) * h,
                        child: IgnorePointer(
                          child: Container(
                            height: t.borderWidthDefault,
                            color: t.colorBorderStrong,
                          ),
                        ),
                      )
                    else
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: xAxis.fraction(activeX!) * w,
                        child: IgnorePointer(
                          child: Container(
                            width: t.borderWidthDefault,
                            color: t.colorBorderStrong,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bar(BuildContext context, KDesignTokens t, double x, double band) {
    final entries = <(KChartSeries, KChartPoint)>[
      for (final s in series)
        for (final p in s.points.where(
          (p) => p.x == x && p.y != null && p.y!.isFinite,
        ))
          (s, p),
    ];
    final rods = <BarChartRodData>[];
    if (stacked) {
      var positive = 0.0, negative = 0.0;
      final pieces = <BarChartRodStackItem>[];
      for (final (s, p) in entries) {
        final start = p.y! >= 0 ? positive : negative;
        final end = start + p.y!;
        pieces.add(
          BarChartRodStackItem(
            math.min(start, end),
            math.max(start, end),
            familyColor(t, s.colorIndex),
          ),
        );
        if (p.y! >= 0) {
          positive = end;
        } else {
          negative = end;
        }
      }
      rods.add(
        BarChartRodData(
          fromY: negative,
          toY: positive,
          width: band,
          borderRadius: BorderRadius.zero,
          rodStackItems: pieces,
        ),
      );
    } else {
      for (final s in series) {
        final p = entries.where((entry) => entry.$1.id == s.id).firstOrNull?.$2;
        rods.add(
          BarChartRodData(
            fromY: 0,
            toY: p?.y ?? 0,
            width: band / math.max(1, series.length),
            color: familyColor(t, s.colorIndex),
            borderRadius: BorderRadius.zero,
          ),
        );
      }
    }
    return BarChart(
      BarChartData(
        minY: yAxis.min,
        maxY: yAxis.max,
        alignment: BarChartAlignment.center,
        barGroups: [BarChartGroupData(x: 0, barRods: rods, barsSpace: 0)],
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: const BarTouchData(enabled: false),
      ),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : t.motionFast,
    );
  }

  Widget _area(BuildContext context, KDesignTokens t) {
    final lines = <LineChartBarData>[];
    final fills = <BetweenBarsData>[];
    for (final s in series) {
      final points = List<KChartPoint>.of(s.points)
        ..sort((a, b) => a.x.compareTo(b.x));
      final color = familyColor(t, s.colorIndex);
      if (stacked) {
        final base = lines.length;
        lines.add(
          LineChartBarData(
            spots: [
              for (final p in points)
                p.y == null || !p.y!.isFinite || !p.x.isFinite
                    ? FlSpot.nullSpot
                    : FlSpot(p.x, familyValue(series, s, p, true) - p.y!),
            ],
            barWidth: 0,
            color: Colors.transparent,
            dotData: const FlDotData(show: false),
          ),
        );
        lines.add(
          LineChartBarData(
            spots: [
              for (final p in points)
                p.y == null || !p.y!.isFinite || !p.x.isFinite
                    ? FlSpot.nullSpot
                    : FlSpot(p.x, familyValue(series, s, p, true)),
            ],
            barWidth: t.componentChartLineWidth,
            color: color,
            dotData: const FlDotData(show: false),
          ),
        );
        fills.add(
          BetweenBarsData(
            fromIndex: base,
            toIndex: base + 1,
            color: color.withValues(alpha: t.opacityMedium),
          ),
        );
      } else {
        lines.add(
          LineChartBarData(
            spots: [
              for (final p in points)
                p.y == null || !p.y!.isFinite || !p.x.isFinite
                    ? FlSpot.nullSpot
                    : FlSpot(p.x, p.y!),
            ],
            barWidth: t.componentChartLineWidth,
            color: color,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: t.opacityMedium),
              cutOffY: 0,
              applyCutOffY: true,
            ),
            aboveBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: t.opacityMedium),
              cutOffY: 0,
              applyCutOffY: true,
            ),
          ),
        );
      }
    }
    return LineChart(
      LineChartData(
        minX: xAxis.min,
        maxX: xAxis.max,
        minY: yAxis.min,
        maxY: yAxis.max,
        lineBarsData: lines,
        betweenBarsData: fills,
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        clipData: const FlClipData.all(),
        lineTouchData: const LineTouchData(enabled: false),
      ),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : t.motionFast,
    );
  }
}
