import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('decorative cursor and its avatar pass input through', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: SizedBox(
                  width: 160,
                  height: 80,
                  child: KButton(label: 'Save', onPressed: () => presses++),
                ),
              ),
              const Positioned(
                left: 0,
                top: 0,
                child: KAgentCursor(
                  state: KAgentCursorState.clicking,
                  avatar: KAvatar(alt: 'Agent'),
                  label: 'Agent',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Agent'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.tapAt(const Offset(40, 30));
    expect(presses, 1);
    final cursor = find.byType(KAgentCursor);
    expect(
      find.descendant(of: cursor, matching: find.byType(IgnorePointer)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cursor, matching: find.byType(ExcludeSemantics)),
      findsOneWidget,
    );
  });

  testWidgets('hidden cursor omits arrow and companion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const KAgentCursor(
          visible: false,
          label: 'Agent',
          avatar: KAvatar(alt: 'Agent'),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(KAgentCursor),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(find.byType(KAvatar), findsNothing);
    expect(find.text('Agent'), findsNothing);
  });
  testWidgets('consumer glow controls trigger a static repaint', (
    tester,
  ) async {
    Future<CustomPainter> painter(KAgentCursor cursor) async {
      await tester.pumpWidget(MaterialApp(theme: kDesignTheme(), home: cursor));
      return tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(KAgentCursor),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter!;
    }

    final enabled = await painter(const KAgentCursor());
    final disabled = await painter(const KAgentCursor(glowEnabled: false));
    expect(disabled.shouldRepaint(enabled), isTrue);
    final customized = await painter(
      const KAgentCursor(glowIntensity: .4, glowColor: Colors.pink),
    );
    expect(customized.shouldRepaint(enabled), isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
