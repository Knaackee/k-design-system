import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'two actions remain readable below the message at phone width and 2x text',
    (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opened = 0, undone = 0;
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
            body: Center(
              child: SizedBox(
                width: 358,
                child: KSnackbar(
                  message: const Text('Priorität geändert'),
                  icon: const KIcon(KIconName.circleCheck),
                  onDismiss: () {},
                  action: KInline(
                    gap: KLayoutGap.action,
                    wrap: true,
                    children: [
                      KButton(label: 'Öffnen', onPressed: () => opened++),
                      KButton(label: 'Rückgängig', onPressed: () => undone++),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final message = tester.getRect(find.text('Priorität geändert'));
      final open = tester.getRect(find.text('Öffnen'));
      final undo = tester.getRect(find.text('Rückgängig'));
      expect(open.top, greaterThan(message.bottom));
      expect(undo.top, greaterThan(message.bottom));
      expect(open.left, greaterThanOrEqualTo(0));
      expect(undo.right, lessThanOrEqualTo(390));
      await tester.tap(find.text('Öffnen'));
      await tester.tap(find.text('Rückgängig'));
      expect(opened, 1);
      expect(undone, 1);
    },
  );

  testWidgets('more than five queued actionable notifications preserve FIFO', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Builder(
          builder: (c) {
            context = c;
            return const Scaffold();
          },
        ),
      ),
    );
    final controllers = [
      for (var i = 0; i < 8; i++)
        KSnackbar.show(
          context: context,
          message: Text('Operation $i'),
          duration: Duration.zero,
          action: KButton(label: 'Rückgängig', onPressed: () {}),
        ),
    ];
    for (var i = 0; i < 8; i++) {
      await tester.pumpAndSettle();
      expect(find.text('Operation $i'), findsOneWidget);
      controllers[i].dismiss();
    }
    await tester.pumpAndSettle();
  });
}
