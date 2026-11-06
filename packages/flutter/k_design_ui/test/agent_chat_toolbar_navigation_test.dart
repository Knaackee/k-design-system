import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final width in [390.0, 1200.0]) {
    testWidgets('custom navigation works at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var count = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: KAgentChatWorkspace(
            sidebar: const SizedBox.shrink(),
            sidebarCollapsed: true,
            contentMaxWidth: 400,
            toolbarMaxWidth: double.infinity,
            sidebarToggleBuilder: (context, collapsed, toggle) => KIconButton(
              icon: KIconName.arrowLeft,
              label: 'Back to agents',
              onPressed: () => count++,
            ),
            avatar: const SizedBox.square(dimension: 80),
            title: const Text('Ada'),
            conversation: const SizedBox.expand(),
            composer: const SizedBox(height: 48),
          ),
        ),
      );
      expect(find.byTooltip('Back to agents'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byTooltip('Back to agents')).dx,
        lessThan(60),
      );
      await tester.tap(find.byTooltip('Back to agents'));
      await tester.pumpAndSettle();
      expect(count, 1);
      expect(
        find.byKey(const ValueKey('k-agent-chat-workspace-agents')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
