import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  final x = KChartAxis(
    min: 0,
    max: 2,
    ticks: [0, 1, 2],
    format: (v) => 'Day ${v.toInt()}',
  );
  final y = KChartAxis(
    min: -10,
    max: 10,
    ticks: [-10, 0, 10],
    format: (v) => '${v.toInt()}',
  );
  final series = [
    KChartSeries(
      id: 'a',
      label: 'Completed',
      points: const [
        KChartPoint(id: 'one', x: 0, y: -5),
        KChartPoint(id: 'two', x: 1, y: null),
        KChartPoint(id: 'three', x: 2, y: 8),
      ],
    ),
    KChartSeries(
      id: 'b',
      label: 'Planned',
      colorIndex: 1,
      points: const [
        KChartPoint(id: 'one', x: 0, y: 0),
        KChartPoint(id: 'two', x: 1, y: 3),
        KChartPoint(id: 'three', x: 2, y: 6),
      ],
    ),
  ];
  Future<void> mount(
    WidgetTester tester,
    Widget chart, {
    KDensity density = KDensity.standard,
    double width = 320,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: kDesignTheme(
        configuration: KDesignConfiguration(density: density),
      ),
      home: Scaffold(
        body: Column(
          children: [
            SizedBox(width: width, child: chart),
            const Text('Outside'),
          ],
        ),
      ),
    ),
  );
  KLineChart chart({
    KChartSelection? selected,
    ValueChanged<KChartSelection?>? change,
    List<String>? visible,
    ValueChanged<List<String>>? visibility,
    bool table = false,
    List<KChartSeries>? data,
  }) => KLineChart(
    series: data ?? series,
    xAxis: x,
    yAxis: y,
    label: 'Activity',
    selectedPoint: selected,
    onSelectionChange: change,
    visibleSeriesIds: visible,
    onVisibleSeriesChange: visibility,
    showDataTable: table,
  );

  testWidgets('keyboard commits stable IDs, skips gaps and Escape clears', (
    tester,
  ) async {
    KChartSelection? selected;
    final calls = <KChartSelection?>[];
    await mount(
      tester,
      StatefulBuilder(
        builder: (_, setState) => chart(
          selected: selected,
          change: (value) {
            calls.add(value);
            setState(() => selected = value);
          },
        ),
      ),
    );
    final plot = find.byType(LineChart);
    await tester.tapAt(tester.getTopLeft(plot) + const Offset(1, 155));
    await tester.pumpAndSettle();
    expect(calls.last, const KChartSelection(seriesId: 'a', pointId: 'one'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(calls.last, const KChartSelection(seriesId: 'a', pointId: 'three'));
    expect(find.text('8'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(calls, hasLength(3));
    expect(calls.last, isNull);
    expect(find.text('8'), findsNothing);
  });
  testWidgets('selection and legend remain controlled and outside dismisses', (
    tester,
  ) async {
    final calls = <KChartSelection?>[];
    final visibility = <List<String>>[];
    await mount(
      tester,
      chart(
        selected: const KChartSelection(seriesId: 'a', pointId: 'one'),
        change: calls.add,
        visibility: visibility.add,
      ),
    );
    await tester.tap(find.widgetWithText(KButton, 'Completed'));
    await tester.pumpAndSettle();
    expect(visibility.single, ['b']);
    expect(
      tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData.length,
      2,
    );
    await tester.tap(find.text('Outside'));
    expect(calls.single, isNull);
    expect(find.text('-5'), findsOneWidget);
    await mount(tester, chart());
    expect(find.text('-5'), findsNothing);
  });
  testWidgets(
    'gap and negative values survive mapping; stale data selection disappears',
    (tester) async {
      await mount(
        tester,
        chart(
          selected: const KChartSelection(seriesId: 'a', pointId: 'one'),
        ),
      );
      final plot = tester.widget<LineChart>(find.byType(LineChart));
      expect(plot.data.lineBarsData.first.spots[1], FlSpot.nullSpot);
      expect(plot.data.lineBarsData.first.spots.first.y, -5);
      await mount(
        tester,
        chart(
          data: [],
          selected: const KChartSelection(seriesId: 'a', pointId: 'one'),
        ),
      );
      expect(find.text('No data to display'), findsOneWidget);
      expect(find.text('-5'), findsNothing);
      await mount(tester, chart(visible: []));
      expect(find.text('No data to display'), findsOneWidget);
    },
  );
  testWidgets(
    'table includes missing values and thousand points use one plot',
    (tester) async {
      await mount(tester, chart(table: true));
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      await mount(
        tester,
        chart(
          data: [
            KChartSeries(
              id: 'large',
              label: 'Large',
              points: List.generate(
                1000,
                (i) =>
                    KChartPoint(id: '$i', x: i / 500, y: (i % 10).toDouble()),
              ),
            ),
          ],
        ),
      );
      expect(find.byType(LineChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final density in KDensity.values) {
    for (final width in [375.0, 768.0, 1280.0]) {
      testWidgets('plot geometry $width at ${density.name} density', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(tester, chart(), density: density, width: width);
        final bounds = tester.getRect(find.byType(KLineChart));
        final plot = tester.getRect(find.byType(LineChart));
        expect(plot.left - bounds.left, 40);
        debugPrint(
          'chart geometry width=$width density=${density.name} relativePlot=${plot.shift(-bounds.topLeft)}',
        );
        expect(
          tester.getSize(find.byType(LineChart)),
          Size(
            width - 56,
            256 -
                16 -
                kDesignTokens(
                  configuration: KDesignConfiguration(density: density),
                ).componentChartInsetBottom,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('hover is temporary; Home End and repeated Escape commit once', (
    tester,
  ) async {
    KChartSelection? selected;
    final calls = <KChartSelection?>[];
    await mount(
      tester,
      StatefulBuilder(
        builder: (_, setState) => chart(
          selected: selected,
          change: (value) {
            calls.add(value);
            setState(() => selected = value);
          },
        ),
      ),
    );
    final plot = find.byType(LineChart);
    final point = tester.getTopLeft(plot) + const Offset(1, 155);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(point);
    await tester.pumpAndSettle();
    expect(find.text('-5'), findsOneWidget);
    expect(calls, isEmpty);
    await mouse.moveTo(tester.getCenter(find.text('Outside')));
    await tester.pumpAndSettle();
    expect(find.text('-5'), findsNothing);
    await tester.tapAt(point);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(selected?.pointId, 'three');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(selected?.pointId, 'one');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    final count = calls.length;
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(calls.length, count);
    await mouse.removePointer();
  });
  testWidgets(
    'hidden series stay in table and invalid tooltip rows are omitted',
    (tester) async {
      await mount(tester, chart(table: true, visible: []));
      final table = tester.widget<DataTable>(find.byType(DataTable));
      expect(table.columns, hasLength(3));
      expect(table.rows, hasLength(3));
      await mount(
        tester,
        chart(
          selected: const KChartSelection(seriesId: 'b', pointId: 'two'),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.text('—'), findsNothing);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Planned'), findsNWidgets(2));
    },
  );
  testWidgets('long tooltip labels remain bounded and fully spoken', (
    tester,
  ) async {
    const longLabel =
        'Completed tasks with a deliberately very long descriptive series label';
    final semantics = tester.ensureSemantics();
    await mount(
      tester,
      chart(
        selected: const KChartSelection(seriesId: 'long', pointId: 'one'),
        data: [
          KChartSeries(
            id: 'long',
            label: longLabel,
            points: const [KChartPoint(id: 'one', x: 0, y: 5)],
          ),
        ],
      ),
      width: 240,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final tooltip = find.byType(KSurface);
    expect(tester.getSize(tooltip).width, lessThanOrEqualTo(184));
    expect(find.bySemanticsLabel(longLabel), findsWidgets);
    semantics.dispose();
  });
}
