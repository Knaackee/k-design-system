import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/table_fixtures.dart';

void main() {
  testWidgets('table cells keep independent selection and menu actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: TableFixture(cells: true)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(KSelect).first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'Planned',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Atlas website: Planned'), findsOneWidget);
    expect(tester.widget<KSelect>(find.byType(KSelect).at(1)).value, 'planned');
    expect(tester.widget<KSelect>(find.byType(KSelect).at(2)).value, 'done');
    await tester.tap(find.byType(KOverflowMenu).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy name'));
    await tester.pumpAndSettle();
    expect(find.text('Copy name: Atlas website'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow table retains all columns through horizontal scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: TableFixture()),
      ),
    );
    await tester.pumpAndSettle();
    final horizontal = find.byWidgetPredicate(
      (widget) =>
          widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontal, findsOneWidget);
    await tester.drag(horizontal, const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('€12,000').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
