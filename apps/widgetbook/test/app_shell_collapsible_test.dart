import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/core_components_fixture.dart';

void main() {
  testWidgets('collapsible fixture keeps navigation and footer in rail', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const AppShellFixture(collapsible: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(KSidebarToggle));
    await tester.pumpAndSettle();
    expect(
      tester.widget<KSidebar>(find.byType(KSidebar)).mode,
      KSidebarMode.rail,
    );
    await tester.tap(find.byTooltip('Inbox').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Inbox has no content in this reference.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Help'), findsWidgets);
    await tester.tap(find.byType(KSidebarToggle));
    await tester.pumpAndSettle();
    expect(
      tester.widget<KSidebar>(find.byType(KSidebar)).mode,
      KSidebarMode.expanded,
    );
    expect(tester.takeException(), isNull);
  });
}
