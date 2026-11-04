import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
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
    expect(find.text('Actions'), findsOneWidget);
    // The visible category proves that the Widgetbook navigation is mounted;
    // lower categories are virtualized by Widgetbook and are not in the test
    // tree until the user scrolls the rail.
  });

  testWidgets('configuration addon applies the selected adaptive axes', (
    tester,
  ) async {
    late KDesignTokens resolved;
    final addon = KDesignConfigurationAddon();

    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Builder(
          builder: (context) => addon.buildUseCase(
            context,
            Builder(
              builder: (context) {
                resolved = Theme.of(context).extension<KDesignTokens>()!;
                return const SizedBox();
              },
            ),
            const KGalleryConfiguration(
              device: false,
              manual: KDesignConfiguration.mobileApp,
            ),
          ),
        ),
      ),
    );

    expect(resolved.sizeControl, 36);
    expect(resolved.fontSize, 16);
    expect(resolved.fontHeading1Size, 28);
    expect(resolved.sizeHitTarget, 48);
  });
}
