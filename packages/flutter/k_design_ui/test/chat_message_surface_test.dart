import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  final messages = [
    KChatMessageValue(
      id: 'user',
      role: KChatRole.user,
      timestamp: DateTime(2026, 10, 8, 12, 34),
      status: KChatMessageStatus.sent,
      parts: const [KChatTextPart(id: 'user-text', text: 'Hi')],
    ),
    KChatMessageValue(
      id: 'assistant',
      role: KChatRole.assistant,
      timestamp: DateTime(2026, 10, 8, 12, 34),
      status: KChatMessageStatus.failed,
      parts: const [KChatTextPart(id: 'answer-text', text: 'Assistant answer')],
    ),
  ];
  Finder bubbles() => find.byWidgetPredicate(
    (widget) =>
        widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).border != null,
  );
  Future<void> mount(
    WidgetTester tester, {
    bool omitAvatars = true,
    KChatMessageMetadataMode metadata = KChatMessageMetadataMode.always,
    List<KChatMessageValue>? testMessages,
  }) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: KChatConversation(
            messages: testMessages ?? messages,
            metadataMode: metadata,
            formatTimestamp: (_) => '12:34',
            avatarBuilder: omitAvatars ? (_, _, _) => null : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'null avatar renderer leaves assistant transparent with author metadata',
    (tester) async {
      await mount(tester);
      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(bubbles(), findsOneWidget);
      final userBubble = tester.getRect(bubbles());
      expect(userBubble.width, lessThan(120));
      final answer = find.byWidgetPredicate(
        (widget) =>
            widget is KChatMarkdown && widget.text == 'Assistant answer',
      );
      expect(find.ancestor(of: answer, matching: bubbles()), findsNothing);
      final author = tester.widget<Text>(find.text('Assistant'));
      final tokens = Theme.of(
        tester.element(find.text('Assistant')),
      ).extension<KDesignTokens>()!;
      expect(author.style?.fontSize, tokens.fontCaptionSize);
      expect(
        tester.getRect(find.text('Not sent')).left,
        closeTo(tester.getRect(answer).left, 0.1),
      );
      expect(
        tester.getRect(find.text('Sent')).right,
        closeTo(userBubble.right, 0.1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('assistant remains borderless with a visible avatar', (
    tester,
  ) async {
    await mount(tester, omitAvatars: false);
    expect(find.byType(KAvatar), findsNWidgets(2));
    expect(bubbles(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'hidden author metadata retains user bubble and assistant author semantics',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mount(tester, metadata: KChatMessageMetadataMode.hidden);
      expect(find.text('Assistant'), findsNothing);
      expect(find.bySemanticsLabel(RegExp(r'^Assistant')), findsOneWidget);
      expect(bubbles(), findsOneWidget);
      expect(tester.getRect(bubbles()).width, lessThan(120));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('user bubble height matches its text lines and vertical inset', (
    tester,
  ) async {
    const singleLine = KChatMessageValue(
      id: 'single-line',
      role: KChatRole.user,
      parts: [KChatTextPart(id: 'single-line-text', text: 'Hi')],
    );
    await mount(
      tester,
      metadata: KChatMessageMetadataMode.hidden,
      testMessages: const [singleLine],
    );
    final tokens = Theme.of(
      tester.element(find.byType(KChatMarkdown)),
    ).extension<KDesignTokens>()!;
    expect(
      tester.getSize(bubbles()).height,
      closeTo(
        tokens.fontBodySmallLineHeight +
            2 * tokens.spaceControlGap +
            2 * tokens.borderWidthDefault,
        0.1,
      ),
    );

    const multiline = KChatMessageValue(
      id: 'multiline',
      role: KChatRole.user,
      parts: [
        KChatTextPart(id: 'multiline-text', text: 'First line\nSecond line'),
      ],
    );
    await mount(
      tester,
      metadata: KChatMessageMetadataMode.hidden,
      testMessages: const [multiline],
    );
    expect(
      tester.getSize(bubbles()).height,
      closeTo(
        2 * tokens.fontBodySmallLineHeight +
            2 * tokens.spaceControlGap +
            2 * tokens.borderWidthDefault,
        0.1,
      ),
    );
  });
}
