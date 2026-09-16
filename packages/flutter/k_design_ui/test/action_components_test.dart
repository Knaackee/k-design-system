import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    double width = 375,
    double scale = 1,
    KDensity density = KDensity.standard,
    KInputMode inputMode = KInputMode.pointer,
  }) async {
    tester.view.physicalSize = Size(width, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(
          configuration: KDesignConfiguration(
            density: density,
            inputMode: inputMode,
          ),
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 812),
            textScaler: TextScaler.linear(scale),
          ),
          child: Scaffold(
            body: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<KMenuAction> actions(VoidCallback selected) => [
    KMenuAction(
      id: 'copy',
      label: 'Copy link',
      onSelect: selected,
      icon: KIconName.link,
    ),
    KMenuAction(
      id: 'disabled',
      label: 'Export',
      disabled: true,
      onSelect: () => fail('disabled action invoked'),
    ),
    KMenuAction(
      id: 'delete',
      label: 'Delete',
      onSelect: selected,
      destructive: true,
      separatorBefore: true,
    ),
  ];
  testWidgets('menu invokes once, skips disabled entries and restores focus', (
    tester,
  ) async {
    var selected = 0;
    await mount(
      tester,
      KMenuButton(label: 'Actions', actions: actions(() => selected++)),
    );
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Copy link');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Delete');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.text('Copy link'), findsNothing);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.focusNode!.hasPrimaryFocus, true);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Delete');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsNothing);
    expect(button.focusNode!.hasPrimaryFocus, true);
  });
  testWidgets('outside click dismisses and empty menu is disabled', (
    tester,
  ) async {
    await mount(
      tester,
      KMenuButton(label: 'Actions', actions: actions(() => {})),
    );
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(350, 700));
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsNothing);
    await mount(tester, const KMenuButton(label: 'Empty', actions: []));
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
  testWidgets('toolbar has one tab stop, arrows skip disabled and wrap', (
    tester,
  ) async {
    await mount(
      tester,
      Column(
        children: [
          KToolbar(
            label: 'Actions',
            children: [
              KIconButton(
                label: 'First',
                icon: KIconName.plus,
                onPressed: () {},
              ),
              const KIconButton(
                label: 'Disabled',
                icon: KIconName.copy,
                onPressed: null,
              ),
              KMenuButton(label: 'Last', actions: actions(() => {})),
            ],
          ),
          TextButton(onPressed: () {}, child: const Text('After')),
        ],
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final buttons = tester
        .widgetList<FilledButton>(find.byType(FilledButton))
        .toList();
    expect(buttons[0].focusNode!.hasPrimaryFocus, true);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(buttons[2].focusNode!.hasPrimaryFocus, true);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(buttons[0].focusNode!.hasPrimaryFocus, true);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(buttons[2].focusNode!.hasPrimaryFocus, false);
    expect(buttons[0].focusNode!.hasPrimaryFocus, false);
  });
  for (final density in KDensity.values) {
    for (final width in [320.0, 700.0, 1024.0]) {
      testWidgets('toolbar and menu fit $width / $density at 200%', (
        tester,
      ) async {
        await mount(
          tester,
          KToolbar(
            label: 'Actions',
            children: [
              KButton(label: 'New item', onPressed: () {}),
              KMenuButton(label: 'Actions', actions: actions(() => {})),
              KIconButton(
                label: 'Refresh',
                icon: KIconName.refreshCw,
                onPressed: () {},
              ),
              KOverflowMenu(label: 'More', actions: actions(() => {})),
            ],
          ),
          width: width,
          scale: 2,
          density: density,
        );
        expect(tester.takeException(), isNull);
        for (final element in find.byType(FilledButton).evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          expect(rect.right, lessThanOrEqualTo(width));
        }
        await tester.tap(find.text('Actions'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final rect = tester.getRect(find.text('Copy link'));
        expect(rect.right, lessThanOrEqualTo(width - 8));
      });
    }
  }
  testWidgets(
    'icon and overflow triggers expose their own accessible button names',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await mount(
        tester,
        KToolbar(
          label: 'Toolbar',
          children: [
            KIconButton(
              label: 'Refresh',
              icon: KIconName.refreshCw,
              onPressed: () {},
            ),
            KOverflowMenu(label: 'More actions', actions: actions(() {})),
          ],
        ),
      );
      for (final label in ['Refresh', 'More actions']) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
        expect(node.label, label);
      }
      semantics.dispose();
    },
  );
  testWidgets('touch trigger keeps dense paint size inside a 48px target', (
    tester,
  ) async {
    await mount(
      tester,
      KMenuButton(label: 'Actions', actions: actions(() {})),
      density: KDensity.dense,
      inputMode: KInputMode.touch,
    );
    expect(tester.getSize(find.byType(FilledButton)).height, 48);
    final material = find.descendant(
      of: find.byType(FilledButton),
      matching: find.byType(Material),
    );
    expect(tester.getSize(material.first).height, 32);
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MenuItemButton).first).height, 48);
    final gap = kDesignTokens(
      configuration: const KDesignConfiguration(
        density: KDensity.dense,
        inputMode: KInputMode.touch,
      ),
    ).spaceControlGap;
    expect(
      tester.getTopLeft(find.byType(MenuItemButton).first).dy,
      tester.getBottomLeft(find.byType(FilledButton)).dy + 2 * gap + 1,
    );
    expect(tester.takeException(), isNull);
  });
}
