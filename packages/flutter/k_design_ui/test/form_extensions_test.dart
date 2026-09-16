import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

void main() {
  Future<void> mount(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(body: SizedBox(width: 300, child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'editable semantics keeps its name and identity beside one clear button',
    (tester) async {
      final handle = tester.ensureSemantics();
      for (final widget in [
        const KInput(label: 'Field', clearable: true),
        KCombobox(
          label: 'Field',
          options: const [KSelectOption(value: 'one', label: 'One')],
          value: null,
          clearable: true,
          onChanged: (_) {},
        ),
      ]) {
        await tester.pumpWidget(const SizedBox());
        await mount(tester, widget);
        final before = tester.getSemantics(find.byType(EditableText));
        final id = before.id;
        expect(before.getSemanticsData().label, 'Field');
        await tester.enterText(find.byType(TextField), 'Again');
        await tester.pumpAndSettle();
        final after = tester.getSemantics(find.byType(EditableText));
        expect(after.id, id);
        expect(after.getSemanticsData().label, 'Field');
        expect(after.getSemanticsData().value, 'Again');

        final buttons = <int>[];
        void collect(SemanticsNode node) {
          final data = node.getSemanticsData();
          if (data.flagsCollection.isButton && data.label == 'Clear') {
            buttons.add(node.id);
            expect(data.hasAction(SemanticsAction.focus), isTrue);
          }
          node.visitChildren((child) {
            collect(child);
            return true;
          });
        }

        collect(tester.getSemantics(find.byType(Scaffold)));
        expect(buttons, hasLength(1));
        await tester.tap(find.byTooltip('Clear'));
        await tester.pumpAndSettle();
        expect(tester.getSemantics(find.byType(EditableText)).id, id);
        expect(
          tester
              .getSemantics(find.byType(EditableText))
              .getSemanticsData()
              .label,
          'Field',
        );
      }
      handle.dispose();
    },
  );
  testWidgets(
    'clear input retains focus and notifies controlled and internal values',
    (tester) async {
      final controller = TextEditingController(text: 'Query');
      final focus = FocusNode();
      String? changed;
      await mount(
        tester,
        KSearchField(
          controller: controller,
          focusNode: focus,
          clearable: true,
          clearLabel: 'Clear search',
          onChanged: (value) => changed = value,
        ),
      );
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(controller.text, '');
      expect(changed, '');
      expect(focus.hasFocus, isTrue);
      expect(find.byTooltip('Clear search'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      focus.dispose();
      await mount(tester, const KInput(clearable: true));
      await tester.enterText(find.byType(TextField), 'Internal');
      await tester.pump();
      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
    },
  );
  testWidgets(
    'clear is opt in and unavailable for readonly disabled empty fields',
    (tester) async {
      final controller = TextEditingController(text: 'Value');
      for (final input in [
        KInput(controller: controller),
        KInput(controller: controller, clearable: true, readOnly: true),
        KInput(controller: controller, clearable: true, enabled: false),
        const KInput(clearable: true),
      ]) {
        await tester.pumpWidget(const SizedBox());
        await mount(tester, input);
        expect(find.byTooltip('Clear'), findsNothing);
      }
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
  testWidgets(
    'selection clears query and value closes options and keeps focus',
    (tester) async {
      String? value = 'alex';
      await mount(
        tester,
        StatefulBuilder(
          builder: (context, setState) => KCombobox(
            options: const [
              KSelectOption(value: 'alex', label: 'Alex', icon: KIconName.user),
            ],
            value: value,
            onChanged: (next) => setState(() => value = next),
            clearable: true,
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Al');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();
      final input = tester.widget<TextField>(find.byType(TextField));
      expect(value, isNull);
      expect(input.controller!.text, '');
      expect(input.focusNode!.hasFocus, isTrue);
      expect(find.text('Alex'), findsNothing);
      expect(find.byTooltip('Clear'), findsNothing);
    },
  );
  testWidgets('select clear is keyboard reachable without reopening options', (
    tester,
  ) async {
    String? value = 'one';
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KSelect(
          options: const [KSelectOption(value: 'one', label: 'One')],
          value: value,
          onChanged: (next) => setState(() => value = next),
          clearable: true,
        ),
      ),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    field.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(value, isNull);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(find.text('One'), findsNothing);
  });
  testWidgets(
    'unselected draft remains clearable after Tab and clears with Space',
    (tester) async {
      await mount(
        tester,
        KCombobox(
          options: const [KSelectOption(value: 'alex', label: 'Alex')],
          value: null,
          onChanged: (_) {},
          clearable: true,
        ),
      );
      await tester.enterText(find.byType(TextField), 'Al');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Clear'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Al',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '');
      expect(field.focusNode!.hasFocus, isTrue);
      expect(find.text('Alex'), findsNothing);
    },
  );
  testWidgets(
    'media stays decorative uses fixed size and image failure falls back',
    (tester) async {
      await mount(
        tester,
        KSelect(
          options: const [
            KSelectOption(
              value: 'alex',
              label: 'Alex',
              icon: KIconName.user,
              imageSrc: 'https://invalid.example/avatar.png',
            ),
          ],
          value: 'alex',
          onChanged: (_) {},
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, 16);
      expect(image.height, 16);
      expect(image.fit, BoxFit.cover);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is KIcon && widget.name == KIconName.user,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'filter reset label and enabled state controlled by application',
    (tester) async {
      var resets = 0;
      await mount(
        tester,
        KFilterBar(
          label: 'Filters',
          resetLabel: 'Restore defaults',
          resetEnabled: false,
          onReset: () => resets++,
          children: const [],
        ),
      );
      await tester.tap(find.text('Restore defaults'));
      await tester.pump();
      expect(resets, 0);
      await mount(
        tester,
        KFilterBar(
          label: 'Filters',
          resetLabel: 'Restore defaults',
          onReset: () => resets++,
          children: const [],
        ),
      );
      await tester.tap(find.text('Restore defaults'));
      await tester.pump();
      expect(resets, 1);
    },
  );
}
