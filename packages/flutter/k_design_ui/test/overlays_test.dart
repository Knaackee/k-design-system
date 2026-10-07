import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  for (final useHandle in [false, true]) {
    testWidgets(
      'phone sheet dismisses via ${useHandle ? 'handle' : 'content edge'} and respects close guard',
      (tester) async {
        tester.view.physicalSize = const Size(390, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var allowClose = false;
        var closeRequests = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => KAdaptiveDialog.show<void>(
                  context: context,
                  barrierDismissible: false,
                  builder: (route) => KAdaptiveDialog(
                    title: const Text('Guarded sheet'),
                    onClose: () {
                      closeRequests++;
                      if (allowClose) Navigator.pop(route);
                    },
                    child: const SizedBox(
                      height: 1800,
                      child: Text('Long content'),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(KIconButton), findsNothing);
        Future<void> pullDown() async {
          final start = useHandle
              ? tester.getTopLeft(find.byType(KBottomSheet)) +
                    const Offset(195, 16)
              : tester.getTopLeft(find.byType(SingleChildScrollView)) +
                    const Offset(195, 40);
          await tester.dragFrom(start, const Offset(0, 530));
          await tester.pumpAndSettle();
        }

        await pullDown();
        expect(closeRequests, greaterThan(0));
        expect(find.text('Guarded sheet'), findsOneWidget);
        allowClose = true;
        await pullDown();
        expect(find.text('Guarded sheet'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final width in [390.0, 1024.0]) {
    testWidgets(
      'adaptive modal at $width keeps actions visible with long content',
      (tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('Open adaptive'),
                  onPressed: () => KAdaptiveDialog.show<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (route) => KAdaptiveDialog(
                      title: const Text('Account'),
                      onClose: () => Navigator.pop(route),
                      actions: TextButton(
                        onPressed: () => Navigator.pop(route),
                        child: const Text('Save'),
                      ),
                      child: Column(
                        children: List.generate(
                          40,
                          (index) =>
                              SizedBox(height: 40, child: Text('Value $index')),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open adaptive'));
        await tester.pumpAndSettle();
        expect(
          find.byType(KBottomSheet),
          width < 600 ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(KDialog),
          width < 600 ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Save').hitTestable(), findsOneWidget);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -900),
        );
        await tester.pumpAndSettle();
        expect(find.text('Save').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(find.text('Account'), findsNothing);
      },
    );
  }
  for (final sheet in [false, true]) {
    testWidgets('${sheet ? 'sheet' : 'dialog'} opens and closes', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  if (sheet) {
                    KBottomSheet.show<void>(
                      context: context,
                      title: const Text('Title'),
                      child: const Text('Content'),
                    );
                  } else {
                    KDialog.show<void>(
                      context: context,
                      title: const Text('Title'),
                      child: const Text('Content'),
                    );
                  }
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Content'), findsOneWidget);
      if (sheet) {
        await tester.tapAt(const Offset(10, 10));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pumpAndSettle();
      expect(find.text('Content'), findsNothing);
    });
  }
}
