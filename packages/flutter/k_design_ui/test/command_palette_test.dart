import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  Future<double> commandRowHeight(WidgetTester tester, KDensity density) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(
          configuration: KDesignConfiguration(density: density),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: KButton(
              label: 'Open',
              onPressed: () => KCommandPalette.show(
                context: context,
                items: const [
                  KCommandPaletteItem(
                    id: 'settings',
                    label: 'Settings',
                    description: 'Configure the workspace',
                  ),
                ],
                onCommand: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final height = tester
        .getSize(
          find.ancestor(
            of: find.text('Settings'),
            matching: find.byType(InkWell),
          ),
        )
        .height;
    await tester.tap(find.byType(KIconButton));
    await tester.pumpAndSettle();
    return height;
  }

  testWidgets('command rows follow the selected density', (tester) async {
    final denseHeight = await commandRowHeight(tester, KDensity.dense);
    final spaciousHeight = await commandRowHeight(tester, KDensity.spacious);

    expect(spaciousHeight, greaterThan(denseHeight));
  });

  testWidgets('filters, enters nested page and invokes one command', (
    tester,
  ) async {
    KCommandPaletteItem? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: KButton(
              label: 'Open',
              onPressed: () => KCommandPalette.show(
                context: context,
                items: const [
                  KCommandPaletteItem(
                    id: 'create',
                    label: 'Create new…',
                    children: [
                      KCommandPaletteItem(
                        id: 'issue',
                        label: 'Issue',
                        keywords: ['ticket'],
                      ),
                    ],
                  ),
                  KCommandPaletteItem(id: 'settings', label: 'Settings'),
                ],
                onCommand: (item) => selected = item,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Create new…'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'sett');
    await tester.pump();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Create new…'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.text('Create new…'));
    await tester.pump();
    expect(find.text('Issue'), findsOneWidget);
    expect(find.bySemanticsLabel('Back'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ticket');
    await tester.pump();
    await tester.tap(find.text('Issue'));
    await tester.pumpAndSettle();
    expect(selected?.id, 'issue');
    expect(find.text('Issue'), findsNothing);
  });
}
