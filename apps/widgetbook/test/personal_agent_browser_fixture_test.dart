import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/personal_agent_browser_fixture.dart';

void main() {
  testWidgets(
    'close persists through unrelated messages until explicit reopen',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: const PersonalAgentBrowserFixture(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is KIconButton && w.label == 'Browser schließen',
        ),
      );
      await tester.pump();
      expect(find.byType(KBrowserViewer), findsNothing);
      final composer = tester.widget<KChatComposer>(find.byType(KChatComposer));
      composer.onSubmit('Wie ist das Wetter?');
      await tester.pump();
      expect(find.byType(KBrowserViewer), findsNothing);
      expect(find.text('Du · Wie ist das Wetter?'), findsOneWidget);
      await tester.tap(find.text('Browser öffnen'));
      await tester.pump();
      expect(find.byType(KBrowserViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'permission is in scrolling chat and one click restores preview',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: const PersonalAgentBrowserFixture(scenario: 'permission'),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester.getSize(find.byKey(const ValueKey('browser-viewer'))).height,
        180,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('personal-browser-chat')),
          matching: find.text('Formulardaten senden?'),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Einmal erlauben'));
      await tester.tap(find.text('Einmal erlauben'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Einmal erlaubt'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('browser-viewer'))).height,
        greaterThan(180),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
