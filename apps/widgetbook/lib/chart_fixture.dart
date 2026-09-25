import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class ChartFixture extends StatefulWidget {
  const ChartFixture({
    this.scenario = 'reference',
    this.showTableButton = true,
    this.tableButtonLabel = 'Show data table',
    this.tableTitle = 'Data table',
    super.key,
  });
  final bool showTableButton;
  final String tableButtonLabel;
  final String tableTitle;
  final String scenario;
  @override
  State<ChartFixture> createState() => _ChartFixtureState();
}

class _ChartFixtureState extends State<ChartFixture> {
  late final _data = rootBundle
      .loadString('fixtures/chart-line-reference.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);
  KChartSelection? _selected;
  List<String>? _visible;
  String _date(double value) =>
      '${DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true).day} Sep';
  KChartAxis _axis(Map<String, dynamic> data, String Function(double) format) =>
      KChartAxis(
        min: (data['min'] as num).toDouble(),
        max: (data['max'] as num).toDouble(),
        ticks: (data['ticks'] as List)
            .map((value) => (value as num).toDouble())
            .toList(),
        format: format,
      );
  void _showTable(BuildContext context, List<KChartSeries> series) {
    final dates =
        series.expand((s) => s.points.map((p) => p.x)).toSet().toList()..sort();
    final values = [
      for (final s in series) {for (final p in s.points) p.x: p.y},
    ];
    KDialog.show<void>(
      context: context,
      title: KText(widget.tableTitle),
      child: KTable(
        label: widget.tableTitle,
        columns: [
          const KTableColumn(id: 'date', header: KText('Date')),
          for (final s in series)
            KTableColumn(id: s.id, header: KText(s.label)),
        ],
        rows: [
          for (final x in dates)
            KTableRow(
              id: x.toString(),
              cells: [
                KText(_date(x)),
                for (final points in values)
                  KText(points[x]?.toStringAsFixed(0) ?? '—'),
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
                var series = (data['series'] as List)
                    .map(
                      (raw) => KChartSeries(
                        id: raw['id'] as String,
                        label: raw['label'] as String,
                        colorIndex: raw['colorIndex'] as int,
                        points: (raw['points'] as List)
                            .map(
                              (p) => KChartPoint(
                                id: p['id'] as String,
                                x: (p['x'] as num).toDouble(),
                                y: (p['y'] as num?)?.toDouble(),
                              ),
                            )
                            .toList(),
                      ),
                    )
                    .toList();
                if (widget.scenario == 'empty') series = [];
                if (widget.scenario == 'gaps') {
                  series = [
                    for (final s in series)
                      KChartSeries(
                        id: s.id,
                        label: s.label,
                        colorIndex: s.colorIndex,
                        points: [
                          for (var i = 0; i < s.points.length; i++)
                            KChartPoint(
                              id: s.points[i].id,
                              x: s.points[i].x,
                              y: i == 5
                                  ? null
                                  : i == 8
                                  ? -10
                                  : s.points[i].y,
                            ),
                        ],
                      ),
                  ];
                }
                if (widget.scenario == 'large') {
                  final axis = data['xAxis'] as Map<String, dynamic>;
                  final min = (axis['min'] as num).toDouble();
                  final max = (axis['max'] as num).toDouble();
                  series = [
                    for (final s in series)
                      KChartSeries(
                        id: s.id,
                        label: s.label,
                        colorIndex: s.colorIndex,
                        points: List.generate(
                          1000,
                          (i) => KChartPoint(
                            id: 'sample-$i',
                            x: min + (max - min) * i / 999,
                            y: 50 + 30 * math.sin(i / 25 + s.colorIndex),
                          ),
                        ),
                      ),
                  ];
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
                    const KText(
                      'Workspace activity',
                      variant: KTextVariant.heading3,
                    ),
                    SizedBox(height: t.spaceControlGap),
                    KText(
                      'Completed and planned tasks · September 2026',
                      variant: KTextVariant.bodySmall,
                      style: TextStyle(color: t.colorTextMuted),
                    ),
                    SizedBox(height: t.spaceContentActionGap),
                    KLineChart(
                      series: series,
                      xAxis: _axis(
                        data['xAxis'] as Map<String, dynamic>,
                        _date,
                      ),
                      yAxis: _axis(
                        widget.scenario == 'gaps'
                            ? {
                                'min': -25,
                                'max': 100,
                                'ticks': [-25, 0, 25, 50, 75, 100],
                              }
                            : data['yAxis'] as Map<String, dynamic>,
                        (value) => value.toStringAsFixed(0),
                      ),
                      label: 'Workspace activity',
                      description:
                          'Use left and right arrow keys to explore values. Escape clears the selection.',
                      selectedPoint: _selected,
                      onSelectionChange: (value) =>
                          setState(() => _selected = value),
                      visibleSeriesIds: _visible,
                      onVisibleSeriesChange: (value) =>
                          setState(() => _visible = value),
                    ),
                    if (widget.showTableButton) ...[
                      SizedBox(height: t.spaceContentActionGap),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: KButton(
                          label: widget.tableButtonLabel,
                          variant: KButtonVariant.ghost,
                          onPressed: () => _showTable(context, series),
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
