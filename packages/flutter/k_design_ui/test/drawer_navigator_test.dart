import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final width in [375.0, 1280.0]) {
    for (final root in <bool?>[null, false, true]) {
      testWidgets('responsive drawer navigator width=$width root=$root', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final outer = GlobalKey<NavigatorState>();
        final inner = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: outer,
            theme: kDesignTheme(),
            home: Scaffold(
              body: SizedBox(
                width: width - 80,
                child: Navigator(
                  key: inner,
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (context) => Center(
                      child: KButton(
                        label: 'Open',
                        onPressed: () => KResponsiveDrawer.show<void>(
                          context: context,
                          useRootNavigator: root,
                          title: const Text('Details'),
                          child: const Text('Scoped content'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        final expectedRoot = root ?? width >= 600;
        expect(outer.currentState!.canPop(), expectedRoot);
        expect(inner.currentState!.canPop(), !expectedRoot);
        (expectedRoot ? outer : inner).currentState!.pop();
        await tester.pumpAndSettle();
        expect(find.text('Scoped content'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final root in [false, true]) {
    testWidgets('bottom sheet root=$root preserves nearest default', (
      tester,
    ) async {
      final outer = GlobalKey<NavigatorState>();
      final inner = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: outer,
          theme: kDesignTheme(),
          home: Scaffold(
            body: Navigator(
              key: inner,
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (context) => Center(
                  child: KButton(
                    label: 'Open',
                    onPressed: () => KBottomSheet.show<void>(
                      context: context,
                      useRootNavigator: root,
                      title: const Text('Details'),
                      child: const Text('Scoped content'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(outer.currentState!.canPop(), root);
      expect(inner.currentState!.canPop(), !root);
      (root ? outer : inner).currentState!.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
