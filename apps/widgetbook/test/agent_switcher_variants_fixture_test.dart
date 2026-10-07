import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_widgetbook/agent_switcher_variants_fixture.dart';

void main() {
  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('custom-content showcase reorders with ${kind.name} long press', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: const Scaffold(body: AgentSwitcherShowcaseFixture()),
        ),
      );
      await tester.pump();

      expect(find.byType(ReorderableListView), findsOneWidget);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Atlas')),
        kind: kind,
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      for (var step = 0; step < 6; step++) {
        await gesture.moveBy(const Offset(30, 0));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await gesture.up();
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.textContaining('Reihenfolge:'), findsOneWidget);
      expect(find.textContaining('nova, echo'), findsOneWidget);
    });
  }
}
