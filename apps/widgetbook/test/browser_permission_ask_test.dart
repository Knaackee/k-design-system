import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/browser_permission_ask_fixture.dart';

void main() {
  testWidgets('always ask keeps the browser request pending', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: BrowserPermissionAskFixture()),
      ),
    );
    var question = tester.widget<KAgentQuestion>(find.byType(KAgentQuestion));
    question.onResponse!(
      const KAgentQuestionResponse(
        questionId: 'browser-permission',
        optionIds: ['ask'],
      ),
    );
    await tester.pump();
    question = tester.widget<KAgentQuestion>(find.byType(KAgentQuestion));
    expect(question.part.state, KAgentResolutionState.pending);
    expect(
      find.text('Diese Aktion wartet weiterhin auf deine Entscheidung.'),
      findsOneWidget,
    );
    question.onResponse!(
      const KAgentQuestionResponse(
        questionId: 'browser-permission',
        optionIds: ['allow-once'],
      ),
    );
    await tester.pump();
    expect(
      tester.widget<KAgentQuestion>(find.byType(KAgentQuestion)).part.state,
      KAgentResolutionState.answered,
    );
  });
  testWidgets('manual completion has only takeover and block', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(
          body: BrowserPermissionAskFixture(
            state: BrowserPermissionAskState.manual,
          ),
        ),
      ),
    );
    final part = tester
        .widget<KAgentQuestion>(find.byType(KAgentQuestion))
        .part;
    expect(part.options.map((option) => option.id), ['takeover', 'block']);
    expect(tester.takeException(), isNull);
  });
}
