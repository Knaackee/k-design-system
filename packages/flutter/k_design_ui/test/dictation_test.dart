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

  testWidgets('dictation can render as a labeled button', (tester) async {
    await tester.pumpWidget(
      screen(
        KDictationAction(
          state: KDictationState.recording,
          label: 'Aufnahme beenden',
          showLabel: true,
          audioLevel: .5,
          onPressed: () {},
        ),
      ),
    );

    expect(find.text('Aufnahme beenden'), findsOneWidget);
    expect(find.byType(KButton), findsOneWidget);
    expect(find.byType(KIconButton), findsNothing);
    expect(
      tester.widget<KButton>(find.byType(KButton)).variant,
      KButtonVariant.primary,
    );

    await tester.pumpWidget(
      screen(
        KDictationAction(
          state: KDictationState.ready,
          label: 'Stimme aufnehmen',
          showLabel: true,
          onPressed: () {},
        ),
      ),
    );
    expect(
      tester.widget<KButton>(find.byType(KButton)).variant,
      KButtonVariant.secondary,
    );
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
  testWidgets('saved-caret dots follow the offset without modifying text', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Inspect roof');
    addTearDown(controller.dispose);
    Future<void> show(int offset, {bool readOnly = false}) async {
      await tester.pumpWidget(
        screen(
          KInput(
            controller: controller,
            dictationState: KDictationState.recording,
            dictationOffset: offset,
            readOnly: readOnly,
          ),
        ),
      );
      await tester.pump();
    }

    await show(0);
    expect(find.byType(KDictationAnchor), findsOneWidget);
    final start = tester.getTopLeft(find.byType(KDictationAnchor));
    await show(8);
    expect(
      tester.getTopLeft(find.byType(KDictationAnchor)).dx,
      greaterThan(start.dx),
    );
    expect(controller.text, 'Inspect roof');
    expect(controller.selection.baseOffset, -1);
    await show(8, readOnly: true);
    expect(find.byType(KDictationAnchor), findsNothing);
    await tester.pumpWidget(
      screen(
        KTextarea(
          controller: controller,
          dictationState: KDictationState.processing,
          dictationOffset: 8,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(KDictationAnchor), findsOneWidget);
    expect(controller.text, 'Inspect roof');
  });

  testWidgets(
    'recording feedback uses supplied level and reduced motion is static',
    (tester) async {
      Future<Size> wave(double? level) async {
        await tester.pumpWidget(
          screen(
            MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: KDictationAction(
                state: KDictationState.recording,
                label: 'Stop dictation',
                audioLevel: level,
                onPressed: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final bars = find.descendant(
          of: find.byType(KDictationAction),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.constraints?.maxWidth ==
                    KDesignTokens.orbitLight.borderWidthStrong,
          ),
        );
        expect(bars, findsNWidgets(5));
        return tester.getSize(bars.at(2));
      }

      final low = await wave(0);
      final high = await wave(1);
      expect(high.height, KDesignTokens.orbitLight.sizeIconDefault);
      expect(low.height, closeTo(high.height * 0.3, 0.01));
      expect(await wave(3), high);
      expect(await wave(-3), low);
      expect(await wave(double.nan), low);
      expect(await wave(null), high);
    },
  );
}
