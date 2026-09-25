import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_surface.dart';
import '../primitives/k_text.dart';
import 'k_chart_types.dart';
import 'k_chart_plot.dart';

class KChartTooltip extends StatelessWidget {
  const KChartTooltip({
    required this.series,
    required this.x,
    required this.xAxis,
    required this.yAxis,
    super.key,
  });
  final List<KChartSeries> series;
  final double x;
  final KChartAxis xAxis;
  final KChartAxis yAxis;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      liveRegion: true,
      child: KSurface(
        elevation: KSurfaceElevation.overlay,
        radius: KSurfaceRadius.overlay,
        child: Padding(
          padding: EdgeInsets.all(t.spaceControlInsetInline),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KText(
                  xAxis.format(x),
                  variant: KTextVariant.bodySmall,
                  style: TextStyle(fontWeight: t.fontLabelWeight),
                ),
                for (final s in series)
                  for (final p in s.points.where(
                    (p) =>
                        p.x == x &&
                        p.x.isFinite &&
                        p.x >= xAxis.min &&
                        p.x <= xAxis.max &&
                        p.y != null &&
                        p.y!.isFinite &&
                        p.y! >= yAxis.min &&
                        p.y! <= yAxis.max,
                  ))
                    Padding(
                      padding: EdgeInsets.only(top: t.spaceControlGap),
                      child: Row(
                        children: [
                          Container(
                            width: t.componentChartPointRadius * 2,
                            height: t.componentChartPointRadius * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: chartColor(t, s),
                            ),
                          ),
                          SizedBox(width: t.spaceControlGap),
                          Expanded(
                            child: KText(
                              s.label,
                              variant: KTextVariant.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: t.spaceControlGap),
                          KText(
                            yAxis.format(p.y!),
                            variant: KTextVariant.bodySmall,
                            style: TextStyle(fontWeight: t.fontLabelWeight),
                          ),
                        ],
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

class KChartDataTable extends StatelessWidget {
  const KChartDataTable({
    required this.series,
    required this.xAxis,
    required this.yAxis,
    required this.label,
    required this.xAxisLabel,
    super.key,
  });
  final List<KChartSeries> series;
  final KChartAxis xAxis;
  final KChartAxis yAxis;
  final String label;
  final String xAxisLabel;
  @override
  Widget build(BuildContext context) {
    final xs = series.expand((s) => s.points.map((p) => p.x)).toSet().toList()
      ..sort();
    return Semantics(
      label: label,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(xAxisLabel)),
            for (final s in series) DataColumn(label: Text(s.label)),
          ],
          rows: [
            for (final x in xs)
              DataRow(
                cells: [
                  DataCell(Text(xAxis.format(x))),
                  for (final s in series) DataCell(Text(_value(s, x))),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _value(KChartSeries series, double x) {
    final points = series.points.where((p) => p.x == x);
    final y = points.isEmpty ? null : points.first.y;
    return y == null ? '—' : yAxis.format(y);
  }
}
