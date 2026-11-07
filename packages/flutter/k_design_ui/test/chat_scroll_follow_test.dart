import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final width in [360.0, 393.0]) {
    testWidgets('newest control preserves scroll geometry at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: KAdaptiveTheme(
            child: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: KChatConversation(
                      messages: const [
                        KChatMessageValue(
                          id: 'long-answer',
                          role: KChatRole.assistant,
                          parts: [KChatTextPart(id: 'text', text: 'Answer')],
                        ),
                      ],
                      renderPart: (_, _, _) => const SizedBox(height: 2400),
                    ),
                  ),
                  const SizedBox(key: ValueKey('composer'), height: 80),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final list = find.byType(ListView);
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)).first,
          )
          .position;
      final viewport = tester.getRect(list);
      await tester.drag(list, const Offset(0, 160));
      await tester.pumpAndSettle();
      expect(find.text('Jump to newest message'), findsOneWidget);
      expect(tester.getRect(list), viewport);
      expect(
        tester.getRect(find.text('Jump to newest message')).bottom,
        lessThan(tester.getRect(find.byKey(const ValueKey('composer'))).top),
      );
      // Cross the follow threshold with a finger still down, then continue
      // toward the bottom. Showing/hiding the control must not move the target.
      final gesture = await tester.startGesture(tester.getCenter(list));
      await gesture.moveBy(const Offset(0, -24));
      await gesture.moveBy(Offset(0, -position.extentAfter - 100));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(position.extentAfter, lessThan(1));
      expect(find.text('Jump to newest message'), findsNothing);
      expect(tester.getRect(list), viewport);
      expect(tester.takeException(), isNull);
    });
  }
}
