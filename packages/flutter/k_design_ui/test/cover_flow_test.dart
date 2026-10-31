import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  final items = List.generate(
    8,
    (i) => KCoverFlowItem(
      id: '$i',
      label: 'Figure $i',
      child: ColoredBox(key: ValueKey('art-$i'), color: Colors.blue),
    ),
  );
  Widget host(KCoverFlow child) => MaterialApp(home: Scaffold(body: child));

  testWidgets(
    'reveal completes, replays without replacing content and respects reduced motion',
    (tester) async {
      int completed = 0;
      Widget scene(int replay, {bool reduced = false}) => host(
        KCoverFlow(
          items: items,
          label: 'Figures',
          reveal: true,
          revealKey: replay,
          revealDurationMs: 200,
          revealStaggerMs: 30,
          reducedMotion: reduced,
          onRevealComplete: () => completed++,
        ),
      );
      await tester.pumpWidget(scene(0));
      final element = tester.element(find.byKey(const ValueKey('art-0')));
      await tester.pumpAndSettle();
      expect(completed, 1);
      await tester.pumpWidget(scene(0));
      await tester.pumpAndSettle();
      expect(completed, 1);
      await tester.pumpWidget(scene(1));
      await tester.pumpAndSettle();
      expect(completed, 2);
      expect(
        tester.element(find.byKey(const ValueKey('art-0'))),
        same(element),
      );
      await tester.pumpWidget(scene(2, reduced: true));
      await tester.pump();
      expect(completed, 3);
      expect(tester.hasRunningAnimations, false);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('consumer can enlarge covers within the viewport', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        KCoverFlow(
          items: items,
          label: 'Figures',
          itemWidth: 900,
          itemWidthFraction: .9,
          contentPadding: 0,
          showControls: false,
          showCaption: false,
        ),
      ),
    );
    final large = tester.getSize(find.byKey(const ValueKey('art-0'))).width;
    await tester.pumpWidget(
      host(
        KCoverFlow(
          items: items,
          label: 'Figures',
          itemWidth: 900,
          contentPadding: 0,
          showControls: false,
          showCaption: false,
        ),
      ),
    );
    final standard = tester.getSize(find.byKey(const ValueKey('art-0'))).width;
    expect(large, greaterThan(standard));
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection, bounded mounting and empty data', (tester) async {
    int? selected;
    await tester.pumpWidget(
      host(
        KCoverFlow(
          items: items,
          label: 'Figures',
          initialIndex: 1,
          sideAngle: 0,
          sideScale: .72,
          sideOffset: 100,
          onIndexChange: (i) => selected = i,
        ),
      ),
    );
    expect(find.byKey(const ValueKey('art-7')), findsNothing);
    await tester.tap(find.byTooltip('Next cover'));
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(find.text('Figure 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(host(const KCoverFlow(items: [], label: 'Empty')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('retained covers keep their elements when selection changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        KCoverFlow(
          items: items,
          label: 'Figures',
          keepMounted: true,
          visibleNeighbors: 1,
        ),
      ),
    );
    final element = tester.element(find.byKey(const ValueKey('art-7')));
    await tester.tap(find.byTooltip('Next cover'));
    await tester.pumpAndSettle();
    expect(tester.element(find.byKey(const ValueKey('art-7'))), same(element));
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe changes selection and vertical drag does not', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      host(
        KCoverFlow(
          items: items,
          label: 'Figures',
          itemWidth: 200,
          sideOffset: 100,
          reducedMotion: true,
          onIndexChange: (i) => selected = i,
        ),
      ),
    );
    await tester.drag(
      find.byKey(const ValueKey('art-0')),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
    expect(selected, isNull);
    await tester.drag(
      find.byKey(const ValueKey('art-0')),
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(tester.takeException(), isNull);
  });
}
