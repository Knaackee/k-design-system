import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final variant in [
    KMobileAppBarVariant.floatingGlass,
    KMobileAppBarVariant.labeled,
  ]) {
    for (final (count, layoutAware) in [
      ('1', false),
      ('10', false),
      ('99+', false),
      ('99+', true),
    ]) {
      testWidgets(
        '$variant keeps ${layoutAware ? 'layout-aware ' : ''}badge $count '
        'inside its destination without clipping',
        (tester) async {
          tester.view.physicalSize = const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final countBadge = Text(count, key: const ValueKey('count'));
          final badgeWidget = layoutAware
              ? LayoutBuilder(builder: (_, _) => countBadge)
              : countBadge;
          await tester.pumpWidget(
            MaterialApp(
              theme: kDesignTheme(),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: KMobileAppBar(
                    variant: variant,
                    quality: KGlassQuality.solid,
                    labelVisibility: KMobileAppBarLabelVisibility.never,
                    selectedId: 'inbox',
                    onSelectionChanged: (_) {},
                    items: [
                      for (final id in [
                        'home',
                        'calendar',
                        'inbox',
                        'customers',
                        'settings',
                      ])
                        KMobileAppBarItem(
                          id: id,
                          label: id,
                          icon: const Icon(Icons.home),
                          badge: id == 'inbox' ? badgeWidget : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final text = find.byKey(const ValueKey('count'));
          final badge = find
              .ancestor(of: text, matching: find.byType(Container))
              .first;
          final rect = tester.getRect(badge);
          final destination = tester.getRect(find.byTooltip('inbox'));
          expect(rect.left, greaterThanOrEqualTo(destination.left));
          expect(rect.right, lessThanOrEqualTo(destination.right));
          expect(rect.top, greaterThanOrEqualTo(destination.top));
          expect(rect.bottom, lessThanOrEqualTo(destination.bottom));
          final material = tester.widget<Material>(
            find.ancestor(of: text, matching: find.byType(Material)).first,
          );
          expect(material.clipBehavior, Clip.none);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  for (final variant in [
    KMobileAppBarVariant.fixed,
    KMobileAppBarVariant.fixedLine,
    KMobileAppBarVariant.floatingDock,
    KMobileAppBarVariant.action,
  ]) {
    testWidgets('$variant selects destinations and preserves disabled items', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var selected = 'chat';
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => KMobileAppBar(
                items: const [
                  KMobileAppBarItem(
                    id: 'portfolios',
                    label: 'Portfolios',
                    icon: Icon(Icons.home),
                  ),
                  KMobileAppBarItem(
                    id: 'chat',
                    label: 'Chat',
                    icon: Icon(Icons.chat),
                  ),
                  KMobileAppBarItem(
                    id: 'disabled',
                    label: 'Disabled',
                    icon: Icon(Icons.settings),
                    enabled: false,
                  ),
                ],
                selectedId: selected,
                variant: variant,
                quality: KGlassQuality.solid,
                visibility: KMobileAppBarVisibility.always,
                onSelectionChanged: (id) => setState(() => selected = id),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Portfolios'));
      await tester.pumpAndSettle();
      expect(selected, 'portfolios');
      await tester.tap(find.byTooltip('Disabled'));
      expect(selected, 'portfolios');
      final rect = tester.getRect(find.byTooltip('Chat'));
      expect(rect.width, greaterThanOrEqualTo(44));
      expect(rect.height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
    });
  }
}
