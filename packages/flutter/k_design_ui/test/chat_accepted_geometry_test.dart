import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final density in KDensity.values) {
    for (final input in KInputMode.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('accepted question $density $input text $scale', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(393, 1400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final semantics = tester.ensureSemantics();

          await tester.pumpWidget(
            MaterialApp(
              home: KAdaptiveTheme(
                overrides: KAdaptiveOverrides(
                  density: density,
                  inputMode: input,
                  typeScale: KTypeScale.standard,
                  style: KStyle.linear,
                ),
                child: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: const Scaffold(
                      body: Padding(
                        padding: EdgeInsets.all(16),
                        child: KAgentQuestion(
                          part: KAgentQuestionPart(
                            id: 'question',
                            title: 'Question title',
                            description: 'Helpful context',
                            statusLabel: 'Waiting for input',
                            kind: KAgentQuestionKind.singleChoice,
                            state: KAgentResolutionState.pending,
                            options: [
                              KAgentQuestionOption(
                                id: 'first',
                                label: 'First option',
                              ),
                              KAgentQuestionOption(
                                id: 'second',
                                label:
                                    'A longer second option that wraps on a phone',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final option = find.bySemanticsLabel('First option');
          final row = find.ancestor(
            of: find.text('First option'),
            matching: find.byType(AnimatedContainer),
          );
          final t = Theme.of(
            tester.element(find.text('First option')),
          ).extension<KDesignTokens>()!;
          expect(t.componentChatTurnGap, switch (density) {
            KDensity.dense => 16,
            KDensity.standard => 24,
            KDensity.spacious => 32,
          });
          final height = tester.getSize(row).height;
          expect(height, greaterThanOrEqualTo(t.componentChatOptionMinHeight));
          if (input == KInputMode.touch) {
            expect(height, greaterThanOrEqualTo(t.sizeHitTarget));
          }
          expect(t.sizeIconStroke, t.componentChatIconStroke);
          expect(t.fontControlWeight, t.fontLabelWeight);
          final title = tester.widget<Text>(find.text('Question title'));
          expect(title.style?.fontSize, t.fontLabelSize);
          expect(title.style?.fontWeight, t.fontHeadingWeight);
          final submit = tester.widget<KButton>(find.byType(KButton));
          expect(submit.onPressed, isNull);
          await tester.tap(option);
          await tester.pump();
          expect(
            tester.widget<KButton>(find.byType(KButton)).onPressed,
            isNotNull,
          );
          expect(tester.takeException(), isNull);
          semantics.dispose();
        });
      }
    }
  }

  testWidgets('chat appearance leaves ordinary controls unchanged', (
    tester,
  ) async {
    KDesignTokens? outside;
    KDesignTokens? inside;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Column(
            children: [
              Builder(
                builder: (context) {
                  outside = Theme.of(context).extension<KDesignTokens>();
                  return const KIcon(KIconName.check);
                },
              ),
              KAgentQuestion(
                part: const KAgentQuestionPart(
                  id: 'question',
                  title: 'Question',
                  kind: KAgentQuestionKind.text,
                  state: KAgentResolutionState.pending,
                ),
                inputBuilder: (_) => Builder(
                  builder: (context) {
                    inside = Theme.of(context).extension<KDesignTokens>();
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(inside?.sizeIconStroke, 1.25);
    expect(outside?.sizeIconStroke, 1.5);
    expect(inside?.fontControlWeight, outside?.fontLabelWeight);
    expect(outside?.fontControlWeight, FontWeight.w600);
  });
}
