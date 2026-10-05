import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('settings page switches navigation and detail below 700px', (
    tester,
  ) async {
    var detailVisible = false;
    var backCalls = 0;
    await tester.binding.setSurfaceSize(const Size(699, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KSettingsPage(
          navigation: const _TestNavigation(),
          content: const KSettingsRow(
            title: 'Name',
            control: SizedBox(width: 240, child: KInput()),
          ),
          detailVisible: detailVisible,
          onBack: () => backCalls++,
        ),
      ),
    );

    expect(find.text('Navigation'), findsOneWidget);
    expect(find.text('Detail'), findsNothing);

    // Rebuild with the detail selected, as a settings fixture would after a
    // navigation item is tapped.
    detailVisible = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KSettingsPage(
          navigation: const _TestNavigation(),
          content: const KSettingsRow(
            title: 'Name',
            control: SizedBox(width: 240, child: KInput()),
          ),
          detailVisible: detailVisible,
          onBack: () => backCalls++,
        ),
      ),
    );

    expect(find.text('Navigation'), findsNothing);
    expect(find.text('Name'), findsOneWidget);
    await tester.tap(find.widgetWithText(KButton, 'Settings'));
    expect(backCalls, 1);
  });

  testWidgets('settings page keeps both panes at the 700px breakpoint', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KSettingsPage(
          navigation: const _TestNavigation(),
          content: const KSettingsRow(
            title: 'Name',
            control: SizedBox(width: 320, child: KInput()),
          ),
          detailVisible: false,
        ),
      ),
    );

    expect(find.text('Navigation'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings row layouts distinguish compact and full width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Material(
          child: Column(
            children: [
              KSettingsRow(
                title: 'Product updates',
                description: 'Monthly summary',
                layout: KSettingsRowLayout.compact,
                control: KSwitch(
                  key: ValueKey('compact-control'),
                  label: 'Product updates',
                  value: true,
                  onChanged: null,
                ),
              ),
              KSettingsRow(
                title: 'Contact email',
                description: 'Security messages',
                layout: KSettingsRowLayout.fullWidth,
                control: KInput(
                  key: ValueKey('full-width-control'),
                  label: 'Contact email',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final compactControl = find.byKey(const ValueKey('compact-control'));
    final compactDescription = find.text('Monthly summary');
    expect(
      tester.getTopLeft(compactControl).dy,
      lessThan(tester.getBottomLeft(compactDescription).dy),
    );

    final fullWidthControl = find.byKey(const ValueKey('full-width-control'));
    expect(
      tester.getTopLeft(fullWidthControl).dy,
      greaterThan(tester.getBottomLeft(find.text('Security messages')).dy),
    );
    expect(tester.getSize(fullWidthControl).width, 375);
    expect(tester.takeException(), isNull);
  });
}

class _TestNavigation extends StatelessWidget {
  const _TestNavigation();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => KSidebar(
      mode: KSidebarMode.expanded,
      expandedWidth: constraints.maxWidth,
      child: const Column(
        children: [
          KSidebarBody(children: [KSidebarItem(label: 'Navigation')]),
        ],
      ),
    ),
  );
}
