import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'stream follows bottom but preserves deliberate reading position',
    (tester) async {
      tester.view.physicalSize = const Size(360, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> render(int lines) => tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: KChatConversation(
              messages: [
                KChatMessageValue(
                  id: 'stream',
                  role: KChatRole.assistant,
                  parts: [
                    KChatTextPart(
                      id: 'text',
                      text: List.filled(
                        lines,
                        'Streaming answer line.',
                      ).join('\n\n'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await render(30);
      await tester.pumpAndSettle();
      final list = find.byType(ListView);
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)).first,
          )
          .position;
      await render(40);
      await tester.pumpAndSettle();
      expect(position.extentAfter, lessThan(1));
      expect(find.text('Jump to newest message'), findsNothing);
      await tester.drag(list, const Offset(0, 200));
      await tester.pumpAndSettle();
      final readingOffset = position.pixels;
      await render(50);
      await tester.pumpAndSettle();
      expect(position.pixels, closeTo(readingOffset, 1));
      expect(find.text('Jump to newest message'), findsOneWidget);
      await tester.tap(find.text('Jump to newest message'));
      await tester.pump(const Duration(milliseconds: 30));
      await render(60);
      await tester.pumpAndSettle();
      expect(position.extentAfter, lessThan(1));
      expect(find.text('Jump to newest message'), findsNothing);
      tester.view.physicalSize = const Size(360, 350);
      await tester.pumpAndSettle();
      expect(position.extentAfter, lessThan(1));
      expect(find.text('Jump to newest message'), findsNothing);
    },
  );
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

  testWidgets('newest control overlays the scroll body without resizing it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(tester, [
      ...List.generate(
        20,
        (index) => KChatTextPart(
          id: 'long-message-$index',
          text: 'A long message that makes the conversation scrollable.',
        ),
      ),
      const KAgentQuestionPart(
        id: 'question',
        title: 'Which project?',
        kind: KAgentQuestionKind.text,
        state: KAgentResolutionState.pending,
      ),
    ]);

    final questionField = find.byType(TextField);
    await tester.ensureVisible(questionField);
    await tester.tap(questionField);
    tester.view.physicalSize = const Size(360, 300);
    await tester.pumpAndSettle();
    final scrollBodyAfterResize = tester.getRect(find.byType(ListView));
    expect(
      tester.getRect(questionField).bottom,
      lessThanOrEqualTo(scrollBodyAfterResize.bottom),
    );
    expect(find.text('Jump to newest message'), findsNothing);

    tester.view.physicalSize = const Size(360, 500);
    await tester.pump();
    final scrollBodyBeforeDrag = tester.getRect(find.byType(ListView));

    await tester.drag(find.byType(ListView), const Offset(0, 120));
    await tester.pump();

    final scrollBody = tester.getRect(find.byType(ListView));
    final newest = tester.getRect(find.text('Jump to newest message'));
    expect(newest.bottom, lessThanOrEqualTo(scrollBody.bottom));
    expect(scrollBody, scrollBodyBeforeDrag);
  });
  testWidgets('manual drag cancels a queued automatic follow', (tester) async {
    tester.view.physicalSize = const Size(360, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await mount(
      tester,
      List.generate(
        30,
        (index) => KChatTextPart(
          id: 'line-$index',
          text:
              'A message with enough content to scroll through the conversation.',
        ),
      ),
    );
    final list = find.byType(ListView);
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    final bottom = scrollable.position.pixels;
    ScrollMetricsNotification(
      metrics: scrollable.position.copyWith(),
      context: tester.element(list),
    ).dispatch(tester.element(list));
    final gesture = await tester.startGesture(tester.getCenter(list));
    await gesture.moveBy(const Offset(0, 24));
    await gesture.moveBy(const Offset(0, 150));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, lessThan(bottom - 50));
    expect(find.text('Jump to newest message'), findsOneWidget);
  });
}
