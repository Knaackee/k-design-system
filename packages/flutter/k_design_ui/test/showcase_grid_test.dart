import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  final items = List.generate(
    6,
    (index) => KShowcaseGridItem(
      id: '$index',
      content: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          height: 140,
          child: KText('Decorative card $index', textWrap: KTextWrap.balance),
        ),
      ),
    ),
  );
  Widget app(Widget child, {bool reduced = false, double scale = 1}) =>
      MaterialApp(
        theme: kDesignTheme(),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(1000, 800),
            disableAnimations: reduced,
            textScaler: TextScaler.linear(scale),
          ),
          child: child,
        ),
      );
  testWidgets('non-loop entrance completes without retaining a ticker', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        SizedBox(
          height: 640,
          child: KShowcaseGrid(items: items, durationMs: 100, staggerMs: 10),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
    expect(
      tester
          .widgetList<Opacity>(find.byType(Opacity))
          .every((opacity) => opacity.opacity == 1),
      isTrue,
    );
  });
  testWidgets(
    'phone/tablet with balanced arbitrary content and active foreground',
    (tester) async {
      var taps = 0;
      for (final width in [390.0, 1000.0]) {
        await tester.pumpWidget(
          app(
            Center(
              child: SizedBox(
                width: width,
                height: 640,
                child: KShowcaseGrid(
                  items: items,
                  loop: true,
                  child: KButton(label: 'Start', onPressed: () => taps++),
                ),
              ),
            ),
            scale: 1.5,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Start'));
      }
      expect(taps, 2);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'pause freezes loop and resume moves it; decorative semantics absent',
    (tester) async {
      Widget build(bool animate) => app(
        SizedBox(
          height: 640,
          child: KShowcaseGrid(
            items: items,
            loop: true,
            animate: animate,
            child: const KText('Foreground'),
          ),
        ),
      );
      await tester.pumpWidget(build(true));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      List<double> transforms() => tester
          .widgetList<Transform>(find.byType(Transform))
          .map((w) => w.transform.storage[13])
          .toList();
      await tester.pumpWidget(build(false));
      final frozen = transforms();
      await tester.pump(const Duration(seconds: 2));
      expect(transforms(), frozen);
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(seconds: 2));
      expect(transforms(), isNot(frozen));
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('Decorative card 0'), findsNothing);
      expect(find.bySemanticsLabel('Foreground'), findsOneWidget);
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'reduced motion static; empty and unbounded layouts remain finite',
    (tester) async {
      await tester.pumpWidget(
        app(
          SingleChildScrollView(child: KShowcaseGrid(items: items, loop: true)),
          reduced: true,
        ),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.getSize(find.byType(KShowcaseGrid)).height, 512);
      await tester.pumpWidget(
        app(
          const SingleChildScrollView(
            child: KShowcaseGrid(items: [], loop: true),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
}
