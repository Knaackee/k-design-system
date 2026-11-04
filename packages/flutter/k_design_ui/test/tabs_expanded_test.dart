import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    double width,
    List<String> labels,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: KTabs(
                expanded: true,
                value: '0',
                onChanged: (_) {},
                items: [
                  for (var i = 0; i < labels.length; i++)
                    KTabItem(
                      id: '$i',
                      label: Text(labels[i]),
                      content: const SizedBox.shrink(),
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

  testWidgets('expanded tabs fill a wide row with equal controls', (
    tester,
  ) async {
    await mount(tester, 600, ['Festpreis', 'Ab-Preis', 'Auf Anfrage']);
    final buttons = find.byType(TextButton);
    expect(buttons, findsNWidgets(3));
    final widths = List.generate(3, (i) => tester.getSize(buttons.at(i)).width);
    expect(widths[0], closeTo(widths[1], 0.1));
    expect(widths[1], closeTo(widths[2], 0.1));
    expect(widths.first, greaterThan(150));
    expect(tester.takeException(), isNull);
  });

  testWidgets('long expanded labels scroll without render overflow', (
    tester,
  ) async {
    await mount(tester, 260, [
      'Festpreis für diese Dienstleistung',
      'Ab einem individuellen Preis',
      'Preis nur auf Anfrage',
    ]);
    expect(tester.takeException(), isNull);
    final scroll = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scroll.scrollDirection, Axis.horizontal);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
