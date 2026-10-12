import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  const rule = KBrowserPermissionRule(
    id: 'search',
    host: 'www.google.com',
    origin: 'https://www.google.com',
    path: '/search',
    action: 'Search',
    source: KBrowserRuleSource.baseline,
    decision: KBrowserRuleDecision.allow,
    status: KBrowserRuleStatus.active,
  );
  Widget list({
    List<KBrowserPermissionRule> rules = const [rule],
    void Function(String, KBrowserRuleDecision)? onDecision,
    ValueChanged<String>? onReset,
    ValueChanged<String>? onRevoke,
  }) => MaterialApp(
    theme: kDesignTheme(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: KBrowserPermissionList(
            agent: 'Nova',
            rules: rules,
            onDecisionChange: onDecision ?? (_, _) {},
            onReset: onReset ?? (_) {},
            onRevoke: onRevoke ?? (_) {},
          ),
        ),
      ),
    ),
  );
  testWidgets('compact list exposes controlled decisions and reset', (
    tester,
  ) async {
    String? reset;
    KBrowserRuleDecision? decision;
    await tester.pumpWidget(
      list(
        onReset: (id) => reset = id,
        onDecision: (_, value) => decision = value,
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Reset to included rule'));
    await tester.tap(find.text('Reset to included rule'));
    expect(reset, 'search');
    tester.widget<KSelect>(find.byType(KSelect)).onChanged!('block');
    expect(decision, KBrowserRuleDecision.block);
    expect(tester.widget<KSelect>(find.byType(KSelect)).value, 'allow');
    await tester.ensureVisible(find.text('Action details'));
    await tester.tap(find.text('Action details'));
    await tester.pumpAndSettle();
    expect(find.text('https://www.google.com'), findsOneWidget);
  });
  testWidgets('revoked rule disables selection and revoke', (tester) async {
    await tester.pumpWidget(
      list(
        rules: const [
          KBrowserPermissionRule(
            id: 'custom',
            host: 'very-long-hostname.example',
            origin: 'https://very-long-hostname.example',
            path: '/newsletter',
            action: 'Newsletter',
            source: KBrowserRuleSource.custom,
            decision: KBrowserRuleDecision.block,
            status: KBrowserRuleStatus.revoked,
          ),
        ],
      ),
    );
    expect(tester.widget<KSelect>(find.byType(KSelect)).enabled, isFalse);
    expect(tester.widget<KButton>(find.byType(KButton)).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty list gives the empty state', (tester) async {
    await tester.pumpWidget(list(rules: []));
    expect(find.text('No browser permissions yet'), findsOneWidget);
    expect(find.byType(KSelect), findsNothing);
  });
  testWidgets('task card keeps preview ratio and consumer actions', (
    tester,
  ) async {
    var clicked = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: KBrowserTaskCard(
              title: 'Browser task',
              description: 'Research',
              preview: const ColoredBox(color: Colors.white),
              actions: KButton(label: 'Open', onPressed: () => clicked = true),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio,
      16 / 9,
    );
    await tester.tap(find.text('Open'));
    expect(clicked, isTrue);
    expect(tester.takeException(), isNull);
  });
}
