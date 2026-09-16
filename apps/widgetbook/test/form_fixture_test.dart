import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/form_fixtures.dart';

void main() {
  testWidgets('filter reset clears actual input controllers and filter state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: FormFixture()),
      ),
    );
    await tester.pumpAndSettle();

    List<String> inputValues() => tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller!.text)
        .toList();
    final reset = find.byWidgetPredicate(
      (widget) => widget is KButton && widget.label == 'Reset all',
    );
    expect(inputValues(), ['', 'Active', 'Alex']);
    expect(find.byType(KFilterChip), findsNWidgets(2));
    expect(tester.widget<KButton>(reset).onPressed, isNotNull);

    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(inputValues(), ['', '', '']);
    expect(find.byType(KFilterChip), findsNothing);
    expect(find.text('No active filters'), findsOneWidget);
    expect(tester.widget<KButton>(reset).onPressed, isNull);
    expect(tester.widget<KCheckbox>(find.byType(KCheckbox)).value, isFalse);

    final search = find.byType(TextField).first;
    await tester.ensureVisible(search);
    await tester.enterText(search, 'Release');
    await tester.ensureVisible(find.byType(KCheckbox));
    await tester.tap(find.byType(KCheckbox));
    await tester.pumpAndSettle();
    expect(inputValues(), ['Release', '', '']);
    expect(tester.widget<KButton>(reset).onPressed, isNotNull);
    expect(tester.widget<KCheckbox>(find.byType(KCheckbox)).value, isTrue);

    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(inputValues(), ['', '', '']);
    expect(tester.widget<KCheckbox>(find.byType(KCheckbox)).value, isFalse);
    expect(
      find.text(
        'Query: All items · Status: Any · Assignee: Anyone · Archived: No',
      ),
      findsOneWidget,
    );
    expect(tester.widget<KButton>(reset).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('individual clears update filter state and retain field focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: FormFixture()),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'Release');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(fields.first).controller!.text, isEmpty);
    expect(tester.widget<TextField>(fields.first).focusNode!.hasFocus, isTrue);
    await tester.tap(find.byTooltip('Clear status'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(fields.at(1)).controller!.text, isEmpty);
    expect(find.byType(KFilterChip), findsOneWidget);
    await tester.tap(find.byTooltip('Clear assignee'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(fields.at(2)).controller!.text, isEmpty);
    expect(find.byType(KFilterChip), findsNothing);
    expect(find.text('No active filters'), findsOneWidget);
    expect(
      tester
          .widget<KButton>(
            find.byWidgetPredicate(
              (widget) => widget is KButton && widget.label == 'Reset all',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
