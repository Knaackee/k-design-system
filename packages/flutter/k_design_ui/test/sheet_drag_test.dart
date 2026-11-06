import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

// Decision 0015: one drag model for every sheet. A list at its top hands
// the drag to the sheet, and a dismissed sheet leaves from the finger
// position without jumping back first.
void main() {
  Future<void> open(WidgetTester tester, {required bool adaptive}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final rows = Column(
      children: [
        for (var i = 0; i < 40; i++)
          SizedBox(height: 44, child: Text('Row $i')),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: KLocalization(
          locale: 'en',
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => adaptive
                      ? KAdaptiveDialog.show<void>(
                          context: context,
                          title: const Text('Share'),
                          child: rows,
                        )
                      : KBottomSheet.show<void>(
                          context: context,
                          title: const Text('Share'),
                          child: rows,
                        ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  for (final adaptive in [false, true]) {
    final name = adaptive ? 'KAdaptiveDialog' : 'KBottomSheet';
    testWidgets('$name: dragging a list at its top dismisses the sheet', (
      tester,
    ) async {
      await open(tester, adaptive: adaptive);
      expect(find.text('Share'), findsOneWidget);
      await tester.fling(find.text('Row 3'), const Offset(0, 400), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsNothing);
    });

    testWidgets('$name: a scrolled list scrolls back before the sheet moves', (
      tester,
    ) async {
      await open(tester, adaptive: adaptive);
      await tester.drag(find.text('Row 3'), const Offset(0, -300));
      await tester.pumpAndSettle();
      final surface = find
          .descendant(
            of: find.byType(KBottomSheet),
            matching: find.byType(Material),
          )
          .first;
      final before = tester.getTopLeft(surface).dy;
      await tester.drag(find.text('Row 12'), const Offset(0, 120));
      await tester.pumpAndSettle();
      // The list scrolled back; the sheet itself did not move or close.
      expect(tester.getTopLeft(surface).dy, before);
      expect(find.byType(KBottomSheet), findsOneWidget);
    });

    testWidgets('$name: the exit continues from the finger position', (
      tester,
    ) async {
      await open(tester, adaptive: adaptive);
      final start = tester.getTopLeft(find.text('Share')).dy;
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Share')),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 40));
        await tester.pump(const Duration(milliseconds: 16));
      }
      final released = tester.getTopLeft(find.text('Share')).dy;
      expect(released, greaterThan(start + 300));
      await gesture.up();
      var last = released;
      for (var frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (find.text('Share').evaluate().isEmpty) break;
        final y = tester.getTopLeft(find.text('Share')).dy;
        expect(y, greaterThanOrEqualTo(last - 0.5), reason: 'frame $frame');
        last = y;
      }
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsNothing);
    });
  }
}
