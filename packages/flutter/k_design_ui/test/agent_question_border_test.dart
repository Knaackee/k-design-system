import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  const pending = KAgentQuestionPart(
    id: 'question',
    title: 'Which source?',
    kind: KAgentQuestionKind.singleChoice,
    state: KAgentResolutionState.pending,
    options: [KAgentQuestionOption(id: 'current', label: 'Current data')],
  );
  final effect = find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint &&
        widget.foregroundPainter != null &&
        widget.painter != null,
  );

  testWidgets('question border preserves geometry and stops after answering', (
    tester,
  ) async {
    Future<void> mount(Widget question) => tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KAdaptiveTheme(
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(393, 852),
              disableAnimations: true,
            ),
            child: Scaffold(
              body: Align(alignment: Alignment.topCenter, child: question),
            ),
          ),
        ),
      ),
    );
    await mount(const KAgentSingleChoice(part: pending));
    expect(
      tester.widget<KAgentQuestion>(find.byType(KAgentQuestion)).border,
      KCardBorder.none,
    );
    expect(effect, findsNothing);
    final originalSize = tester.getSize(find.byType(KAgentQuestion));

    await mount(
      const KAgentSingleChoice(part: pending, border: KCardBorder.aurora),
    );
    expect(
      tester.widget<KAgentQuestion>(find.byType(KAgentQuestion)).border,
      KCardBorder.aurora,
    );
    expect(effect, findsOneWidget);
    expect(tester.getSize(find.byType(KAgentQuestion)), originalSize);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);

    await mount(
      const KAgentSingleChoice(
        part: KAgentQuestionPart(
          id: 'question',
          title: 'Which source?',
          kind: KAgentQuestionKind.singleChoice,
          state: KAgentResolutionState.answered,
          answerSummary: 'Current data',
        ),
        border: KCardBorder.aurora,
      ),
    );
    expect(effect, findsNothing);
    expect(find.text('Current data'), findsOneWidget);
    expect(find.byType(KButton), findsNothing);
  });
}
