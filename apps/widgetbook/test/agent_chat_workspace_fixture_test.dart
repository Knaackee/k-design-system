import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/agent_chat_workspace_fixture.dart';

void main() {
  test('publishes the cross-platform fixture names', () {
    expect(AgentChatWorkspaceFixtureNames.all, [
      'Fullscreen',
      'NeedsInput',
      'Offline',
      'Mobile',
    ]);
  });

  Widget frame(AgentChatWorkspaceFixtureKind kind) => MaterialApp(
    theme: kDesignTheme(),
    home: AgentChatWorkspaceFixture(kind: kind),
  );

  testWidgets('keeps separate drafts for agents and sessions', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(frame(AgentChatWorkspaceFixtureKind.fullScreen));
    await tester.pump();

    final nova = tester.getSemantics(
      find.byKey(const ValueKey('k-agent-switcher-nova')),
    );
    expect(nova.label, contains('Verbindung: Ruhezustand'));
    expect(nova.hint, contains('Alt plus Pfeiltaste'));

    TextField composer() => tester.widget<TextField>(
      find.descendant(
        of: find.byType(KChatComposer),
        matching: find.byType(TextField),
      ),
    );

    await tester.enterText(
      find.descendant(
        of: find.byType(KChatComposer),
        matching: find.byType(TextField),
      ),
      'Ada-Entwurf',
    );
    await tester.tap(find.text('Linus'));
    await tester.pump();
    expect(composer().controller!.text, isEmpty);
    await tester.enterText(
      find.descendant(
        of: find.byType(KChatComposer),
        matching: find.byType(TextField),
      ),
      'Linus-Entwurf',
    );

    await tester.tap(find.text('Ada'));
    await tester.pump();
    expect(composer().controller!.text, 'Ada-Entwurf');

    await tester.tap(find.byType(KSelect));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Release vorbereiten'));
    await tester.pump();
    expect(composer().controller!.text, isEmpty);
    await tester.enterText(
      find.descendant(
        of: find.byType(KChatComposer),
        matching: find.byType(TextField),
      ),
      'Release-Entwurf',
    );
    await tester.tap(find.byType(KSelect));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aktuelles Gespräch'));
    await tester.pump();
    expect(composer().controller!.text, 'Ada-Entwurf');
    semantics.dispose();
  });
  testWidgets('mobile toolbar opens context without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(frame(AgentChatWorkspaceFixtureKind.mobile));
    await tester.pump();
    expect(tester.takeException(), null);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is KIconButton && widget.label == 'Kontext',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(KBottomSheet), findsOneWidget);
    expect(find.text('Projektbrief.pdf'), findsOneWidget);
    expect(tester.takeException(), null);
  });
}
