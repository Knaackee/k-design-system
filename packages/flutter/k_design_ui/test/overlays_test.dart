import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets(
    'compact bottom sheet constrains tall content and keeps actions reachable',
    (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: KBottomSheet(
              title: const Text('Details'),
              actions: TextButton(
                onPressed: () {},
                child: const Text('Confirm'),
              ),
              child: const SizedBox(height: 1000, child: Text('Tall detail')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -1100),
      );
      await tester.pumpAndSettle();
      expect(find.text('Confirm').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('compact phone dialog preserves labeled close action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var closes = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => KAdaptiveDialog.show<void>(
                context: context,
                builder: (route) => KAdaptiveDialog(
                  title: const Text('Details'),
                  expandBody: false,
                  closeLabel: 'Close details',
                  onClose: () {
                    closes++;
                    Navigator.of(route).pop();
                  },
                  child: const Text('Compact content'),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final close = find.byTooltip('Close details');
    expect(close.hitTestable(), findsOneWidget);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(closes, 1);
    expect(find.text('Compact content'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final alreadyResized in [false, true]) {
    testWidgets(
      'tablet dialog reserves keyboard once with resized parent=$alreadyResized',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const lowerField = Key('lower field');
        Widget dialog() => KAdaptiveDialog(
          title: const Text('Configuration'),
          actions: TextButton(onPressed: () {}, child: const Text('Save')),
          child: const Column(
            children: [
              TextField(decoration: InputDecoration(labelText: 'Name')),
              SizedBox(height: 1000),
              TextField(key: lowerField),
            ],
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: alreadyResized
                    ? dialog()
                    : TextButton(
                        onPressed: () => KAdaptiveDialog.show<void>(
                          context: context,
                          builder: (_) => dialog(),
                        ),
                        child: const Text('Open'),
                      ),
              ),
            ),
          ),
        );
        if (!alreadyResized) {
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byType(TextField).first);
        tester.view.viewInsets = const FakeViewPadding(bottom: 283);
        await tester.pumpAndSettle();
        final surface = tester.getRect(find.byType(KSurface));
        expect(surface.height, closeTo(850 - 283, .01));
        expect(surface.bottom, lessThanOrEqualTo(850 - 283));
        expect(tester.getBottomLeft(find.text('Save')).dy, lessThan(850 - 283));
        expect(find.text('Save').hitTestable(), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(lowerField),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(lowerField));
        await tester.enterText(find.byKey(lowerField), 'Visible input');
        await tester.pumpAndSettle();
        final field = tester.getRect(find.byKey(lowerField));
        expect(field.bottom, lessThan(850 - 283));
        expect(find.text('Visible input').hitTestable(), findsOneWidget);
        expect(find.text('Save').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('dialog honors consumer height without changing the default', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> render(double? maxHeight) => tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KDialog(
          title: const Text('Editor'),
          expandBody: true,
          maxHeight: maxHeight,
          actions: const Text('Save'),
          child: const SizedBox.expand(),
        ),
      ),
    );
    await render(null);
    expect(tester.getSize(find.byType(KSurface)).height, 720);
    await render(852);
    expect(tester.getSize(find.byType(KSurface)).height, 852);
    expect(tester.getBottomLeft(find.text('Save')).dy, lessThan(900));
    expect(tester.takeException(), isNull);
  });
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
          await tester.timedDragFrom(
            start,
            const Offset(0, 300),
            const Duration(milliseconds: 800),
          );
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
