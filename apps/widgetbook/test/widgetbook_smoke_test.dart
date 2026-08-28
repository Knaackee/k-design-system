import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_widgetbook/main.dart';

void main() {
  testWidgets('Widgetbook exposes the design-system navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const KDesignWidgetbook());
    await tester.pumpAndSettle();

    expect(find.text('K Design System'), findsOneWidget);
    expect(find.text('Primitives'), findsOneWidget);
  });
}
