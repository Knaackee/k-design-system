import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_widgetbook/timeline/timeline_canvas.dart';
import 'package:k_design_widgetbook/timeline/timeline_model.dart';

class _Harness {
  _Harness({
    this.accept = true,
    this.readOnly = false,
    this.outerScroll = false,
  });
  final bool accept;
  final bool readOnly;
  final bool outerScroll;
  final scrollController = ScrollController();
  final proposals = <TimelineEntry>[];
  final opened = <String>[];
  final windows = <DateTime>[];
  String? selected;
  late List<TimelineEntry> items = [
    TimelineEntry(
      id: 'research',
      label: 'Research',
      group: 'design',
      start: DateTime(2026, 9, 22),
      end: DateTime(2026, 9, 25),
      readOnly: readOnly,
    ),
  ];
  DateTime start = DateTime(2026, 9, 21), end = DateTime(2026, 9, 28);
  List<TimelineGroup> groups = [
    const TimelineGroup(id: 'design', label: 'Design'),
  ];
  Future<void> mount(
    WidgetTester tester, {
    double width = 375,
    Brightness brightness = Brightness.light,
    KDensity density = KDensity.standard,
  }) async {
    tester.view.physicalSize = Size(width, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(
          brightness: brightness,
          configuration: KDesignConfiguration(density: density),
        ),
        home: Scaffold(
          body: Builder(
            builder: (_) {
              final canvas = StatefulBuilder(
                builder: (context, setState) => TimelineCanvas(
                  items: items,
                  groups: groups,
                  selectedId: selected,
                  onSelect: (id) => setState(() => selected = id),
                  onItemOpen: opened.add,
                  onPropose: (next) {
                    proposals.add(next);
                    setState(
                      () => items = applyTimelineProposal(
                        items,
                        next,
                        groups,
                        accept: accept,
                      ),
                    );
                  },
                  windowStart: start,
                  windowEnd: end,
                  onWindowChange: (nextStart, nextEnd) {
                    windows.add(nextStart);
                    setState(() {
                      start = nextStart;
                      end = nextEnd;
                    });
                  },
                  today: DateTime(2026, 9, 25),
                ),
              );
              return outerScroll
                  ? SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        children: [canvas, const SizedBox(height: 1000)],
                      ),
                    )
                  : canvas;
            },
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Rect rect(WidgetTester tester) => tester.getRect(
    find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == 'Research',
    ),
  );
  double get dayWidth => (375 - 96) / 7;
  Future<TestGesture> hold(WidgetTester tester, PointerDeviceKind kind) async {
    final gesture = await tester.startGesture(rect(tester).center, kind: kind);
    await tester.pump(const Duration(milliseconds: 550));
    return gesture;
  }
}

void main() {
  for (final brightness in Brightness.values) {
    for (final density in [KDensity.dense, KDensity.spacious]) {
      testWidgets('desktop geometry ${brightness.name} ${density.name}', (
        tester,
      ) async {
        final h = _Harness();
        await h.mount(
          tester,
          width: 1024,
          brightness: brightness,
          density: density,
        );
        final canvasRect = tester.getRect(find.byType(TimelineCanvas));
        expect(canvasRect.size, const Size(1024, 420));
        final item = h.rect(tester);
        expect(canvasRect.contains(item.topLeft), isTrue);
        expect(canvasRect.contains(item.bottomRight), isTrue);
        expect(item.left, greaterThan(canvasRect.left + 120));
        final hold = await h.hold(tester, PointerDeviceKind.mouse);
        await hold.up();
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(h.selected, 'research');
      });
    }
  }
  testWidgets('outer scroll view cannot steal held vertical group movement', (
    tester,
  ) async {
    final h = _Harness(outerScroll: true);
    h.groups = [
      const TimelineGroup(id: 'design', label: 'Design'),
      const TimelineGroup(id: 'target', label: 'Target'),
    ];
    h.items.add(
      TimelineEntry(
        id: 'target',
        label: 'Target marker',
        group: 'target',
        start: DateTime(2026, 9, 22),
        end: DateTime(2026, 9, 25),
        readOnly: true,
      ),
    );
    await h.mount(tester);
    final target = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Target marker',
      ),
    );
    final hold = await h.hold(tester, PointerDeviceKind.touch);
    await hold.moveTo(target.center);
    await tester.pump();
    await hold.up();
    await tester.pump();
    expect(h.proposals.single.group, 'target');
    expect(h.scrollController.offset, 0);
  });
  testWidgets(
    'vertical canvas panning scrolls its groups without scrolling ancestor',
    (tester) async {
      final h = _Harness(outerScroll: true);
      h.groups = [
        const TimelineGroup(id: 'design', label: 'Design'),
        for (var i = 0; i < 8; i++)
          TimelineGroup(id: 'group$i', label: 'Group $i'),
      ];
      h.items.add(
        TimelineEntry(
          id: 'marker',
          label: 'Scroll marker',
          group: 'group2',
          start: DateTime(2026, 9, 22),
          end: DateTime(2026, 9, 25),
        ),
      );
      await h.mount(tester);
      final marker = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Scroll marker',
      );
      final before = tester.getRect(marker);
      final gesture = await tester.startGesture(const Offset(330, 350));
      await gesture.moveBy(const Offset(0, -70));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(tester.getRect(marker).top, closeTo(before.top - 70, .01));
      expect(h.scrollController.offset, 0);
      expect(h.proposals, isEmpty);
    },
  );
  for (final escape in [true, false]) {
    testWidgets(
      '${escape ? 'Escape' : 'pointer cancellation'} discards the transient proposal',
      (tester) async {
        final h = _Harness();
        await h.mount(tester);
        final before = h.rect(tester);
        final hold = await h.hold(tester, PointerDeviceKind.touch);
        await hold.moveBy(Offset(h.dayWidth, 0));
        await tester.pump();
        if (escape) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await hold.up();
        } else {
          await hold.cancel();
        }
        await tester.pump();
        expect(h.proposals, isEmpty);
        expect(h.rect(tester), before);
      },
    );
  }
  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('$kind short press opens details without editing', (
      tester,
    ) async {
      final h = _Harness();
      await h.mount(tester);
      final gesture = await tester.startGesture(
        h.rect(tester).center,
        kind: kind,
      );
      await tester.pump(const Duration(milliseconds: 80));
      await gesture.up();
      await tester.pump();
      expect(h.opened, ['research']);
      expect(h.proposals, isEmpty);
    });
    testWidgets('$kind long press then same gesture moves one calendar day', (
      tester,
    ) async {
      final h = _Harness();
      await h.mount(tester);
      final gesture = await h.hold(tester, kind);
      expect(h.selected, 'research');
      expect(h.opened, isEmpty);
      await gesture.moveBy(Offset(h.dayWidth, 0));
      await tester.pump();
      expect(h.proposals, isEmpty);
      await gesture.up();
      await tester.pump();
      expect(h.proposals.single.start, DateTime(2026, 9, 23));
      expect(h.items.single.end, DateTime(2026, 9, 26));
      expect(h.windows, isEmpty);
    });
    testWidgets('$kind activation persists for a subsequent move gesture', (
      tester,
    ) async {
      final h = _Harness();
      await h.mount(tester);
      final hold = await h.hold(tester, kind);
      await hold.up();
      await tester.pump();
      final move = await tester.startGesture(h.rect(tester).center, kind: kind);
      await move.moveBy(Offset(h.dayWidth, 0));
      await move.up();
      await tester.pump();
      expect(h.proposals.single.start, DateTime(2026, 9, 23));
      expect(h.opened, isEmpty);
    });
  }
  for (final left in [true, false]) {
    testWidgets(
      '${left ? 'left' : 'right'} handle resizes without moving opposite edge',
      (tester) async {
        final h = _Harness();
        await h.mount(tester);
        final hold = await h.hold(tester, PointerDeviceKind.touch);
        await hold.up();
        await tester.pump();
        final rect = h.rect(tester);
        final resize = await tester.startGesture(
          Offset(left ? rect.left : rect.right, rect.center.dy),
        );
        await resize.moveBy(Offset(left ? -h.dayWidth : h.dayWidth, 0));
        await tester.pump();
        await resize.up();
        await tester.pump();
        expect(h.proposals.single.start, DateTime(2026, 9, left ? 21 : 22));
        expect(h.proposals.single.end, DateTime(2026, 9, left ? 25 : 26));
      },
    );
  }
  testWidgets(
    'rejection restores geometry and next gesture has no stale delta',
    (tester) async {
      final h = _Harness(accept: false);
      await h.mount(tester);
      final before = h.rect(tester);
      final first = await h.hold(tester, PointerDeviceKind.touch);
      await first.moveBy(Offset(h.dayWidth, 0));
      await first.up();
      await tester.pump();
      expect(h.rect(tester), before);
      final second = await h.hold(tester, PointerDeviceKind.touch);
      await second.up();
      await tester.pump();
      expect(h.proposals.length, 1);
      final third = await tester.startGesture(h.rect(tester).center);
      await third.moveBy(Offset(-h.dayWidth, 0));
      await third.up();
      await tester.pump();
      expect(h.proposals.length, 2);
      expect(h.proposals.last.start, DateTime(2026, 9, 21));
      expect(h.rect(tester), before);
    },
  );
  testWidgets('movement before long press pans instead of changing the item', (
    tester,
  ) async {
    final h = _Harness();
    await h.mount(tester);
    final pan = await tester.startGesture(h.rect(tester).center);
    await pan.moveBy(Offset(-h.dayWidth, 0));
    await tester.pump(const Duration(milliseconds: 600));
    await pan.up();
    await tester.pump();
    expect(h.windows.single, DateTime(2026, 9, 22));
    expect(h.proposals, isEmpty);
    expect(h.opened, isEmpty);
  });
  testWidgets('read only item never produces a move proposal', (tester) async {
    final h = _Harness(readOnly: true);
    await h.mount(tester);
    final hold = await h.hold(tester, PointerDeviceKind.touch);
    await hold.moveBy(Offset(h.dayWidth, 0));
    await hold.up();
    await tester.pump();
    expect(h.proposals, isEmpty);
    expect(h.items.single.start, DateTime(2026, 9, 22));
  });
}
