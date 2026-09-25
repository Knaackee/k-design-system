import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/candlestick_fixture.dart';

void main() {
  testWidgets(
    'candlestick fixture renders eight candles and opens its modal table',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: const Scaffold(body: CandlestickFixture()),
        ),
      );
      await tester.runAsync(() async {
        await rootBundle.loadString('fixtures/chart-candlestick.json');
      });
      await tester.pumpAndSettle();
      final chart = tester.widget<KCandlestickChart>(
        find.byType(KCandlestickChart),
      );
      expect(chart.data.length, 8);
      expect(chart.data.where((c) => c.open == c.close).length, 1);
      chart.onSelectionChange!('day-2');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<KCandlestickChart>(find.byType(KCandlestickChart))
            .selectedId,
        'day-2',
      );
      await tester.tap(find.text('Show data table'));
      await tester.pumpAndSettle();
      expect(find.byType(KDialog), findsOneWidget);
      final table = tester.widget<KTable>(find.byType(KTable));
      expect(table.rows.length, 8);
      expect(table.columns.length, 6);
      Navigator.of(tester.element(find.byType(KTable))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(KDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
