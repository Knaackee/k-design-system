import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/activity_fixture.dart';
import 'package:k_design_widgetbook/activity_fixture_data.dart';

void main() {
  test('Activity fixture data matches Storybook', () {
    expect(activityIssues.length, 140);
    expect(activityIssues.where((i) => i.status == 'done').length, 100);
    expect(activityIssues.first.id, 'ISS-600');
  });
  testWidgets('Phone shows month raster and opens day in bottom sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: ActivityFixture(phone: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Oktober 2026'), findsOneWidget);
    expect(find.textContaining('ISS-'), findsNothing);
    final day = find.byWidgetPredicate(
      (w) =>
          w is Semantics && w.properties.label == '2. Oktober 2026: 0 Issues',
    );
    expect(tester.getSize(day), const Size(44, 44));
    await tester.ensureVisible(day);
    await tester.tap(day);
    await tester.pumpAndSettle();
    expect(find.byType(KBottomSheet), findsOneWidget);
    expect(find.text('Keine Issues an diesem Tag.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
