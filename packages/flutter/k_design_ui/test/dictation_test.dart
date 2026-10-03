import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  Widget screen(Widget child) => MaterialApp(
    theme: kDesignTheme(),
    home: Scaffold(body: child),
  );

  testWidgets('dictation callbacks and accessible hit targets follow state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var calls = 0;
    try {
      for (final state in KDictationState.values) {
        await tester.pumpWidget(
          screen(
            KDictationAction(
              state: state,
              label: 'Dictate notes',
              onPressed: () => calls++,
            ),
          ),
        );
        expect(find.bySemanticsLabel('Dictate notes'), findsOneWidget);
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        final blocked =
            state == KDictationState.processing ||
            state == KDictationState.unavailable;
        expect(button.onPressed == null, blocked);
        final before = calls;
        await tester.tap(find.byType(FilledButton));
        expect(calls, before + (blocked ? 0 : 1));
        expect(
          tester.getSize(find.byType(KIconButton)).width,
          greaterThanOrEqualTo(KDesignTokens.orbitLight.sizeHitTarget),
        );
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'clear and dictation coexist without overlapping or altering dictation text',
    (tester) async {
      final controller = TextEditingController(text: 'Roof');
      addTearDown(controller.dispose);
      var calls = 0;
      await tester.pumpWidget(
        screen(
          KInput(
            controller: controller,
            clearable: true,
            clearLabel: 'Clear title',
            trailingAction: KDictationAction(
              state: KDictationState.ready,
              label: 'Dictate notes',
              onPressed: () => calls++,
            ),
          ),
        ),
      );
      final clear = find.byTooltip('Clear title');
      final dictation = find.byTooltip('Dictate notes');
      expect(
        tester.getRect(clear).overlaps(tester.getRect(dictation)),
        isFalse,
      );
      await tester.tap(dictation);
      expect(calls, 1);
      expect(controller.text, 'Roof');
      await tester.tap(clear);
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(dictation, findsOneWidget);
    },
  );

  testWidgets(
    'protected fields remove dictation and textarea reserves bottom space',
    (tester) async {
      final action = KDictationAction(
        state: KDictationState.ready,
        label: 'Dictate notes',
        onPressed: () {},
      );
      for (final field in [
        KInput(enabled: false, trailingAction: action),
        KInput(readOnly: true, trailingAction: action),
        KInput(obscureText: true, trailingAction: action),
        KTextarea(enabled: false, trailingAction: action),
        KTextarea(readOnly: true, trailingAction: action),
      ]) {
        await tester.pumpWidget(screen(field));
        expect(find.byType(KDictationAction), findsNothing);
      }
      await tester.pumpWidget(screen(KTextarea(trailingAction: action)));
      final field = tester.widget<TextField>(find.byType(TextField));
      final padding = field.decoration!.contentPadding! as EdgeInsets;
      expect(
        padding.bottom,
        greaterThanOrEqualTo(KDesignTokens.orbitLight.sizeHitTarget),
      );
      expect(
        tester.getRect(find.byType(KDictationAction)).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(KTextarea)).bottom),
      );
    },
  );
}
