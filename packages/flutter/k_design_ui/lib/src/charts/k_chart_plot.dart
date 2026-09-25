import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_text.dart';
import 'k_chart_types.dart';

Color chartColor(KDesignTokens t, KChartSeries series) =>
    series.colorIndex.isEven
    ? t.componentChartSeriesPrimary
    : t.componentChartSeriesSecondary;

class KChartPlot extends StatelessWidget {
  const KChartPlot({
    required this.series,
    required this.xAxis,
    required this.yAxis,
    required this.activeX,
    super.key,
  });
  final List<KChartSeries> series;
  final KChartAxis xAxis;
  final KChartAxis yAxis;
  final double? activeX;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth -
                    t.componentChartInsetLeft -
                    t.componentChartInsetRight)
                .clamp(1.0, double.infinity);
        final height =
            (constraints.maxHeight -
                    t.componentChartInsetTop -
                    t.componentChartInsetBottom)
                .clamp(1.0, double.infinity);
        final style = TextStyle(color: t.colorTextMuted);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (final tick in yAxis.ticks)
              Positioned(
                left: 0,
                top:
                    t.componentChartInsetTop +
                    (1 - yAxis.fraction(tick)) * height -
                    t.fontBodySmallLineHeight / 2,
                width: t.componentChartInsetLeft - t.spaceControlGap,
                child: KText(
                  yAxis.format(tick),
                  variant: KTextVariant.bodySmall,
                  align: TextAlign.right,
                  style: style,
                ),
              ),
            for (final tick in xAxis.ticks)
              Positioned(
                left: 0,
                top: t.componentChartInsetTop + height + t.spaceControlGap,
                child: Transform.translate(
                  offset: Offset(
                    t.componentChartInsetLeft + xAxis.fraction(tick) * width,
                    0,
                  ),
                  child: FractionalTranslation(
                    translation: Offset(
                      tick == xAxis.ticks.first
                          ? 0
                          : tick == xAxis.ticks.last
                          ? -1
                          : -.5,
                      0,
                    ),
                    child: KText(
                      xAxis.format(tick),
                      variant: KTextVariant.bodySmall,
                      maxLines: 1,
                      softWrap: false,
                      style: style,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: t.componentChartInsetLeft,
              top: t.componentChartInsetTop,
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final tick in yAxis.ticks)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: (1 - yAxis.fraction(tick)) * height,
                      child: Container(
                        height: t.borderWidthDefault,
                        color: t.componentChartGridColor,
                      ),
                    ),
                  if (activeX != null)
                    Positioned(
                      left: xAxis.fraction(activeX!) * width,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: t.borderWidthDefault,
                        color: t.colorBorderStrong,
                      ),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: LineChart(
                        LineChartData(
                          minX: xAxis.min,
                          maxX: xAxis.max,
                          minY: yAxis.min,
                          maxY: yAxis.max,
                          titlesData: const FlTitlesData(show: false),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          clipData: const FlClipData.all(),
                          lineTouchData: const LineTouchData(enabled: false),
                          lineBarsData: [
                            for (final s in series)
                              LineChartBarData(
                                spots: [
                                  for (final p in (List<KChartPoint>.of(
                                    s.points,
                                  )..sort((a, b) => a.x.compareTo(b.x))))
                                    p.y == null ||
                                            !p.y!.isFinite ||
                                            !p.x.isFinite
                                        ? FlSpot.nullSpot
                                        : FlSpot(p.x, p.y!),
                                ],
                                color: chartColor(t, s),
                                barWidth: t.componentChartLineWidth,
                                isCurved: false,
                                isStrokeCapRound: false,
                                dotData: FlDotData(
                                  show: true,
                                  checkToShowDot: (spot, _) =>
                                      spot.x == activeX &&
                                      spot.y >= yAxis.min &&
                                      spot.y <= yAxis.max,
                                  getDotPainter: (_, _, _, _) =>
                                      FlDotCirclePainter(
                                        radius: t.componentChartPointRadius,
                                        color: chartColor(t, s),
                                        strokeWidth: t.componentChartLineWidth,
                                        strokeColor: t.colorSurfaceRaised,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : t.motionFast,
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
}
