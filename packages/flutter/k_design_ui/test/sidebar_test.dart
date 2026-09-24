import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('sidebar keeps fixed widths and hides nested rail content', (
    tester,
  ) async {
    var mode = KSidebarMode.expanded;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Align(
              alignment: Alignment.centerLeft,
              child: KSidebar(
                key: const ValueKey('sidebar'),
                mode: mode,
                onModeChanged: (value) => setState(() => mode = value),
                child: Column(
                  children: [
                    const KSidebarHeader(child: KSidebarToggle()),
                    KSidebarBody(
                      children: [
                        KSidebarSubgroup(
                          label: 'Team',
                          leading: const KIcon(KIconName.users),
                          children: const [
                            KSidebarItem(
                              label: 'Nested item',
                              leading: KIcon(KIconName.folder),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const ValueKey('sidebar'))).width, 248);
    expect(find.text('Nested item'), findsOneWidget);

    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byKey(const ValueKey('sidebar'))).width, 52);
    expect(find.text('Nested item'), findsNothing);
  });

  testWidgets('sidebar subgroup reports its expansion lifecycle', (
    tester,
  ) async {
    bool? reported;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KSidebar(
            mode: KSidebarMode.expanded,
            child: Column(
              children: [
                KSidebarBody(
                  children: [
                    KSidebarSubgroup(
                      label: 'Product lab',
                      onExpandedChanged: (value) => reported = value,
                      children: const [KSidebarItem(label: 'Roadmap')],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Product lab'));
    await tester.pump();
    expect(reported, isFalse);
    expect(find.text('Roadmap'), findsNothing);
  });
}
