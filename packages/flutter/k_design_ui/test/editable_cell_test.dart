import 'package:flutter/material.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

Widget frame(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 250, child: child)),
  ),
);
void main() {
  testWidgets(
    'select is a pointer target while combobox retains text editing',
    (tester) async {
      const options = [
        KSelectOption(value: 'a', label: 'Active'),
        KSelectOption(value: 'b', label: 'Done'),
      ];
      await tester.pumpWidget(
        frame(KSelect(options: options, value: 'a', onChanged: (_) {})),
      );
      var field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enableInteractiveSelection, isFalse);
      expect(field.showCursor, isFalse);
      expect(field.mouseCursor, SystemMouseCursors.click);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsOneWidget);
      await tester.pumpWidget(
        frame(KCombobox(options: options, value: 'a', onChanged: (_) {})),
      );
      field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enableInteractiveSelection, isTrue);
      expect(field.showCursor, isTrue);
      expect(field.mouseCursor, SystemMouseCursors.text);
      await tester.enterText(find.byType(TextField), 'Done');
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Done',
      );
    },
  );

  for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
    testWidgets('outside $kind closes editor without refocusing trigger', (
      tester,
    ) async {
      var editing = false;
      await tester.pumpWidget(
        frame(
          StatefulBuilder(
            builder: (context, setState) => KEditableCell(
              label: 'Edit title',
              display: const Text('Atlas'),
              editing: editing,
              onEdit: () => setState(() => editing = true),
              editor: Focus(
                onFocusChange: (focused) {
                  if (!focused && editing) setState(() => editing = false);
                },
                child: const KInput(autofocus: true),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Atlas'));
      await tester.pumpAndSettle();
      expect(editing, isTrue);
      await tester.tapAt(const Offset(10, 10), kind: kind);
      await tester.pumpAndSettle();
      expect(editing, isFalse);
      expect(
        tester
            .widget<FocusableActionDetector>(
              find.byType(FocusableActionDetector),
            )
            .focusNode!
            .hasFocus,
        isFalse,
      );
    });
  }

  testWidgets(
    'editor removal restores trigger focus without stealing external focus',
    (tester) async {
      final outside = FocusNode();
      var editing = false;
      late StateSetter update;
      await tester.pumpWidget(
        frame(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KEditableCell(
                    label: 'Edit title',
                    display: const Text('Atlas'),
                    editing: editing,
                    onEdit: () => setState(() => editing = true),
                    editor: KInput(
                      autofocus: true,
                      onSubmitted: (_) => setState(() => editing = false),
                    ),
                  ),
                  TextField(focusNode: outside),
                ],
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Atlas'));
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FocusableActionDetector>(
              find.byType(FocusableActionDetector),
            )
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(editing, isTrue);
      outside.requestFocus();
      await tester.pump();
      update(() => editing = false);
      await tester.pumpAndSettle();
      expect(outside.hasPrimaryFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
      outside.dispose();
    },
  );

  testWidgets(
    'outside action still receives its click and Escape restores focus',
    (tester) async {
      var editing = false;
      var clicks = 0;
      await tester.pumpWidget(
        frame(
          StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                KEditableCell(
                  label: 'Edit title',
                  display: const Text('Atlas'),
                  editing: editing,
                  onEdit: () => setState(() => editing = true),
                  editor: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.escape): () =>
                          setState(() => editing = false),
                    },
                    child: Focus(
                      onFocusChange: (focused) {
                        if (!focused && editing) {
                          setState(() => editing = false);
                        }
                      },
                      child: const KInput(autofocus: true),
                    ),
                  ),
                ),
                KButton(label: 'Other action', onPressed: () => clicks++),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Atlas'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FocusableActionDetector>(
              find.byType(FocusableActionDetector),
            )
            .focusNode!
            .hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Other action'));
      await tester.pumpAndSettle();
      expect(editing, isFalse);
      expect(clicks, 1);
      expect(
        tester
            .widget<FocusableActionDetector>(
              find.byType(FocusableActionDetector),
            )
            .focusNode!
            .hasFocus,
        isFalse,
      );
    },
  );
  testWidgets('editable cell rejects an empty accessible label', (
    tester,
  ) async {
    await tester.pumpWidget(
      frame(
        const KEditableCell(
          label: ' ',
          display: Text('Atlas'),
          editor: Text('Editor'),
        ),
      ),
    );
    expect(tester.takeException(), isArgumentError);
  });

  testWidgets('editable cell supports click keyboard and controlled editor', (
    tester,
  ) async {
    var count = 0;
    Widget cell({bool editing = false}) => KEditableCell(
      label: 'Edit title',
      display: const Text('Atlas'),
      editor: const Text('Editor'),
      editing: editing,
      onEdit: () => count++,
    );
    await tester.pumpWidget(frame(cell()));
    expect(find.text('Editor'), findsNothing);
    await tester.tap(find.text('Atlas'));
    expect(count, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(count, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(count, 3);
    await tester.pumpWidget(frame(cell(editing: true)));
    expect(find.text('Atlas'), findsNothing);
    expect(find.text('Editor'), findsOneWidget);
  });
  testWidgets('readonly cell preserves plain display', (tester) async {
    await tester.pumpWidget(
      frame(
        const KEditableCell(
          label: 'Title',
          display: Text('Atlas'),
          editor: Text('Editor'),
        ),
      ),
    );
    expect(find.byType(FocusableActionDetector), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
  });
  testWidgets('input forwards autofocus and submitted value', (tester) async {
    String? submitted;
    await tester.pumpWidget(
      frame(KInput(autofocus: true, onSubmitted: (v) => submitted = v)),
    );
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).autofocus, isTrue);
    await tester.enterText(find.byType(TextField), 'Changed');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(submitted, 'Changed');
  });
  testWidgets('inline select hides chrome and opens options on first click', (
    tester,
  ) async {
    String? value = 'a';
    await tester.pumpWidget(
      frame(
        KSelect(
          presentation: KSelectPresentation.inline,
          label: 'Status',
          value: value,
          onChanged: (v) => value = v,
          options: const [
            KSelectOption(value: 'a', label: 'Active'),
            KSelectOption(value: 'b', label: 'Done'),
          ],
        ),
      ),
    );
    final resting = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(resting.fillColor, Colors.transparent);
    expect(resting.enabledBorder!.borderSide.color, Colors.transparent);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.fillColor,
      isNot(Colors.transparent),
    );
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(value, 'b');
  });
  testWidgets('standard select retains chrome', (tester) async {
    await tester.pumpWidget(
      frame(
        KSelect(
          label: 'Status',
          value: 'a',
          onChanged: (_) {},
          options: const [KSelectOption(value: 'a', label: 'Active')],
        ),
      ),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).decoration!.fillColor,
      isNot(Colors.transparent),
    );
  });
}
