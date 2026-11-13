import 'dart:ui' show SemanticsAction, SemanticsActionEvent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'labeled actions close on Back Escape and outside, restoring trigger focus',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final navigator = GlobalKey<NavigatorState>();
      final states = <bool>[];
      var selections = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: kDesignTheme(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: KFab(
                  label: 'Main action',
                  showLabels: true,
                  onOpenChanged: states.add,
                  items: [
                    KFabItem(
                      id: 'item',
                      label: 'Visible action name',
                      onSelected: () => selections++,
                      child: const Text('Icon'),
                    ),
                  ],
                  child: const Text('Main glyph'),
                ),
              ),
            ),
          ),
        ),
      );
      Future<void> open() async {
        await tester.tap(find.text('Main glyph'));
        await tester.pumpAndSettle();
        expect(find.text('Visible action name'), findsOneWidget);
        expect(navigator.currentState!.canPop(), isTrue);
      }

      void closed() {
        expect(find.text('Visible action name'), findsNothing);
        expect(navigator.currentState!.canPop(), isFalse);
        expect(
          Focus.of(tester.element(find.text('Main glyph'))).hasFocus,
          isTrue,
        );
      }

      await open();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      closed();
      await open();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      closed();
      await open();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      closed();
      await open();
      await tester.tap(find.text('Visible action name'));
      await tester.pumpAndSettle();
      closed();
      expect(selections, 1);
      expect(states, [true, false, true, false, true, false, true, false]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('labeled actions scroll at 3x text in a narrow window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 740),
              textScaler: TextScaler.linear(3),
            ),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: KFab(
                  label: 'Main action',
                  showLabels: true,
                  items: [
                    for (var i = 0; i < 5; i++)
                      KFabItem(
                        id: '$i',
                        label: 'Very long action name $i',
                        child: const KIcon(KIconName.plus),
                        onSelected: () {},
                      ),
                  ],
                  child: const Text('+'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();
    final last = find.text('Very long action name 4');
    await tester.ensureVisible(last);
    expect(last, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'selection opening a dialog keeps its autofocus and removes FAB back history',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: kDesignTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Align(
                alignment: Alignment.bottomRight,
                child: KFab(
                  label: 'Create',
                  showLabels: true,
                  items: [
                    KFabItem(
                      id: 'form',
                      label: 'Open form',
                      child: const KIcon(KIconName.plus),
                      onSelected: () => showDialog<void>(
                        context: context,
                        builder: (_) =>
                            const Dialog(child: TextField(autofocus: true)),
                      ),
                    ),
                  ],
                  child: const Text('+'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(navigator.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('labeled options have one keyboard stop each and select once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final selected = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: KFab(
              label: 'Create',
              showLabels: true,
              items: [
                for (var i = 0; i < 3; i++)
                  KFabItem(
                    id: '$i',
                    label: 'Option $i',
                    onSelected: () => selected.add(i),
                    child: const KIcon(KIconName.plus),
                  ),
              ],
              child: const Text('+'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('+'));
    await tester.pumpAndSettle();
    FocusNode option(int index) =>
        Focus.of(tester.element(find.text('Option $index')));
    option(0).requestFocus();
    await tester.pump();
    expect(option(0).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(option(1).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(option(2).hasPrimaryFocus, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(option(1).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, [1]);
    expect(find.text('Option 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('labeled semantics exposes tap only for enabled options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    var selections = 0;
    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomRight,
              child: KFab(
                label: 'Create',
                showLabels: true,
                items: [
                  KFabItem(
                    id: 'enabled',
                    label: 'Enabled option',
                    onSelected: () => selections++,
                    child: const KIcon(KIconName.plus),
                  ),
                  const KFabItem(
                    id: 'disabled',
                    label: 'Disabled option',
                    onSelected: null,
                    child: KIcon(KIconName.plus),
                  ),
                ],
                child: const Text('+'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('+'));
      await tester.pumpAndSettle();
      final enabled = tester.getSemantics(
        find.bySemanticsLabel('Enabled option'),
      );
      final disabled = tester.getSemantics(
        find.bySemanticsLabel('Disabled option'),
      );
      expect(enabled.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(
        disabled.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          viewId: tester.view.viewId,
          nodeId: enabled.id,
          type: SemanticsAction.tap,
        ),
      );
      await tester.pumpAndSettle();
      expect(selections, 1);
      expect(find.text('Enabled option'), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
