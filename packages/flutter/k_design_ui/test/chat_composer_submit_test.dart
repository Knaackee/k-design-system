import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('follow-ups keep stop available and respect submission gates', (
    tester,
  ) async {
    final sent = <String>[];
    var stops = 0;
    var enabled = true;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return KChatComposer(
                value: 'Follow-up',
                onValueChanged: (_) {},
                onSubmit: sent.add,
                runState: KChatRunState.streaming,
                allowSubmitWhileRunning: true,
                submitEnabled: enabled,
                onStop: () => stops++,
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Send message'));
    expect(sent, ['Follow-up']);
    await tester.tap(find.byTooltip('Stop response'));
    expect(stops, 1);
    update(() => enabled = false);
    await tester.pump();
    final send = find.byWidgetPredicate(
      (widget) => widget is KIconButton && widget.label == 'Send message',
    );
    expect(tester.widget<KIconButton>(send).onPressed, isNull);
    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(sent, ['Follow-up']);
  });
  testWidgets(
    'submitEnabled blocks Enter and button while preserving draft editing',
    (tester) async {
      var draft = 'Draft';
      final sent = <String>[];
      var enabled = false;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return KChatComposer(
                  value: draft,
                  onValueChanged: (value) => setState(() => draft = value),
                  onSubmit: sent.add,
                  submitEnabled: enabled,
                );
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Editable draft');
      await tester.pump();
      expect(draft, 'Editable draft');
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, true);
      final send = find.byWidgetPredicate(
        (widget) => widget is KIconButton && widget.label == 'Send message',
      );
      expect(tester.widget<KIconButton>(send).onPressed, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(sent, isEmpty);
      update(() => enabled = true);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(sent, ['Editable draft']);
    },
  );
  testWidgets('blocked submission keeps running stop callback available', (
    tester,
  ) async {
    var stops = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KChatComposer(
            value: 'Draft',
            onValueChanged: (_) {},
            onSubmit: (_) => fail('Must not submit'),
            runState: KChatRunState.streaming,
            submitEnabled: false,
            onStop: () => stops++,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Stop response'));
    expect(stops, 1);
  });
}
