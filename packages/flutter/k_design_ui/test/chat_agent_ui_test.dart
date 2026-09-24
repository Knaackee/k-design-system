import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  Future<void> mount(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('approval emits one typed response and becomes resolved', (
    tester,
  ) async {
    KAgentApprovalResponse? response;
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => KAgentApproval(
          part: KAgentApprovalPart(
            id: 'publish',
            title: 'Publish?',
            state: response == null
                ? KAgentResolutionState.pending
                : KAgentResolutionState.approved,
            responseSummary: response == null ? null : 'Approved',
            options: const [
              KAgentApprovalOption(
                id: 'approve',
                label: 'Approve',
                primary: true,
              ),
            ],
          ),
          onResponse: (value) => setState(() => response = value),
        ),
      ),
    );

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    expect(response?.approvalId, 'publish');
    expect(response?.optionId, 'approve');
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
  });

  testWidgets('composer submits on Enter and preserves Shift Enter', (
    tester,
  ) async {
    var value = '';
    final submitted = <String>[];
    await mount(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Align(
          alignment: Alignment.topCenter,
          child: KChatComposer(
            value: value,
            onValueChanged: (next) => setState(() => value = next),
            onSubmit: submitted.add,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Check both platforms');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(submitted, ['Check both platforms']);
  });

  testWidgets('composer optional attachment and voice controls emit events', (
    tester,
  ) async {
    var attachmentRequests = 0;
    var voiceRequests = 0;
    await mount(
      tester,
      Align(
        alignment: Alignment.topCenter,
        child: KChatComposer(
          value: '',
          onValueChanged: (_) {},
          onSubmit: (_) {},
          labels: const KChatComposerLabels(
            attach: 'Add attachment',
            voice: 'Record voice',
          ),
          onAttach: () => attachmentRequests++,
          onVoiceInput: () => voiceRequests++,
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Add attachment'));
    await tester.tap(find.bySemanticsLabel('Record voice'));

    expect(attachmentRequests, 1);
    expect(voiceRequests, 1);
  });
}
