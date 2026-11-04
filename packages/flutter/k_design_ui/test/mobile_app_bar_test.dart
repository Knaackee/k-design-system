import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
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
