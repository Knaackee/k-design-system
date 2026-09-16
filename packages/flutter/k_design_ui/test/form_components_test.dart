import 'dart:io';
import 'dart:ui' show Tristate, SemanticsValidationResult;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final rootFont = File(
      'packages/flutter/k_design_tokens/assets/fonts/InterVariable.ttf',
    );
    final font = rootFont.existsSync()
        ? rootFont
        : File('../k_design_tokens/assets/fonts/InterVariable.ttf');
    final loader = FontLoader('packages/k_design_tokens/Inter');
    loader.addFont(font.readAsBytes().then(ByteData.sublistView));
    await loader.load();
  });
  Future<void> mount(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(body: SizedBox(width: 300, child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  const options = [
    KSelectOption(value: 'open', label: 'Open'),
    KSelectOption(value: 'closed', label: 'Closed', disabled: true),
    KSelectOption(value: 'progress', label: 'In progress'),
  ];
  testWidgets('field labels editable input and error replaces helper', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mount(
      tester,
      const KField(
        label: 'Title',
        helperText: 'Useful title',
        errorText: 'Title is required',
        child: KInput(),
      ),
    );
    expect(find.text('Useful title'), findsNothing);
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Title')), findsWidgets);
    await tester.enterText(find.byType(TextField), 'Updated');
    expect(find.text('Updated'), findsOneWidget);
    semantics.dispose();
  });
  testWidgets('read only input preserves value and disabled prevents changes', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Existing');
    await mount(tester, KInput(controller: controller, readOnly: true));
    final input = tester.widget<TextField>(find.byType(TextField));
    expect(input.readOnly, isTrue);
    await mount(tester, KInput(controller: controller, enabled: false));
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets('checkbox exposes mixed state and cycles on Space', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    bool? value;
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KCheckbox(
          label: 'Include completed',
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    expect(tester.widget<KCheckbox>(find.byType(KCheckbox)).value, isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(value, isTrue);
    semantics.dispose();
  });
  testWidgets('select skips disabled option and commits with Enter', (
    tester,
  ) async {
    String? value = 'open';
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KSelect(
          label: 'Status',
          options: options,
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(value, 'progress');
    expect(find.text('In progress'), findsOneWidget);
  });
  testWidgets('combobox filters locally and Escape restores committed label', (
    tester,
  ) async {
    String? value = 'open';
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KCombobox(
          label: 'Status',
          options: options,
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'progress');
    await tester.pumpAndSettle();
    expect(find.text('Closed'), findsNothing);
    expect(find.text('In progress'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(value, 'open');
    expect(find.text('Open'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'progress');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(value, 'progress');
  });
  testWidgets('filter chip removal and reset invoke application callbacks', (
    tester,
  ) async {
    var removed = 0;
    var reset = 0;
    await mount(
      tester,
      KFilterBar(
        label: 'Filters',
        onReset: () => reset++,
        children: [KFilterChip(label: 'Open', onRemove: () => removed++)],
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.tap(find.text('Reset all'));
    expect(removed, 1);
    expect(reset, 1);
  });
  testWidgets('input border includes horizontal inset and control height', (
    tester,
  ) async {
    await mount(tester, const KInput(placeholder: 'Title'));
    final outer = tester.getRect(find.byType(TextField));
    final editable = tester.getRect(find.byType(EditableText));
    expect(outer.height, 36);
    expect(editable.left - outer.left, 13);
  });
  testWidgets('select Home and End navigate enabled options; Escape cancels', (
    tester,
  ) async {
    String? value = 'open';
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KSelect(
          options: options,
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(value, 'progress');
    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(value, 'progress');
    expect(find.text('Open'), findsNothing);
  });
  testWidgets(
    'combobox empty query and outside tap preserve committed selection',
    (tester) async {
      var changes = 0;
      await mount(
        tester,
        KCombobox(options: options, value: 'open', onChanged: (_) => changes++),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pumpAndSettle();
      expect(find.text('No results'), findsOneWidget);
      await tester.tapAt(const Offset(500, 500));
      await tester.pumpAndSettle();
      expect(find.text('No results'), findsNothing);
      expect(find.text('Open'), findsOneWidget);
      expect(changes, 0);
    },
  );
  testWidgets('checkbox whole target activates and true toggles false', (
    tester,
  ) async {
    bool? value = true;
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KCheckbox(
          label: 'Include completed',
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    final rect = tester.getRect(find.byType(KCheckbox));
    await tester.tapAt(Offset(rect.left + 4, rect.top + 1));
    await tester.pumpAndSettle();
    expect(value, isFalse);
  });
  testWidgets('field required and error semantics belong to editable control', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await mount(
      tester,
      const KField(
        label: 'Title',
        required: true,
        errorText: 'Required title',
        child: KInput(),
      ),
    );
    final data = tester.getSemantics(find.byType(TextField)).getSemanticsData();
    expect(data.label, 'Title');
    expect(data.hint, 'Required title');
    expect(data.flagsCollection.isRequired, Tristate.isTrue);
    expect(data.validationResult, SemanticsValidationResult.invalid);
    handle.dispose();
  });
  testWidgets('placeholder does not duplicate the accessible field name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await mount(
      tester,
      const KField(
        label: 'Search items',
        child: KSearchField(placeholder: 'Search items'),
      ),
    );
    expect(
      tester.getSemantics(find.byType(TextField)).getSemanticsData().label,
      'Search items',
    );
    await mount(
      tester,
      KField(
        label: 'Status',
        child: KSelect(
          placeholder: 'Status',
          options: options,
          value: null,
          onChanged: (_) {},
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(TextField)).getSemanticsData().label,
      'Status',
    );
    handle.dispose();
  });
  for (final density in KDensity.values) {
    for (final scale in [1.0, 1.25, 1.5, 1.75, 2.0]) {
      testWidgets(
        'painted input container follows $density at $scale text scale',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: kDesignTheme(
                configuration: KDesignConfiguration(density: density),
              ),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const Scaffold(
                  body: SizedBox(
                    width: 300,
                    child: KSearchField(placeholder: 'Search items'),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(EditableText));
          final tokens = Theme.of(context).extension<KDesignTokens>()!;
          final container = InputDecorator.containerOf(context)!;
          expect(container.size.height, tokens.sizeControl);
          final origin = container.localToGlobal(Offset.zero);
          final editable = tester.getRect(find.byType(EditableText));
          expect(
            editable.left - origin.dx,
            1 + tokens.spaceControlInsetInline + 16 + tokens.spaceControlGap,
          );
          final render = tester
              .state<EditableTextState>(find.byType(EditableText))
              .renderEditable;
          final baseline =
              render.localToGlobal(Offset.zero).dy +
              render.getDryBaseline(
                render.constraints,
                TextBaseline.alphabetic,
              )!;
          // Chromium native-input font bounding metrics from the bundled Inter.
          final baselineOffset = {
            1.0: 5.0,
            1.25: 6.0,
            1.5: 7.0,
            1.75: 8.5,
            2.0: 9.5,
          }[scale]!;
          expect(
            baseline,
            closeTo(
              origin.dy + (tokens.sizeControl / 2 + baselineOffset).round(),
              .01,
            ),
          );
        },
      );
    }
  }
  testWidgets('rapid reopen after Escape clears the committed combobox label', (
    tester,
  ) async {
    String? value = 'open';
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KCombobox(
          options: options,
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'progress');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
    await tester.enterText(find.byType(TextField), 'progress');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(value, 'progress');
  });
  for (final scale in [1.25, 1.5, 1.75]) {
    testWidgets('field labels share pixel-grid line height at $scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const Scaffold(
              body: SizedBox(
                width: 300,
                child: KField(
                  label: 'Title',
                  helperText: 'Helpful text',
                  child: KInput(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(KField)).height,
        closeTo(36 + 16 + 2 * (13 * scale).round(), .01),
      );
    });
  }
}
