import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

const labels = [
  'Settings and personal information',
  'Platform administration',
  'Customers and businesses',
  'Account configuration and permissions',
  'Password security and authentication preferences',
];
Widget host(double width, double scale, void Function(int) selected) =>
    MaterialApp(
      theme: kDesignTheme(),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 800),
            textScaler: TextScaler.linear(scale),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: KBreadcrumb(
                label: 'Navigation trail',
                items: [
                  for (var i = 0; i < labels.length; i++)
                    KBreadcrumbItem(
                      id: '$i',
                      label: labels[i],
                      icon: i == 0 ? KIconName.house : null,
                      onSelect: i == labels.length - 1
                          ? null
                          : () => selected(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
void main() {
  for (final width in [320.0, 390.0, 500.0, 1024.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'breadcrumb fits $width at text scale $scale and retains current semantics',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final semantics = tester.ensureSemantics();
          var selected = -1;
          await tester.pumpWidget(
            host(width, scale, (index) => selected = index),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final current = find.text(labels.last);
          expect(current, findsOneWidget);
          expect(find.byTooltip(labels.last), findsOneWidget);
          expect(tester.widget<Text>(current).maxLines, 1);
          expect(tester.widget<Text>(current).overflow, TextOverflow.ellipsis);
          final selectedSemantics = find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.selected == true,
          );
          expect(selectedSemantics, findsOneWidget);
          expect(
            tester
                .getSemantics(selectedSemantics)
                .getSemanticsData()
                .flagsCollection
                .isSelected
                .name,
            'isTrue',
          );
          expect(
            find.byType(KMenuButton),
            width < 600 ? findsOneWidget : findsNothing,
          );
          if (width < 600) {
            expect(find.text(labels.first), findsNothing);
            expect(
              find.text(labels[3]),
              width < 400 ? findsNothing : findsOneWidget,
            );
            await tester.tap(find.byType(KMenuButton));
            await tester.pumpAndSettle();
            expect(find.text(labels.first), findsOneWidget);
            await tester.tap(find.text(labels.first));
            await tester.pumpAndSettle();
            expect(selected, 0);
          } else {
            await tester.tap(find.text(labels.first));
            await tester.pumpAndSettle();
            expect(selected, 0);
          }
          expect(tester.takeException(), isNull);
          semantics.dispose();
        },
      );
    }
  }
}
