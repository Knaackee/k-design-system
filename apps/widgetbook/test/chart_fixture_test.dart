import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/chart_fixture.dart';

void main() {
  testWidgets('canonical chart asset renders all points and modal table', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: ChartFixture()),
      ),
    );
    await tester.runAsync(() async {
      await rootBundle.loadString('fixtures/chart-line-reference.json');
    });
    await tester.pumpAndSettle();
    expect(find.text('Workspace activity'), findsOneWidget);
    final chart = tester.widget<KLineChart>(find.byType(KLineChart));
    expect(chart.series.map((s) => s.points.length), [14, 14]);
    expect(chart.series.first.points.first.y, 42);
    await tester.tap(find.text('Show data table'));
    await tester.pumpAndSettle();
    expect(find.byType(KDialog), findsOneWidget);
    final table = tester.widget<KTable>(find.byType(KTable));
    expect(table.rows.length, 14);
    expect(chart.showDataTable, isFalse);
    Navigator.of(tester.element(find.byType(KTable))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(KDialog), findsNothing);
    expect(find.byType(KLineChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
