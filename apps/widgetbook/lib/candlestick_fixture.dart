import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class CandlestickFixture extends StatefulWidget {
  const CandlestickFixture({
    this.showTableButton = true,
    this.tableButtonLabel = 'Show data table',
    this.tableTitle = 'Daily prices',
    super.key,
  });
  final bool showTableButton;
  final String tableButtonLabel;
  final String tableTitle;
  @override
  State<CandlestickFixture> createState() => _CandlestickFixtureState();
}

class _CandlestickFixtureState extends State<CandlestickFixture> {
  late final _data = rootBundle
      .loadString('fixtures/chart-candlestick.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);
  String? _selected;
  void _showTable(List<String> categories, List<KChartCandle> candles) {
    KDialog.show<void>(
      context: context,
      title: KText(widget.tableTitle),
      child: KTable(
        label: widget.tableTitle,
        columns: const [
          KTableColumn(id: 'date', header: KText('Date')),
          KTableColumn(id: 'open', header: KText('Open')),
          KTableColumn(id: 'high', header: KText('High')),
          KTableColumn(id: 'low', header: KText('Low')),
          KTableColumn(id: 'close', header: KText('Close')),
          KTableColumn(id: 'volume', header: KText('Volume')),
        ],
        rows: [
          for (final c in candles)
            KTableRow(
              id: c.id,
              cells: [
                KText(categories[c.x.toInt()]),
                KText(c.open.toStringAsFixed(0)),
                KText(c.high.toStringAsFixed(0)),
                KText(c.low.toStringAsFixed(0)),
                KText(c.close.toStringAsFixed(0)),
                KText(c.volume?.toStringAsFixed(0) ?? '—'),
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
                final candles = [
                  for (final c in data['candles'] as List)
                    KChartCandle(
                      id: c['id'] as String,
                      x: (c['x'] as num).toDouble(),
                      open: (c['open'] as num).toDouble(),
                      high: (c['high'] as num).toDouble(),
                      low: (c['low'] as num).toDouble(),
                      close: (c['close'] as num).toDouble(),
                      volume: (c['volume'] as num).toDouble(),
                    ),
                ];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KText(
                      'Demo market data',
                      variant: KTextVariant.bodySmall,
                      style: TextStyle(color: t.colorTextMuted),
                    ),
                    SizedBox(height: t.spaceControlGap),
                    KText(
                      data['title'] as String,
                      variant: KTextVariant.heading3,
                    ),
                    SizedBox(height: t.spaceControlGap),
                    KText(
                      data['description'] as String,
                      variant: KTextVariant.bodySmall,
                      style: TextStyle(color: t.colorTextMuted),
                    ),
                    SizedBox(height: t.spaceContentActionGap),
                    KCandlestickChart(
                      data: candles,
                      label: data['title'] as String,
                      description: data['description'] as String,
                      xAxis: KChartAxis(
                        min: -0.5,
                        max: 7.5,
                        ticks: const [0, 2, 4, 6],
                        format: (x) => x >= 0 && x < categories.length
                            ? categories[x.toInt()]
                            : '',
                      ),
                      yAxis: KChartAxis(
                        min: 90,
                        max: 120,
                        ticks: const [90, 100, 110, 120],
                        format: (y) => y.toStringAsFixed(0),
                      ),
                      selectedId: _selected,
                      onSelectionChange: (value) =>
                          setState(() => _selected = value),
                    ),
                    if (widget.showTableButton) ...[
                      SizedBox(height: t.spaceContentActionGap),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: KButton(
                          label: widget.tableButtonLabel,
                          variant: KButtonVariant.ghost,
                          onPressed: () => _showTable(categories, candles),
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
