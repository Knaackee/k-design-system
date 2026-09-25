import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  final x = KChartAxis(
    min: -.5,
    max: 1.5,
    ticks: [0, 1],
    format: (v) => 'Day ${v.toInt()}',
  );
  final y = KChartAxis(
    min: -10,
    max: 20,
    ticks: [-10, 0, 10, 20],
    format: (v) => '$v',
  );
  final series = [
    KChartSeries(
      id: 'a',
      label: 'Alpha',
      points: const [
        KChartPoint(id: 'a0', x: 0, y: 5),
        KChartPoint(id: 'a1', x: 1, y: null),
      ],
    ),
    KChartSeries(
      id: 'b',
      label: 'Beta',
      colorIndex: 1,
      points: const [
        KChartPoint(id: 'b0', x: 0, y: 8),
        KChartPoint(id: 'b1', x: 1, y: -4),
      ],
    ),
  ];
  Future<void> mount(WidgetTester tester, Widget chart) => tester.pumpWidget(
    MaterialApp(
      theme: kDesignTheme(),
      home: Scaffold(body: SizedBox(width: 375, child: chart)),
    ),
  );
  testWidgets('grouped bars retain slots when a peer has missing data', (
    tester,
  ) async {
    await mount(
      tester,
      KBarChart(series: series, xAxis: x, yAxis: y, label: 'Bars'),
    );
    final charts = tester.widgetList<BarChart>(find.byType(BarChart)).toList();
    expect(charts.length, 2);
    expect(charts[1].data.barGroups.single.barRods.map((r) => r.toY), [0, -4]);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'stacked bars accumulate positive and negative values separately',
    (tester) async {
      await mount(
        tester,
        KBarChart(
          series: series,
          xAxis: x,
          yAxis: y,
          label: 'Bars',
          stacked: true,
        ),
      );
      final charts = tester
          .widgetList<BarChart>(find.byType(BarChart))
          .toList();
      expect(charts.first.data.barGroups.single.barRods.single.toY, 13);
      expect(charts.last.data.barGroups.single.barRods.single.fromY, -4);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'horizontal bars use existing axis formatters and rotate only plot',
    (tester) async {
      await mount(
        tester,
        KBarChart(
          series: series,
          xAxis: x,
          yAxis: y,
          label: 'Bars',
          orientation: KChartOrientation.horizontal,
        ),
      );
      expect(find.text('Day 0'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is RotatedBox && w.quarterTurns == 1),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('stacked area renders bands and preserves missing samples', (
    tester,
  ) async {
    await mount(
      tester,
      KAreaChart(
        series: series,
        xAxis: x,
        yAxis: y,
        label: 'Area',
        stacked: true,
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.betweenBarsData.length, 2);
    expect(chart.data.lineBarsData[3].spots.first.y, 13);
    expect(chart.data.lineBarsData[1].spots.last, FlSpot.nullSpot);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'bar blank region clears selection and keyboard emits stable ids',
    (tester) async {
      KChartSelection? selected = const KChartSelection(
        seriesId: 'b',
        pointId: 'b1',
      );
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => KBarChart(
            series: series,
            xAxis: x,
            yAxis: y,
            label: 'Bars',
            selectedPoint: selected,
            onSelectionChange: (v) => setState(() => selected = v),
          ),
        ),
      );
      final plot = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Bars',
      );
      await tester.tapAt(tester.getTopLeft(plot) + const Offset(45, 10));
      expect(selected, isNull);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      expect(selected, const KChartSelection(seriesId: 'a', pointId: 'a0'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(selected, isNull);
    },
  );
  testWidgets(
    'donut ignores invalid values, controlled selection and zero hole pie',
    (tester) async {
      String? selected;
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => KDonutChart(
            selectedId: selected,
            label: 'Distribution',
            segments: const [
              KChartSegment(id: 'a', label: 'Alpha', value: 5),
              KChartSegment(id: 'b', label: 'Beta', value: 3),
              KChartSegment(id: 'invalid', label: 'Invalid', value: -2),
            ],
            innerRadiusRatio: 0,
            onSelectionChange: (v) => setState(() => selected = v),
          ),
        ),
      );
      final chart = tester.widget<PieChart>(find.byType(PieChart));
      expect(chart.data.sections.length, 2);
      expect(chart.data.centerSpaceRadius, 0);
      await tester.tapAt(tester.getCenter(find.byType(PieChart)));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      expect(selected, 'b');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(selected, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('hidden series display consumer empty content', (tester) async {
    await mount(
      tester,
      KAreaChart(
        series: series,
        xAxis: x,
        yAxis: y,
        label: 'Area',
        visibleSeriesIds: const [],
        emptyContent: const Text('Nothing selected'),
      ),
    );
    expect(find.text('Nothing selected'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });
  testWidgets('families fit three widths and all density settings', (
    tester,
  ) async {
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());
    tester.view.devicePixelRatio = 1;
    for (final width in [375.0, 768.0, 1280.0]) {
      tester.view.physicalSize = Size(width, 900);
      for (final density in KDensity.values) {
        final theme = kDesignTheme(
          configuration: KDesignConfiguration(density: density),
        );
        final tokens = theme.extension<KDesignTokens>()!;
        final charts = <Widget>[
          KBarChart(series: series, xAxis: x, yAxis: y, label: 'Bars'),
          KAreaChart(
            series: series,
            xAxis: x,
            yAxis: y,
            label: 'Area',
            stacked: true,
          ),
          const KDonutChart(
            label: 'Donut',
            segments: [
              KChartSegment(id: 'one', label: 'First', value: 42),
              KChartSegment(
                id: 'two',
                label: 'Second',
                value: 58,
                colorIndex: 1,
              ),
            ],
          ),
        ];
        for (final chart in charts) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: Scaffold(
                body: SizedBox(width: width, child: chart),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${chart.runtimeType} width=$width density=$density',
          );
          final bounds = tester.getRect(find.byWidget(chart));
          expect(bounds.width, width);
          expect(
            bounds.height,
            greaterThanOrEqualTo(tokens.componentChartHeight),
          );
          expect(bounds.bottom, lessThan(900));
        }
      }
    }
  });
}
