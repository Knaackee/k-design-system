import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final contextMenu in [false, true]) {
    testWidgets(
      '${contextMenu ? 'context' : 'button'} menu consumes outside tap',
      (tester) async {
        var backgroundTaps = 0;
        final actions = [
          KMenuAction(id: 'copy', label: 'Copy', onSelect: () {}),
        ];
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Scaffold(
              body: Column(
                children: [
                  if (contextMenu)
                    KContextMenu(
                      label: 'Actions',
                      actions: actions,
                      child: const SizedBox(
                        width: 200,
                        height: 60,
                        child: Text('Target'),
                      ),
                    )
                  else
                    KMenuButton(label: 'Actions', actions: actions),
                  const Spacer(),
                  TextButton(
                    onPressed: () => backgroundTaps++,
                    child: const Text('Underlying row'),
                  ),
                ],
              ),
            ),
          ),
        );
        if (contextMenu) {
          await tester.longPress(find.text('Target'));
        } else {
          await tester.tap(find.text('Actions'));
        }
        await tester.pumpAndSettle();
        expect(find.text('Copy'), findsOneWidget);
        await tester.tap(find.text('Underlying row'));
        await tester.pumpAndSettle();
        expect(find.text('Copy'), findsNothing);
        expect(backgroundTaps, 0);
        await tester.tap(find.text('Underlying row'));
        await tester.pumpAndSettle();
        expect(backgroundTaps, 1);
      },
    );

    testWidgets(
      '${contextMenu ? 'context' : 'button'} nested menu scrolls on a short screen with large text',
      (tester) async {
        tester.view.physicalSize = const Size(390, 400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var selected = false;
        final actions = [
          KMenuAction(
            id: 'projects',
            label: 'Projects',
            children: [
              for (var i = 0; i < 20; i++)
                KMenuAction(
                  id: 'project-$i',
                  label: 'Project $i',
                  onSelect: () => selected = true,
                ),
            ],
          ),
        ];
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: contextMenu
                  ? KContextMenu(
                      label: 'Actions',
                      actions: actions,
                      child: const SizedBox(
                        width: 200,
                        height: 60,
                        child: Text('Target'),
                      ),
                    )
                  : KMenuButton(label: 'Actions', actions: actions),
            ),
          ),
        );
        if (contextMenu) {
          await tester.longPress(find.text('Target'));
        } else {
          await tester.tap(find.text('Actions'));
        }
        await tester.pumpAndSettle();
        await tester.tap(find.text('Projects'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Project 19'));
        await tester.pumpAndSettle();
        final last = tester.getRect(find.text('Project 19'));
        expect(last.top, greaterThanOrEqualTo(0));
        expect(last.bottom, lessThanOrEqualTo(400));
        await tester.tap(find.text('Project 19'));
        await tester.pumpAndSettle();
        expect(selected, isTrue);
        expect(find.text('Projects'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
