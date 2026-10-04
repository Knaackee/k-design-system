import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  KAgentToolPart tool(
    String id, [
    KAgentToolState state = KAgentToolState.succeeded,
  ]) => KAgentToolPart(
    id: id,
    toolName: 'search',
    title: 'Issues durchsuchen',
    state: state,
    arguments: const {'project': 'Orbit'},
  );
  Future<void> mount(WidgetTester tester, List<KChatMessagePart> parts) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: KChatConversation(
            messages: [
              KChatMessageValue(
                id: 'message',
                role: KChatRole.assistant,
                parts: parts,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'groups consecutive calls but keeps questions and failures visible',
    (tester) async {
      await mount(tester, [
        tool('one'),
        tool('two', KAgentToolState.running),
        const KAgentQuestionPart(
          id: 'question',
          title: 'Welches Projekt?',
          kind: KAgentQuestionKind.text,
          state: KAgentResolutionState.pending,
        ),
        tool('three', KAgentToolState.failed),
      ]);
      expect(find.text('Issues durchsuchen · 2×'), findsOneWidget);
      expect(find.text('Welches Projekt?'), findsOneWidget);
      expect(find.text('Arguments'), findsNothing);
    },
  );

  testWidgets(
    'open group remains expanded after completion with stable part IDs',
    (tester) async {
      await mount(tester, [tool('one'), tool('two', KAgentToolState.running)]);
      await tester.tap(find.text('Issues durchsuchen · 2×'));
      await tester.pumpAndSettle();
      expect(find.text('Issues durchsuchen'), findsNWidgets(2));
      await mount(tester, [tool('one'), tool('two')]);
      expect(find.text('Issues durchsuchen'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}
