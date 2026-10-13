import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'leading message padding scrolls with content without insetting viewport',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: SizedBox(
              height: 300,
              child: KChatConversation(
                contentPadding: const EdgeInsets.fromLTRB(16, 144, 16, 16),
                metadataMode: KChatMessageMetadataMode.hidden,
                messages: const [
                  KChatMessageValue(
                    id: 'one',
                    role: KChatRole.assistant,
                    parts: [KChatTextPart(id: 'text', text: 'A long message')],
                  ),
                ],
                renderPart: (_, _, _) => const SizedBox(
                  key: ValueKey('content'),
                  height: 900,
                  width: 200,
                ),
                avatarBuilder: (_, _, _) => null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Reading older messages is a user gesture; programmatic movement must
      // not disable following while streamed content changes its height.
      await tester.drag(find.byType(ListView), const Offset(0, 1200));
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      scrollable.position.jumpTo(0);
      await tester.pumpAndSettle();
      final viewport = tester.getRect(find.byType(ListView));
      final firstTop = tester
          .getRect(find.byKey(const ValueKey('content')))
          .top;
      expect(viewport.top, 0);
      expect(viewport.height, greaterThan(144));
      expect(firstTop - viewport.top, greaterThanOrEqualTo(144));
      scrollable.position.jumpTo(100);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('content'))).top,
        closeTo(firstTop - 100, .01),
      );
      expect(tester.getRect(find.byType(ListView)), viewport);
      expect(tester.takeException(), null);
    },
  );
}
