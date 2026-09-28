import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('rail app icon is a single keyboard accessible toggle', (
    tester,
  ) async {
    var mode = KSidebarMode.rail;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => KSidebar(
              mode: mode,
              onModeChanged: (value) => setState(() => mode = value),
              child: const Column(
                children: [
                  KSidebarHeader(
                    child: KSidebarToggle(railContent: KIcon(KIconName.orbit)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(IconButton), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is KIcon && widget.name == KIconName.orbit,
      ),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(mode, KSidebarMode.expanded);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(mode, KSidebarMode.rail);
  });
}
