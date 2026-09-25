import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/charts/k_candle_plot.dart';

void main() {
  final x = KChartAxis(
    min: -.5,
    max: 2.5,
    ticks: [0, 1, 2],
    format: (v) => 'Day ${v.toInt()}',
  );
  final y = KChartAxis(
    min: 0,
    max: 20,
    ticks: [0, 10, 20],
    format: (v) => '\$${v.toInt()}',
  );
  const data = [
    KChartCandle(
      id: 'up',
      x: 0,
      open: 8,
      high: 15,
      low: 5,
      close: 12,
      volume: 100,
    ),
    KChartCandle(id: 'doji', x: 1, open: 10, high: 14, low: 6, close: 10),
    KChartCandle(id: 'down', x: 2, open: 12, high: 16, low: 4, close: 7),
  ];
  Future<void> mount(WidgetTester tester, Widget chart) => tester.pumpWidget(
    MaterialApp(
      theme: kDesignTheme(),
      home: Scaffold(body: SizedBox(width: 375, child: chart)),
    ),
  );
  testWidgets('invalid OHLC excluded and caller input untouched', (
    tester,
  ) async {
    final source = [
      ...data,
      const KChartCandle(id: 'bad', x: 1, open: 10, high: 8, low: 0, close: 9),
      const KChartCandle(
        id: 'nan',
        x: double.nan,
        open: 1,
        high: 2,
        low: 0,
        close: 1,
      ),
    ];
    await mount(
      tester,
      KCandlestickChart(data: source, xAxis: x, yAxis: y, label: 'Price'),
    );
    final chart = tester.widget<CandlestickChart>(
      find.byType(CandlestickChart),
    );
    expect(chart.data.candlestickSpots.length, 3);
    expect(source.length, 5);
    expect(
      chart.data.candlestickSpots[1].open,
      chart.data.candlestickSpots[1].close,
    );
  });
  testWidgets('controlled touch and keyboard selection report stable ids', (
    tester,
  ) async {
    String? selected;
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, set) => KCandlestickChart(
          data: data,
          xAxis: x,
          yAxis: y,
          label: 'Price',
          selectedId: selected,
          onSelectionChange: (id) => set(() => selected = id),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(CandlestickChart));
    await tester.tapAt(Offset(rect.center.dx, rect.center.dy));
    await tester.pump();
    expect(selected, 'doji');
    expect(find.text('Day 1'), findsNWidgets(2));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected, 'down');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(selected, 'up');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(selected, 'down');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(selected, isNull);
  });
  testWidgets(
    'visible range sets domain and filters candles, volume has own formatter',
    (tester) async {
      await mount(
        tester,
        KCandlestickChart(
          data: data,
          xAxis: x,
          yAxis: y,
          label: 'Price',
          visibleRange: const KChartVisibleRange(min: -.25, max: .75),
          selectedId: 'up',
          formatVolume: (v) => '${v.toInt()} units',
        ),
      );
      final chart = tester.widget<CandlestickChart>(
        find.byType(CandlestickChart),
      );
      expect(chart.data.minX, -.25);
      expect(chart.data.maxX, .75);
      expect(chart.data.candlestickSpots.length, 1);
      expect(find.text('100 units'), findsOneWidget);
      expect(find.text('\$8'), findsOneWidget);
    },
  );
  testWidgets('loading and invalid only render supplied content', (
    tester,
  ) async {
    await mount(
      tester,
      KCandlestickChart(
        data: data,
        xAxis: x,
        yAxis: y,
        label: 'Price',
        loading: true,
        loadingContent: const Text('Waiting'),
      ),
    );
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.byType(CandlestickChart), findsNothing);
    await mount(
      tester,
      KCandlestickChart(
        data: const [],
        xAxis: x,
        yAxis: y,
        label: 'Price',
        emptyContent: const Text('Empty'),
      ),
    );
    expect(find.text('Empty'), findsOneWidget);
  });
  test('Doji has a visible horizontal body without modifying OHLC', () async {
    const painter = KCandlePainter(
      width: 20,
      stroke: 2,
      up: Colors.green,
      down: Colors.red,
      neutral: Colors.blue,
    );
    final recorder = ui.PictureRecorder(),
        spot = CandlestickSpot(x: 20, open: 20, high: 10, low: 30, close: 20);
    painter.paint(Canvas(recorder), (v) => v, (v) => v, spot, 0);
    final picture = recorder.endRecording();
    final image = await picture.toImage(40, 40);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(bytes!.getUint8((20 * 40 + 12) * 4 + 3), greaterThan(0));
    expect(spot.open, 20);
    expect(spot.close, 20);
    image.dispose();
    picture.dispose();
  });
  testWidgets('candles and tooltip fit widths and densities', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    for (final width in [375.0, 768.0, 1280.0]) {
      tester.view.physicalSize = Size(width, 900);
      for (final density in KDensity.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(
              configuration: KDesignConfiguration(density: density),
            ),
            home: Scaffold(
              body: SizedBox(
                width: width,
                child: KCandlestickChart(
                  data: data,
                  xAxis: x,
                  yAxis: y,
                  label: 'Price',
                  selectedId: 'up',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$width $density');
      }
    }
  });
}
