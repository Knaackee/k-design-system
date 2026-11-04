import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/management_overview_fixture.dart';

void main() {
  for (final width in [390.0, 1024.0, 1360.0]) {
    for (final brightness in Brightness.values) {
      testWidgets('management fits $width $brightness including long labels', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 760);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(brightness: brightness),
            home: const ManagementOverviewFixture(longLabels: true),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final customer = find.byWidgetPredicate(
          (w) => w is KButton && w.label.startsWith('Kund:innen'),
        );
        await tester.tap(customer.first);
        await tester.pumpAndSettle();
        expect(find.text('Zurück zur Verwaltung'), findsOneWidget);
        await tester.tap(find.text('Zurück zur Verwaltung'));
        await tester.pumpAndSettle();
        expect(find.text('Deine Buchungsseite ist online'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
