import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_text.dart';
import 'k_chart_types.dart';
import 'k_candle_types.dart';

class KCandlePlot extends StatelessWidget {
  const KCandlePlot({
    required this.data,
    required this.xAxis,
    required this.yAxis,
    this.activeX,
    super.key,
  });
  final List<KChartCandle> data;
  final KChartAxis xAxis, yAxis;
  final double? activeX;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(
          1.0,
          constraints.maxWidth -
              t.componentChartInsetLeft -
              t.componentChartInsetRight,
        );
        final height = math.max(
          1.0,
          constraints.maxHeight -
              t.componentChartInsetTop -
              t.componentChartInsetBottom,
        );
        final xs = data.map((p) => p.x).toSet().toList()..sort();
        var span = xAxis.max - xAxis.min;
        for (var i = 1; i < xs.length; i++) {
          span = math.min(span, xs[i] - xs[i - 1]);
        }
        final painter = KCandlePainter(
          width: .72 * span / (xAxis.max - xAxis.min) * width,
          stroke: t.componentChartLineWidth,
          up: t.colorStatusSuccessAccent,
          down: t.colorStatusErrorAccent,
          neutral: t.colorTextMuted,
        );
        return Stack(
          children: [
            for (final tick in yAxis.ticks.where(
              (v) => v >= yAxis.min && v <= yAxis.max,
            ))
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
                  style: TextStyle(color: t.colorTextMuted),
                ),
              ),
            for (final tick in xAxis.ticks.where(
              (v) => v >= xAxis.min && v <= xAxis.max,
            ))
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
                      tick == xAxis.min
                          ? 0
                          : tick == xAxis.max
                          ? -1
                          : -.5,
                      0,
                    ),
                    child: KText(
                      xAxis.format(tick),
                      variant: KTextVariant.bodySmall,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(color: t.colorTextMuted),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: t.componentChartInsetLeft,
              top: t.componentChartInsetTop,
              width: width,
              height: height,
              child: ClipRect(
                child: Stack(
                  children: [
                    for (final tick in yAxis.ticks.where(
                      (v) => v >= yAxis.min && v <= yAxis.max,
                    ))
                      Positioned(
                        left: 0,
                        right: 0,
                        top: (1 - yAxis.fraction(tick)) * height,
                        child: Container(
                          height: t.borderWidthDefault,
                          color: t.componentChartGridColor,
                        ),
                      ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CandlestickChart(
                          CandlestickChartData(
                            minX: xAxis.min,
                            maxX: xAxis.max,
                            minY: yAxis.min,
                            maxY: yAxis.max,
                            candlestickSpots: [
                              for (final c in data)
                                CandlestickSpot(
                                  x: c.x,
                                  open: c.open,
                                  high: c.high,
                                  low: c.low,
                                  close: c.close,
                                ),
                            ],
                            candlestickPainter: painter,
                            titlesData: const FlTitlesData(show: false),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            clipData: const FlClipData.all(),
                            candlestickTouchData: CandlestickTouchData(
                              enabled: false,
                            ),
                          ),
                          duration: Duration.zero,
                        ),
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
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Native fl_chart painter with a minimum visible body height, including Doji.
class KCandlePainter extends FlCandlestickPainter {
  const KCandlePainter({
    required this.width,
    required this.stroke,
    required this.up,
    required this.down,
    required this.neutral,
  });
  final double width, stroke;
  final Color up, down, neutral;
  @override
  Color getMainColor({required CandlestickSpot spot, required int spotIndex}) =>
      spot.close > spot.open
      ? up
      : spot.close < spot.open
      ? down
      : neutral;
  @override
  void paint(
    Canvas canvas,
    ValueInCanvasProvider xInCanvasProvider,
    ValueInCanvasProvider yInCanvasProvider,
    CandlestickSpot spot,
    int spotIndex,
  ) {
    final x = xInCanvasProvider(spot.x),
        a = yInCanvasProvider(spot.open),
        b = yInCanvasProvider(spot.close);
    final color = getMainColor(spot: spot, spotIndex: spotIndex);
    canvas.drawLine(
      Offset(x, yInCanvasProvider(spot.high)),
      Offset(x, yInCanvasProvider(spot.low)),
      Paint()
        ..color = color
        ..strokeWidth = stroke,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x, (a + b) / 2),
        width: width,
        height: math.max(stroke, (a - b).abs()),
      ),
      Paint()..color = color,
    );
  }

  @override
  FlCandlestickPainter lerp(
    FlCandlestickPainter a,
    FlCandlestickPainter b,
    double t,
  ) => b;
  @override
  List<Object?> get props => [width, stroke, up, down, neutral];
}
