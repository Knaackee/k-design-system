import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

// Decision 0015: platform-native defaults without properties.
Widget host(Widget child, {KStyle style = KStyle.apple, double width = 393}) =>
    MaterialApp(
      home: KAdaptiveTheme(
        fontFamily: 'packages/k_design_tokens/Inter',
        overrides: KAdaptiveOverrides(style: style),
        child: Scaffold(
          body: Center(
            child: SizedBox(width: width, height: 800, child: child),
          ),
        ),
      ),
    );

void main() {
  testWidgets('list value sits beside a short title and under a long one', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        KList(
          children: [
            KListItem(title: 'Email', value: 'Weekly', onPressed: () {}),
            KListItem(
              title: 'On-device speech input for dictation and commands',
              value: 'Not set up',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final shortTitle = tester.getRect(find.text('Email'));
    final shortValue = tester.getRect(find.text('Weekly'));
    expect(shortValue.left, greaterThan(shortTitle.right));
    expect((shortValue.center.dy - shortTitle.center.dy).abs(), lessThan(2));
    final longTitle = tester.getRect(
      find.text('On-device speech input for dictation and commands'),
    );
    final longValue = tester.getRect(find.text('Not set up'));
    expect(longValue.top, greaterThanOrEqualTo(longTitle.bottom));
    expect((longValue.left - longTitle.left).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('material rows show the value as supporting text', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        KList(
          children: [
            KListItem(title: 'Email', value: 'Weekly', onPressed: () {}),
          ],
        ),
        style: KStyle.material,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.text('Weekly')).top,
      greaterThanOrEqualTo(tester.getRect(find.text('Email')).bottom),
    );
  });

  testWidgets('touch raises controls to the style heights', (tester) async {
    for (final (style, button, field) in [
      (KStyle.apple, 44.0, 44.0),
      (KStyle.material, 40.0, 56.0),
    ]) {
      final tokens = kDesignTokens(
        configuration: KDesignConfiguration(
          style: style,
          inputMode: KInputMode.touch,
        ),
      );
      expect(tokens.sizeControl, button, reason: '$style button');
      expect(tokens.sizeField, field, reason: '$style field');
    }
    final apple = kDesignTokens(
      configuration: const KDesignConfiguration(
        style: KStyle.apple,
        inputMode: KInputMode.touch,
      ),
    );
    expect(apple.sizeProminent, 50);
    final pointer = kDesignTokens(
      configuration: const KDesignConfiguration(style: KStyle.apple),
    );
    expect(pointer.sizeControl, 36);
    expect(pointer.sizeField, 36);
  });

  testWidgets('a full-width button centres its label', (tester) async {
    await tester.pumpWidget(
      host(KButton(label: 'Sign in', fullWidth: true, onPressed: () {})),
    );
    final button = tester.getRect(find.byType(KButton));
    final label = tester.getRect(find.text('Sign in'));
    expect((label.center.dx - button.center.dx).abs(), lessThan(1));
  });

  testWidgets('a form page keeps a readable width on a tablet', (tester) async {
    await tester.pumpWidget(
      host(
        const KPage(
          width: KPageWidth.form,
          children: [SizedBox(height: 40, child: Placeholder())],
        ),
        width: 1024,
      ),
    );
    final tokens = kDesignTokens();
    expect(
      tester.getSize(find.byType(Placeholder)).width,
      tokens.layoutFormWidth,
    );
  });

  testWidgets('the shell bar takes the title once it scrolls away', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: KAdaptiveTheme(
          fontFamily: 'packages/k_design_tokens/Inter',
          overrides: const KAdaptiveOverrides(style: KStyle.apple),
          child: Scaffold(
            body: KAppShell(
              destinations: const [
                KAppDestination(id: 'a', label: 'Home', icon: KIconName.house),
                KAppDestination(
                  id: 'b',
                  label: 'Settings',
                  icon: KIconName.settings,
                ),
              ],
              selectedId: 'b',
              onSelected: (_) {},
              child: ListView(
                controller: controller,
                children: [
                  KPageHeader(
                    title: 'Settings',
                    backLabel: 'Back to Home',
                    onBack: () {},
                    actions: [
                      KIconButton(
                        label: 'Share',
                        icon: KIconName.share,
                        onPressed: () {},
                      ),
                      KButton(label: 'Add', onPressed: () {}),
                    ],
                  ),
                  for (var i = 0; i < 40; i++)
                    SizedBox(height: 44, child: Text('Row $i')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bar = find.byType(KScrollTopBar);
    expect(bar, findsOneWidget);
    Iterable<double> opacities() => tester
        .widgetList<AnimatedOpacity>(
          find.descendant(of: bar, matching: find.byType(AnimatedOpacity)),
        )
        .map((widget) => widget.opacity);
    expect(opacities(), everyElement(0));
    controller.jumpTo(300);
    await tester.pumpAndSettle();
    expect(opacities(), everyElement(1));
    expect(find.text('Settings'), findsWidgets);
    // Back and actions stay reachable in the bar; the text action moves
    // into the More menu.
    final inBar = find.descendant(of: bar, matching: find.byType(KBackButton));
    expect(inBar, findsOneWidget);
    expect(
      find.descendant(of: bar, matching: find.byTooltip('Share')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bar, matching: find.byType(KMenuButton)),
      findsOneWidget,
    );
  });

  testWidgets('text-adjacent icons grow with the text up to 2x', (
    tester,
  ) async {
    Future<Size> sizeAt(double scale, {bool fixed = false}) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: host(
            Center(
              child: fixed
                  ? const KIconFixedScope(
                      child: KIcon(KIconName.house, size: 24),
                    )
                  : const KIcon(KIconName.house, size: 24),
            ),
          ),
        ),
      );
      return tester.getSize(find.byType(KIcon));
    }

    expect((await sizeAt(1)).width, 24);
    expect((await sizeAt(1.5)).width, 36);
    expect((await sizeAt(3)).width, 48);
    expect((await sizeAt(3, fixed: true)).width, 24);
  });
}
