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
  testWidgets('composer places voice beside primary Send at mobile width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: KChatComposer(
              value: 'Draft',
              onValueChanged: (_) {},
              onSubmit: (_) {},
              onAttach: () {},
              onVoiceInput: () {},
            ),
          ),
        ),
      ),
    );
    final attach = find.byTooltip('Attach files');
    final voice = find.byTooltip('Start voice input');
    final send = find.byTooltip('Send message');
    final t = KDesignTokens.orbitLight;
    expect(tester.getRect(attach).right, lessThan(tester.getRect(voice).left));
    expect(
      tester.getRect(send).left - tester.getRect(voice).right,
      closeTo(t.spaceControlGap, 0.01),
    );
    expect(tester.getRect(voice).left, greaterThan(180));
    final sendButton = tester.widget<KIconButton>(
      find.ancestor(of: send, matching: find.byType(KIconButton)),
    );
    expect(sendButton.selected, isTrue);
    expect(sendButton.icon, KIconName.arrowUp);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled composer prevents voice activation', (tester) async {
    var calls = 0;
    await mount(
      tester,
      Align(
        alignment: Alignment.topCenter,
        child: KChatComposer(
          value: 'Draft',
          disabled: true,
          onValueChanged: (_) {},
          onSubmit: (_) {},
          onVoiceInput: () => calls++,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Start voice input'));
    expect(calls, 0);
  });

  testWidgets('active voice can stop while the composer is disabled', (tester) async {
    var calls = 0;
    await mount(tester, Align(alignment: Alignment.topCenter, child: KChatComposer(
      value: 'Draft', disabled: true, voiceActive: true,
      onValueChanged: (_) {}, onSubmit: (_) {}, onVoiceInput: () => calls++,
    )));
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    await tester.tap(find.byTooltip('Stop voice input'));
    expect(calls, 1);
    final sendButton = tester.widget<KIconButton>(find.ancestor(
      of: find.byTooltip('Send message'), matching: find.byType(KIconButton)));
    expect(sendButton.onPressed, isNull);
  });

}
