import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

// Decision 0015: platform-native defaults without properties.
Widget host(
  Widget child, {
  KStyle style = KStyle.apple,
  double width = 393,
  double height = 800,
}) => MaterialApp(
  home: KAdaptiveTheme(
    fontFamily: 'packages/k_design_tokens/Inter',
    overrides: KAdaptiveOverrides(style: style),
    child: Scaffold(
      body: Center(
        child: SizedBox(width: width, height: height, child: child),
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
    // Far down a lazy list the header leaves the viewport's cache; the bar
    // keeps its title and back control.
    controller.jumpTo(1400);
    await tester.pumpAndSettle();
    expect(opacities(), everyElement(1));
    expect(inBar, findsOneWidget);
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

  Future<void> pumpShell(
    WidgetTester tester, {
    required KStyle style,
    KPrimaryActionPlacement placement = KPrimaryActionPlacement.auto,
  }) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: KAdaptiveTheme(
          fontFamily: 'packages/k_design_tokens/Inter',
          overrides: KAdaptiveOverrides(style: style),
          child: Scaffold(
            body: KAppShell(
              primaryActionPlacement: placement,
              destinations: const [
                KAppDestination(id: 'a', label: 'Home', icon: KIconName.house),
                KAppDestination(id: 'b', label: 'More', icon: KIconName.menu),
              ],
              selectedId: 'a',
              onSelected: (_) {},
              child: KPage(
                children: [
                  KPageHeader(
                    title: 'Portfolios',
                    backLabel: 'Back',
                    onBack: () {},
                    actions: [
                      KButton(
                        label: 'Portfolio',
                        leading: const KIcon(KIconName.plus),
                        onPressed: () {},
                      ),
                      KMenuButton(
                        label: 'Options',
                        overflow: true,
                        actions: [
                          KMenuAction(
                            id: 'x',
                            label: 'Export',
                            onSelect: () {},
                          ),
                        ],
                      ),
                      KIconButton(
                        label: 'Edit',
                        icon: KIconName.pencil,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('phone header controls appear once, in the bar', (tester) async {
    await pumpShell(tester, style: KStyle.apple);
    expect(find.byType(KBackButton), findsOneWidget);
    // One More menu: the page's own overflow merges into the bar's.
    expect(find.byType(KMenuButton), findsOneWidget);
    // Apple: the primary action is an icon in the bar.
    expect(find.byTooltip('Portfolio'), findsOneWidget);
    expect(find.text('Portfolio'), findsNothing);
  });

  testWidgets('material puts the primary action on an extended FAB', (
    tester,
  ) async {
    await pumpShell(tester, style: KStyle.material);
    expect(find.text('Portfolio'), findsOneWidget);
    final fab = tester.getRect(find.text('Portfolio'));
    expect(fab.bottom, greaterThan(600));
    await pumpShell(
      tester,
      style: KStyle.material,
      placement: KPrimaryActionPlacement.bar,
    );
    expect(find.byTooltip('Portfolio'), findsOneWidget);
  });

  testWidgets('onboarding footer stays put on every step', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var done = false;
    await tester.pumpWidget(
      host(
        KOnboarding(
          steps: const [Text('One'), Text('Two'), Text('Three')],
          onDone: () => done = true,
        ),
        height: 852,
      ),
    );
    await tester.pumpAndSettle();
    final next = find.text('Next');
    final dots = find.byType(KProgressDots);
    final first = (tester.getRect(next), tester.getRect(dots));
    expect(first.$2.bottom, greaterThan(760));
    // Back is invisible but keeps its space on the first step.
    expect(find.text('Back').hitTestable(), findsNothing);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Next')), first.$1);
    expect(tester.getRect(dots), first.$2);
    expect(find.text('Back').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    expect(done, isTrue);
  });

  testWidgets('choice and switch rows respond on the whole row', (
    tester,
  ) async {
    var on = false;
    String? picked;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => KList(
            children: [
              KListItem(
                title: 'Appearance',
                value: 'Dark',
                menu: [
                  KMenuAction(
                    id: 'light',
                    label: 'Light',
                    onSelect: () => picked = 'light',
                  ),
                ],
              ),
              KListItem(
                title: 'Notifications',
                switchValue: on,
                onSwitchChanged: (value) => setState(() => on = value),
              ),
            ],
          ),
        ),
      ),
    );
    // A tap on the title, far from the trailing control, works.
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(on, isTrue);
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(picked, 'light');
  });

  testWidgets('only the visible tab fills the bar (IndexedStack)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget app(int index) => MaterialApp(
      home: KAdaptiveTheme(
        fontFamily: 'packages/k_design_tokens/Inter',
        overrides: const KAdaptiveOverrides(style: KStyle.material),
        child: Scaffold(
          body: KAppShell(
            destinations: const [
              KAppDestination(
                id: 'a',
                label: 'Portfolios',
                icon: KIconName.folder,
              ),
              KAppDestination(
                id: 'b',
                label: 'Chat',
                icon: KIconName.messageSquare,
              ),
            ],
            selectedId: index == 0 ? 'a' : 'b',
            onSelected: (_) {},
            child: IndexedStack(
              index: index,
              children: [
                KPage(
                  children: [
                    KPageHeader(
                      title: 'Portfolios',
                      actions: [
                        KButton(
                          label: 'Portfolio',
                          leading: const KIcon(KIconName.plus),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
                KPage(
                  children: [
                    KPageHeader(
                      title: 'Chat',
                      leading: KIconButton(
                        label: 'Chat history',
                        icon: KIconName.menu,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app(1));
    await tester.pumpAndSettle();
    // Chat: no FAB from the hidden Portfolios tab, the history button sits
    // in the bar.
    expect(find.text('Portfolio'), findsNothing);
    expect(find.byTooltip('Chat history'), findsOneWidget);
    final bar = find.byType(KScrollTopBar);
    expect(
      find.descendant(of: bar, matching: find.byTooltip('Chat history')),
      findsOneWidget,
    );
    await tester.pumpWidget(app(0));
    await tester.pumpAndSettle();
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.byTooltip('Chat history'), findsNothing);
    await tester.pumpWidget(app(1));
    await tester.pumpAndSettle();
    expect(find.text('Portfolio'), findsNothing);
  });

  testWidgets('the bar follows the shown tab, not the scrolled one', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    Widget app(int index) => MaterialApp(
      home: KAdaptiveTheme(
        fontFamily: 'packages/k_design_tokens/Inter',
        overrides: const KAdaptiveOverrides(style: KStyle.material),
        child: Scaffold(
          body: KAppShell(
            destinations: const [
              KAppDestination(id: 'a', label: 'Agents', icon: KIconName.house),
              KAppDestination(id: 'b', label: 'Jobs', icon: KIconName.folder),
            ],
            selectedId: index == 0 ? 'a' : 'b',
            onSelected: (_) {},
            child: IndexedStack(
              index: index,
              children: [
                KPage(
                  controller: controller,
                  children: [
                    KPageHeader(
                      title: 'Agents',
                      leading: KIconButton(
                        label: 'Account',
                        icon: KIconName.user,
                        onPressed: () {},
                      ),
                    ),
                    for (var i = 0; i < 40; i++)
                      SizedBox(height: 60, child: Text('Agent $i')),
                  ],
                ),
                const KPage(children: [KPageHeader(title: 'Jobs')]),
              ],
            ),
          ),
        ),
      ),
    );
    final bar = find.byType(KScrollTopBar);
    double background() => tester
        .widget<AnimatedOpacity>(
          find
              .descendant(of: bar, matching: find.byType(AnimatedOpacity))
              .first,
        )
        .opacity;
    await tester.pumpWidget(app(0));
    await tester.pumpAndSettle();
    expect(background(), 0);
    controller.jumpTo(1200);
    await tester.pumpAndSettle();
    expect(background(), 1);
    // The account button stays in the bar while scrolled.
    expect(
      find.descendant(of: bar, matching: find.byTooltip('Account')),
      findsOneWidget,
    );
    // Jobs is not scrolled: the bar is clear again.
    await tester.pumpWidget(app(1));
    await tester.pumpAndSettle();
    expect(background(), 0);
    // Back to Agents, still scrolled.
    await tester.pumpWidget(app(0));
    await tester.pumpAndSettle();
    expect(background(), 1);
  });
}
