import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  const destinations = [
    KAppDestination(id: 'home', label: 'Home', icon: KIconName.house),
    KAppDestination(
      id: 'settings',
      label: 'Settings',
      icon: KIconName.settings,
    ),
  ];

  testWidgets('controlled rail keeps chrome, custom destinations and toggle', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var mode = KSidebarMode.expanded;
    var selected = 'home';
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: StatefulBuilder(
          builder: (context, setState) => KAppShell(
            destinations: destinations,
            selectedId: selected,
            onSelected: (id) => setState(() => selected = id),
            sidebarMode: mode,
            onSidebarModeChanged: (value) => setState(() => mode = value),
            sidebarHeader: const KSidebarToggle(
              collapseLabel: 'Collapse',
              expandLabel: 'Expand',
            ),
            sidebarContent: KSidebarBody(
              children: [
                KSidebarItem(
                  label: 'Custom destination',
                  leading: const KIcon(KIconName.calendar),
                  onPressed: () => setState(() => selected = 'custom'),
                ),
              ],
            ),
            sidebarFooter: KSidebarItem(
              label: 'Help',
              leading: const KIcon(KIconName.circleAlert),
              onPressed: () => setState(() => selected = 'help'),
            ),
            child: Text('Selected $selected'),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(KSidebar)).width, 280);
    await tester.tap(find.byTooltip('Collapse').first);
    await tester.pumpAndSettle();
    expect(mode, KSidebarMode.rail);
    expect(
      tester.getSize(find.byType(KSidebar)).width,
      KSidebar.defaultRailWidth,
    );
    await tester.tap(find.byTooltip('Custom destination').first);
    await tester.pump();
    expect(find.text('Selected custom'), findsOneWidget);
    await tester.tap(find.byTooltip('Help').first);
    await tester.pump();
    expect(find.text('Selected help'), findsOneWidget);
    await tester.tap(find.byTooltip('Expand').first);
    await tester.pumpAndSettle();
    expect(mode, KSidebarMode.expanded);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(const Size(390, 800));
    await tester.pumpAndSettle();
    expect(find.byType(KSidebar), findsNothing);
    expect(find.byType(KMobileAppBar), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Selected settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('automatic rail falls back to the primary destinations', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KAppShell(
          destinations: destinations,
          selectedId: 'home',
          onSelected: (id) => selected = id,
          sidebarContent: const KSidebarBody(children: [Text('Custom body')]),
          child: const SizedBox(),
        ),
      ),
    );
    expect(find.text('Custom body'), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(700, 800));
    await tester.pumpAndSettle();
    expect(find.text('Custom body'), findsNothing);
    await tester.tap(find.byTooltip('Settings'));
    expect(selected, 'settings');
    expect(tester.takeException(), isNull);
  });

  for (final width in KPageWidth.values) {
    testWidgets('fluid shell delegates $width page sizing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final theme = kDesignTheme();
      final tokens = theme.extension<KDesignTokens>()!;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: KAppShell(
            destinations: destinations,
            selectedId: 'home',
            onSelected: (_) {},
            contentWidth: KPageWidth.fluid,
            child: KPage(
              width: width,
              children: const [
                SizedBox(key: ValueKey('page-child'), height: 40),
              ],
            ),
          ),
        ),
      );
      final expectedWidth = switch (width) {
        KPageWidth.fluid =>
          1600 - KSidebar.defaultExpandedWidth - 2 * tokens.spaceLayoutGutter,
        KPageWidth.content => tokens.layoutPageWidth,
        KPageWidth.form => tokens.layoutFormWidth,
      };
      expect(
        tester.getSize(find.byKey(const ValueKey('page-child'))).width,
        expectedWidth,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final mode in KSidebarMode.values) {
    testWidgets('settings reserves only $mode navigation width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: KSettingsPage(
            navigationMode: mode,
            navigation: KSidebar(
              mode: mode,
              expandedWidth: 280,
              child: const SizedBox(),
            ),
            contentPadding: EdgeInsets.zero,
            content: const SizedBox(key: ValueKey('content'), height: 40),
          ),
        ),
      );
      final width = switch (mode) {
        KSidebarMode.expanded => 280.0,
        KSidebarMode.rail => KSidebar.defaultRailWidth,
        KSidebarMode.hidden => 0.0,
      };
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('k-settings-content'))).dx,
        width,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
