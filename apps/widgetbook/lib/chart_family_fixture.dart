import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class ChartFamilyFixture extends StatefulWidget {
  const ChartFamilyFixture({
    this.variant = 'bar',
    this.showTableButton = true,
    this.tableButtonLabel = 'Show data table',
    this.tableTitle = 'Data table',
    super.key,
  });
  final String variant;
  final bool showTableButton;
  final String tableButtonLabel;
  final String tableTitle;
  @override
  State<ChartFamilyFixture> createState() => _ChartFamilyFixtureState();
}

class _ChartFamilyFixtureState extends State<ChartFamilyFixture> {
  late final _data = rootBundle
      .loadString('fixtures/chart-families.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);
  KChartSelection? _selection;
  String? _segment;
  List<String>? _visible;
  List<String>? _visibleSegments;

  void _showTable(
    BuildContext context,
    List<String> categories,
    List<KChartSeries> series,
    List<KChartSegment> segments,
    bool circular,
  ) {
    KDialog.show<void>(
      context: context,
      title: KText(widget.tableTitle),
      child: KTable(
        label: widget.tableTitle,
        columns: circular
            ? const [
                KTableColumn(id: 'status', header: KText('Status')),
                KTableColumn(id: 'value', header: KText('Tasks')),
              ]
            : [
                const KTableColumn(id: 'day', header: KText('Day')),
                for (final s in series)
                  KTableColumn(id: s.id, header: KText(s.label)),
              ],
        rows: circular
            ? [
                for (final s in segments)
                  KTableRow(
                    id: s.id,
                    cells: [KText(s.label), KText(s.value.toStringAsFixed(0))],
                  ),
              ]
            : [
                for (var x = 0; x < categories.length; x++)
                  KTableRow(
                    id: categories[x],
                    cells: [
                      KText(categories[x]),
                      for (final s in series)
                        KText(s.points[x].y?.toStringAsFixed(0) ?? '—'),
                    ],
                  ),
              ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(t.spaceLayoutGutter),
        child: KSurface(
          radius: KSurfaceRadius.card,
          child: Padding(
            padding: EdgeInsets.all(t.spaceCardPadding),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _data,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return KText(
                    snapshot.hasError
                        ? 'Fixture unavailable'
                        : 'Loading chart…',
                  );
                }
                final data = snapshot.data!;
                final categories = (data['categories'] as List).cast<String>();
                final series = [
                  for (final raw in data['series'] as List)
                    KChartSeries(
                      id: raw['id'] as String,
                      label: raw['label'] as String,
                      colorIndex: raw['colorIndex'] as int,
                      points: [
                        for (final p in raw['points'] as List)
                          KChartPoint(
                            id: p['id'] as String,
                            x: (p['x'] as num).toDouble(),
                            y: (p['y'] as num).toDouble(),
                          ),
                      ],
                    ),
                ];
                final segments = [
                  for (final raw in data['segments'] as List)
                    KChartSegment(
                      id: raw['id'] as String,
                      label: raw['label'] as String,
                      value: (raw['value'] as num).toDouble(),
                      colorIndex: raw['colorIndex'] as int,
                    ),
                ];
                final circular =
                    widget.variant == 'donut' || widget.variant == 'pie';
                final stacked = widget.variant.endsWith('stacked');
                final title = circular
                    ? 'Task distribution'
                    : 'Workspace activity';
                final xAxis = KChartAxis(
                  min: widget.variant.startsWith('bar') ? -0.5 : 0,
                  max: widget.variant.startsWith('bar') ? 5.5 : 5,
                  ticks: const [0, 1, 2, 3, 4, 5],
                  format: (x) => x >= 0 && x < categories.length
                      ? categories[x.toInt()]
                      : '',
                );
                final yAxis = KChartAxis(
                  min: 0,
                  max: stacked ? 160 : 100,
                  ticks: stacked
                      ? const [0, 40, 80, 120, 160]
                      : const [0, 25, 50, 75, 100],
                  format: (y) => y.toStringAsFixed(0),
                );
                final Widget chart;
                if (circular) {
                  chart = KDonutChart(
                    segments: segments,
                    label: title,
                    selectedId: _segment,
                    onSelectionChange: (value) =>
                        setState(() => _segment = value),
                    visibleSegmentIds: _visibleSegments,
                    onVisibleSegmentsChange: (value) =>
                        setState(() => _visibleSegments = value),
                    formatValue: (value) => value.toStringAsFixed(0),
                    innerRadiusRatio: widget.variant == 'pie' ? 0 : 0.65,
                    centerContent: widget.variant == 'donut'
                        ? const KText('100', variant: KTextVariant.heading3)
                        : null,
                  );
                } else if (widget.variant.startsWith('area')) {
                  chart = KAreaChart(
                    series: series,
                    xAxis: xAxis,
                    yAxis: yAxis,
                    label: title,
                    stacked: stacked,
                    selectedPoint: _selection,
                    onSelectionChange: (value) =>
                        setState(() => _selection = value),
                    visibleSeriesIds: _visible,
                    onVisibleSeriesChange: (value) =>
                        setState(() => _visible = value),
                  );
                } else {
                  chart = KBarChart(
                    series: series,
                    xAxis: xAxis,
                    yAxis: yAxis,
                    label: title,
                    stacked: stacked,
                    orientation: widget.variant == 'bar-horizontal'
                        ? KChartOrientation.horizontal
                        : KChartOrientation.vertical,
                    selectedPoint: _selection,
                    onSelectionChange: (value) =>
                        setState(() => _selection = value),
                    visibleSeriesIds: _visible,
                    onVisibleSeriesChange: (value) =>
                        setState(() => _visible = value),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    KText(
                      'Activity',
                      variant: KTextVariant.bodySmall,
                      style: TextStyle(color: t.colorTextMuted),
                    ),
                    SizedBox(height: t.spaceControlGap),
                    KText(title, variant: KTextVariant.heading3),
                    SizedBox(height: t.spaceControlGap),
                    KText(
                      circular
                          ? 'Tasks by status'
                          : 'Completed and planned tasks · This week',
                      variant: KTextVariant.bodySmall,
                      style: TextStyle(color: t.colorTextMuted),
                    ),
                    SizedBox(height: t.spaceContentActionGap),
                    chart,
                    if (widget.showTableButton) ...[
                      SizedBox(height: t.spaceContentActionGap),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: KButton(
                          label: widget.tableButtonLabel,
                          variant: KButtonVariant.ghost,
                          onPressed: () => _showTable(
                            context,
                            categories,
                            series,
                            segments,
                            circular,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
