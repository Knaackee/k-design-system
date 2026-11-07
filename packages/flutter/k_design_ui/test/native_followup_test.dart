import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  test('withAccent replaces every accent-derived colour', () {
    const accent = Color(0xFF0C679F);
    for (final brightness in Brightness.values) {
      final t = kDesignTokens(brightness: brightness).withAccent(accent);
      expect(t.colorActionPrimaryBackground, accent);
      expect(t.componentSwitchActiveTrack, accent);
      expect(t.componentSelectionSelectedBackground, accent);
      expect(t.componentFabBackground, t.colorBrandPrimaryBackground);
      expect(t.componentListMediaBackground, t.colorBrandPrimaryBackground);
      // The tint leans to the accent's hue (blue), not the default green.
      final tint = t.colorBrandPrimaryBackground;
      expect(tint.b, greaterThan(tint.g));
    }
  });

  Widget app(Widget child, {KStyle style = KStyle.material}) => MaterialApp(
    home: KAdaptiveTheme(
      overrides: KAdaptiveOverrides(style: style),
      child: KLocalization(
        locale: 'en',
        child: Scaffold(body: child),
      ),
    ),
  );

  testWidgets('sidebar sections show on tablets only', (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget shell() => KAppShell(
      destinations: const [
        KAppDestination(id: 'a', label: 'Home', icon: KIconName.house),
        KAppDestination(id: 'b', label: 'Inbox', icon: KIconName.inbox),
      ],
      sidebarSections: const [
        KAppSidebarSection(
          label: 'Business',
          destinations: [
            KAppDestination(id: 'c', label: 'Customers', icon: KIconName.users),
          ],
        ),
      ],
      selectedId: 'a',
      onSelected: (_) {},
      child: const SizedBox(),
    );
    await tester.pumpWidget(app(shell()));
    expect(find.text('Business'), findsOneWidget);
    expect(find.text('Customers'), findsOneWidget);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(app(shell()));
    await tester.pumpAndSettle();
    expect(find.text('Customers'), findsNothing);
  });

  for (final style in [KStyle.apple, KStyle.material]) {
    testWidgets('KPage(onRefresh:) refreshes on pull ($style)', (tester) async {
      var refreshed = 0;
      await tester.pumpWidget(
        app(
          KPage(
            onRefresh: () async => refreshed++,
            children: const [SizedBox(height: 40, child: Text('Row'))],
          ),
          style: style,
        ),
      );
      expect(
        find.byType(
          style == KStyle.apple
              ? CupertinoSliverRefreshControl
              : RefreshIndicator,
          // The iOS control has no height until the page is pulled.
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Row')),
      );
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(const Offset(0, 30));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(refreshed, 1);
    });
  }
}
