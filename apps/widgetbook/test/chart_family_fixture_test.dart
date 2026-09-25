import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/chart_family_fixture.dart';

void main() {
  for (final variant in [
    'bar',
    'bar-horizontal',
    'bar-stacked',
    'area',
    'area-stacked',
    'donut',
    'pie',
  ]) {
    testWidgets('$variant renders canonical data and opens its modal table', (
      tester,
    ) async {
      rootBundle.evict('fixtures/chart-families.json');
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(body: ChartFamilyFixture(variant: variant)),
        ),
      );
      await tester.runAsync(() async {
        await rootBundle.loadString('fixtures/chart-families.json');
      });
      await tester.pumpAndSettle();
      if (variant == 'bar' || variant == 'donut') {
        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();
        final visible = variant == 'bar'
            ? tester.widget<KBarChart>(find.byType(KBarChart)).visibleSeriesIds
            : tester
                  .widget<KDonutChart>(find.byType(KDonutChart))
                  .visibleSegmentIds;
        expect(visible, ['planned']);
        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Show data table'));
      await tester.pumpAndSettle();
      expect(find.byType(KDialog), findsOneWidget);
      final table = tester.widget<KTable>(find.byType(KTable));
      expect(table.rows.length, variant == 'donut' || variant == 'pie' ? 2 : 6);
      Navigator.of(tester.element(find.byType(KTable))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(KDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
