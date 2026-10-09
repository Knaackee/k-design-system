import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/forms/selection_popup.dart';

void main() {
  for (final top in [40.0, 160.0, 320.0]) {
    testWidgets('combobox remains visible above keyboard at $top', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 756);
      addTearDown(tester.view.reset);
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Builder(
              builder: (context) => MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: Stack(
                  children: [
                    Positioned(
                      left: 16,
                      top: top,
                      width: 328,
                      child: KCombobox(
                        label: 'Model',
                        onChanged: (value) => selected = value,
                        options: List.generate(
                          20,
                          (index) => KSelectOption(
                            value: '$index',
                            label: 'Model $index',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 283);
      await tester.pumpAndSettle();
      final popup = tester.getRect(find.byType(KSelectionPopup));
      final trigger = tester.getRect(find.byType(TextField));
      expect(popup.top, greaterThanOrEqualTo(8));
      expect(popup.bottom, lessThanOrEqualTo(756 - 283 - 8));
      expect(popup.height, greaterThanOrEqualTo(120));
      if (top == 320) {
        expect(popup.bottom, lessThan(trigger.top));
      } else {
        expect(popup.top, greaterThan(trigger.bottom));
      }
      await tester.scrollUntilVisible(
        find.text('Model 19'),
        100,
        scrollable: find.descendant(
          of: find.byType(KSelectionPopup),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.text('Model 19'));
      await tester.pumpAndSettle();
      expect(selected, '19');
      expect(find.byType(KSelectionPopup), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('custom option icon appears in trigger and popup', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
        home: Scaffold(
          body: KSelect(
            label: 'Projects',
            value: 'orbit',
            onChanged: (_) {},
            options: const [
              KSelectOption(
                value: 'orbit',
                label: 'Orbit',
                leading: Icon(Icons.flag, color: Color(0xFFE76F51)),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.flag), findsOneWidget);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.flag), findsNWidgets(2));
    expect(
      tester.widget<Icon>(find.byIcon(Icons.flag).last).color,
      const Color(0xFFE76F51),
    );
  });

  testWidgets('select trigger toggles its popup closed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: KSelect(
                label: 'Status',
                onChanged: (_) {},
                options: [KSelectOption(value: 'open', label: 'Open')],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.byType(KSelectionPopup), findsOneWidget);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.byType(KSelectionPopup), findsNothing);
  });
  testWidgets('empty select exposes its label and placeholder', (tester) async {
    final semantics = tester.ensureSemantics();
    Widget select(String? value) => MaterialApp(
      theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
      home: Scaffold(
        body: KSelect(
          label: 'Teams',
          placeholder: 'All teams',
          value: value,
          onChanged: (_) {},
          options: const [KSelectOption(value: 'team', label: 'Team')],
        ),
      ),
    );
    await tester.pumpWidget(select(null));

    final data = tester.getSemantics(find.byType(TextField)).getSemanticsData();
    expect(data.label, 'Teams');
    expect(data.value, 'All teams');
    expect(data.flagsCollection.isButton, isTrue);

    await tester.pumpWidget(select('team'));
    expect(
      tester.getSemantics(find.byType(TextField)).getSemanticsData().value,
      'Team',
    );
    semantics.dispose();
  });

  testWidgets(
    'multiple selection toggles without closing and ignores disabled options',
    (tester) async {
      var values = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) => SizedBox(
                width: 320,
                child: KSelect(
                  multiple: true,
                  values: values,
                  onValuesChanged: (next) => update(() => values = next),
                  label: 'Teams',
                  placeholder: 'All teams',
                  options: const [
                    KSelectOption(
                      value: 'private',
                      label: 'Private projects',
                      icon: KIconName.lock,
                    ),
                    KSelectOption(
                      value: 'team',
                      label: 'Team',
                      icon: KIconName.users,
                    ),
                    KSelectOption(
                      value: 'disabled',
                      label: 'Disabled',
                      disabled: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Private projects'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Team'));
      await tester.pumpAndSettle();
      expect(values, ['private', 'team']);
      expect(find.byType(KSelectionPopup), findsOneWidget);
      await tester.tap(find.text('Disabled'));
      await tester.pumpAndSettle();
      expect(values, ['private', 'team']);
      await tester.tap(find.text('Private projects'));
      await tester.pumpAndSettle();
      expect(values, ['team']);
      expect(tester.takeException(), isNull);
    },
  );
  for (final top in [40.0, 240.0]) {
    testWidgets('select popup uses shifted nested overlay bounds at $top', (
      tester,
    ) async {
      final entry = OverlayEntry(
        builder: (_) => Positioned(
          left: 30,
          top: top,
          width: 180,
          child: KSelect(
            label: 'Status',
            value: 'active',
            onChanged: (_) {},
            options: const [
              KSelectOption(value: 'active', label: 'Active'),
              KSelectOption(value: 'done', label: 'Done'),
              KSelectOption(value: 'blocked', label: 'Blocked', disabled: true),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 130,
                  top: 90,
                  width: 350,
                  height: 300,
                  child: Overlay(initialEntries: [entry]),
                ),
              ],
            ),
          ),
        ),
      );
      final trigger = tester.getRect(find.byType(KSelect));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      final optionRegions = tester.widgetList<MouseRegion>(
        find.descendant(
          of: find.byType(KSelectionPopup),
          matching: find.byType(MouseRegion),
        ),
      );
      expect(
        optionRegions.where((r) => r.cursor == SystemMouseCursors.click).length,
        2,
      );
      expect(
        optionRegions.where((r) => r.cursor == SystemMouseCursors.basic).length,
        1,
      );
      final popup = tester.getRect(find.byType(KSelectionPopup));
      expect(popup.left, trigger.left);
      expect(popup.width, trigger.width);
      final gap = KDesignTokens.orbitLight.spaceControlGap;
      if (top == 40) {
        expect(popup.top, trigger.bottom + gap);
      } else {
        expect(popup.bottom, trigger.top - gap);
      }
      expect(popup.right, lessThanOrEqualTo(480));
      expect(popup.bottom, lessThanOrEqualTo(390));
      entry.remove();
      await tester.pumpWidget(const SizedBox());
      entry.dispose();
    });
  }
}
