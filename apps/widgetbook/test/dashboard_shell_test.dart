import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/dashboard_shell_fixture.dart';
import 'package:k_design_widgetbook/dashboard_shell_content.dart';

final details = find.byWidgetPredicate(
  (widget) => widget is KIconButton && widget.label == 'Project details',
);
final settings = find.byWidgetPredicate(
  (widget) => widget is KSidebarItem && widget.label == 'Settings',
);
Future<void> mount(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: kDesignTheme(),
      home: const Scaffold(
        body: DashboardShellFixture(initialMode: KSidebarMode.rail),
      ),
    ),
  );
}

void main() {
  for (final width in [375.0, 768.0, 1280.0]) {
    testWidgets('shell navigation and floating inspector at $width', (
      tester,
    ) async {
      await mount(tester, width);
      await tester.tap(find.text('Website refresh'));
      await tester.pumpAndSettle();
      final main = find.byType(DashboardShellContent);
      final bounds = tester.getRect(main);
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(tester.getRect(main), bounds);
      await tester.enterText(find.byType(TextField), 'Keep this project note');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.getRect(main), bounds);
      await tester.tap(details);
      await tester.pumpAndSettle();
      expect(find.text('Keep this project note'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      if (width < 600) {
        await tester.tap(
          find.byWidgetPredicate(
            (widget) =>
                widget is KIconButton && widget.label == 'Open navigation',
          ),
        );
        await tester.pumpAndSettle();
      }
      if (width < 600) {
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('navigation-brand')),
            matching: find.text('Orbit'),
          ),
          findsOneWidget,
        );
        expect(find.byType(KSidebarHeader), findsNothing);
        expect(tester.getSize(find.byType(KSidebar)).width, 248);
        expect(tester.getRect(settings).bottom, greaterThan(980));
        expect(
          find.byWidgetPredicate(
            (widget) => widget is KIconButton && widget.icon == KIconName.x,
          ),
          findsNothing,
        );
      }
      await tester.tap(settings);
      await tester.pumpAndSettle();
      if (width < 600) {
        expect(find.byKey(const ValueKey('navigation-brand')), findsNothing);
      }
      await tester.tap(find.text('Back to app'));
      await tester.pumpAndSettle();
      expect(find.text('Back to projects'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('mobile project and settings selections close navigation', (
    tester,
  ) async {
    await mount(tester, 375);
    final open = find.byWidgetPredicate(
      (widget) => widget is KIconButton && widget.label == 'Open navigation',
    );
    await tester.tap(open);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is KSidebarItem && widget.label == 'Projects',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navigation-brand')), findsNothing);
    expect(
      find.text('Your current projects and their progress.'),
      findsOneWidget,
    );
    await tester.tap(open);
    await tester.pumpAndSettle();
    await tester.tap(settings);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navigation-brand')), findsNothing);
    expect(find.text('Back to app'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('theme switcher applies light and dark to shell and inspector', (
    tester,
  ) async {
    await mount(tester, 1280);
    await tester.tap(find.byType(KThemeSwitcher));
    await tester.pumpAndSettle();
    expect(
      tester.widget<KThemeSwitcher>(find.byType(KThemeSwitcher)).value,
      ThemeMode.light,
    );
    await tester.tap(find.byType(KThemeSwitcher));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(DashboardShellContent))).brightness,
      Brightness.dark,
    );
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(KInput))).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('left navigation reserves its expanded width', (tester) async {
    await mount(tester, 1280);
    final main = find.byType(DashboardShellContent);
    final bounds = tester.getRect(main);
    expect(bounds.left, 56);
    await tester.tap(find.byType(KSidebarToggle));
    await tester.pumpAndSettle();
    expect(tester.getRect(main).left, 248);
    expect(tester.getRect(main).right, bounds.right);
    expect(tester.getSize(find.byType(KSidebar)).width, 248);
    await tester.tap(find.byType(KSidebarToggle));
    await tester.pumpAndSettle();
    expect(tester.getRect(main), bounds);
    expect(tester.getSize(find.byType(KSidebar)).width, 56);
  });

  testWidgets('expanded sidebar stays open across navigation and settings', (
    tester,
  ) async {
    await mount(tester, 1280);
    await tester.tap(find.byType(KSidebarToggle));
    await tester.pumpAndSettle();
    for (final label in ['Projects', 'Overview']) {
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is KSidebarItem && widget.label == label,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<KSidebar>(find.byType(KSidebar)).mode,
        KSidebarMode.expanded,
      );
    }
    await tester.tap(find.text('Website refresh'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(KBreadcrumb),
        matching: find.text('Projects'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<KSidebar>(find.byType(KSidebar)).mode,
      KSidebarMode.expanded,
    );
    await tester.tap(settings);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to app'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<KSidebar>(find.byType(KSidebar)).mode,
      KSidebarMode.expanded,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('inspector migrates across viewport without losing notes', (
    tester,
  ) async {
    await mount(tester, 1280);
    await tester.tap(details);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Across layouts');
    for (final width in [768.0, 375.0, 1280.0]) {
      tester.view.physicalSize = Size(width, 1000);
      await tester.pumpAndSettle();
      expect(find.text('Across layouts'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<KIconButton>()
          ?.label,
      'Project details',
    );
  });
  testWidgets('project notes remain isolated and settings save is local', (
    tester,
  ) async {
    await mount(tester, 1280);
    await tester.tap(find.text('Website refresh'));
    await tester.pumpAndSettle();
    await tester.tap(details);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Website only');
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to projects'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer portal'));
    await tester.pumpAndSettle();
    await tester.tap(details);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(settings);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'security');
    await tester.pumpAndSettle();
    expect(find.text('Security & access'), findsOneWidget);
    expect(find.text('Preferences'), findsNothing);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Demo: Changes saved locally.'), findsOneWidget);
    await tester.tap(find.text('Back to app'));
    await tester.pumpAndSettle();
    expect(find.text('Customer portal'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  for (final previewWidth in [375.0, 768.0, 1280.0]) {
    testWidgets(
      'overlay stays inside embedded preview navigator $previewWidth',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  key: ValueKey('preview'),
                  width: previewWidth,
                  height: 760,
                  child: DashboardShellFixture(),
                ),
              ),
            ),
          ),
        );
        await tester.tap(details);
        await tester.pumpAndSettle();
        expect(
          find.byType(KBottomSheet),
          previewWidth < 600 ? findsOneWidget : findsNothing,
        );
        final preview = tester.getRect(find.byKey(const ValueKey('preview')));
        final input = tester.getRect(find.byType(KInput));
        expect(input.right, lessThanOrEqualTo(preview.right));
        expect(input.left, greaterThanOrEqualTo(preview.left));
        expect(input.top, greaterThanOrEqualTo(preview.top));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(KInput), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
