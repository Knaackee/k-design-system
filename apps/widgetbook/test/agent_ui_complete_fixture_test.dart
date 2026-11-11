import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/agent_ui_complete_fixture.dart';
import 'package:k_design_widgetbook/ask_tools_fixture.dart';

void main() {
  Widget frame(CompleteScenario scenario) => MaterialApp(
    theme: kDesignTheme(),
    home: Scaffold(body: AgentUiCompleteFixture(scenario: scenario)),
  );

  testWidgets('ask-tools shares the chat frame and keeps answers independent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: AskToolsFixture()),
      ),
    );
    expect(find.byType(KChatComposer), findsOneWidget);
    final conversation = tester.widget<KChatConversation>(
      find.byType(KChatConversation),
    );
    expect(conversation.messages.first.id, 'request');
    conversation.onQuestionResponse!(
      const KAgentQuestionResponse(
        questionId: 'release-note-question',
        text: 'Hinweis',
      ),
    );
    await tester.pump();
    final questions = tester
        .widget<KChatConversation>(find.byType(KChatConversation))
        .messages
        .expand((m) => m.parts)
        .whereType<KAgentQuestionPart>();
    expect(
      questions.firstWhere((p) => p.id == 'release-note-question').state,
      KAgentResolutionState.answered,
    );
    expect(
      questions.firstWhere((p) => p.id == 'checks-question').state,
      KAgentResolutionState.pending,
    );
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 393.0]) {
    for (final scale in [1.0, 1.3, 2.0, 3.0]) {
      testWidgets('empty at width $width and text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const Scaffold(
              body: AgentUiCompleteFixture(scenario: CompleteScenario.empty),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('history contains every current accepted Agent UI part', (
    tester,
  ) async {
    await tester.pumpWidget(frame(CompleteScenario.history));
    final conversation = tester.widget<KChatConversation>(
      find.byType(KChatConversation),
    );
    final parts = conversation.messages.expand((m) => m.parts).toList();
    final renderedQuestions = [
      for (final message in conversation.messages)
        for (final part in message.parts)
          if (part is KAgentQuestionPart)
            conversation.renderPart!(
                  tester.element(find.byType(KChatConversation)),
                  part,
                  message,
                )
                as KAgentQuestion,
    ];
    expect(
      renderedQuestions.where(
        (question) => question.border == KCardBorder.aurora,
      ),
      hasLength(1),
    );
    expect(
      renderedQuestions
          .singleWhere((question) => question.border == KCardBorder.aurora)
          .part
          .id,
      parts
          .whereType<KAgentQuestionPart>()
          .where((part) => part.state == KAgentResolutionState.pending)
          .last
          .id,
    );
    expect(
      parts.whereType<KAgentQuestionPart>().map((p) => p.kind).toSet(),
      containsAll([
        KAgentQuestionKind.singleChoice,
        KAgentQuestionKind.multipleChoice,
        KAgentQuestionKind.text,
        KAgentQuestionKind.confirmation,
      ]),
    );
    expect(parts.whereType<KAgentFormPart>(), hasLength(1));
    expect(parts.whereType<KAgentToolPart>(), hasLength(2));
    expect(parts.whereType<KAgentApprovalPart>(), hasLength(1));
    expect(parts.whereType<KAgentExternalActionPart>(), hasLength(1));
    expect(parts.whereType<KAgentAttachmentRequestPart>(), hasLength(1));
    expect(parts.whereType<KAgentArtifactPart>(), hasLength(1));
    expect(
      parts.whereType<KChatTextPart>().any((p) => p.text.contains('```json')),
      isTrue,
    );

    conversation.onQuestionResponse!(
      const KAgentQuestionResponse(questionId: 'note', text: 'Mein Hinweis'),
    );
    conversation.onQuestionResponse!(
      const KAgentQuestionResponse(questionId: 'checks', optionIds: ['web']),
    );
    await tester.pump();
    final updated = tester.widget<KChatConversation>(
      find.byType(KChatConversation),
    );
    final questions = updated.messages
        .expand((m) => m.parts)
        .whereType<KAgentQuestionPart>();
    expect(
      questions.firstWhere((p) => p.id == 'note').answerSummary,
      'Mein Hinweis',
    );
    expect(questions.firstWhere((p) => p.id == 'checks').answerSummary, 'web');
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty scenario gates upload, sends and stops a local response', (
    tester,
  ) async {
    await tester.pumpWidget(frame(CompleteScenario.empty));
    expect(
      tester.widget<KChatConversation>(find.byType(KChatConversation)).messages,
      isEmpty,
    );
    KChatComposer composer() =>
        tester.widget<KChatComposer>(find.byType(KChatComposer));
    composer().onAttach!();
    await tester.pump();
    expect(composer().submitEnabled, isFalse);
    expect(
      composer().attachments.single.state,
      KChatAttachmentPartState.uploading,
    );
    await tester.tap(find.text('Demo-Upload abschließen'));
    await tester.pump();
    expect(composer().submitEnabled, isTrue);
    composer().onSubmit('Lokale Nachricht');
    await tester.pump();
    expect(composer().runState, KChatRunState.streaming);
    final messages = tester
        .widget<KChatConversation>(find.byType(KChatConversation))
        .messages;
    expect(
      messages.first.parts.whereType<KChatAttachmentPart>().single.id,
      'release-brief',
    );
    composer().onStop!();
    await tester.pump();
    expect(composer().runState, KChatRunState.stopped);
    await tester.tap(find.text('Zurücksetzen'));
    await tester.pump();
    expect(
      tester.widget<KChatConversation>(find.byType(KChatConversation)).messages,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}
