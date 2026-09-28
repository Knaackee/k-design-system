import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/data_display/gantt/gantt_painter.dart';

class Harness {
  List<GanttTask> tasks = [
    GanttTask(
      id: 'research',
      text: 'Research',
      start: DateTime(2026, 9, 23),
      end: DateTime(2026, 9, 26),
      type: 'task',
      progress: 50,
    ),
  ];
  final proposals = <GanttTask>[], opens = <String>[], scrolls = <Offset>[];
  bool accept = true;
  String? selected;
  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(brightness: Brightness.dark),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, update) => KGantt(
              tasks: tasks,
              links: const [],
              start: DateTime(2026, 9, 21),
              end: DateTime(2026, 10, 17),
              selectedId: selected,
              onSelect: (id) => update(() => selected = id),
              onOpen: opens.add,
              onScroll: scrolls.add,
              onPropose: (next) {
                proposals.add(next);
                update(
                  () => tasks = applyGanttProposal(tasks, next, accept: accept),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Rect rect(WidgetTester tester) => tester.getRect(
    find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == 'Research',
    ),
  );
  GanttPainter painter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((w) => w.painter)
      .whereType<GanttPainter>()
      .single;
  Future<TestGesture> hold(
    WidgetTester tester,
    PointerDeviceKind kind, {
    Offset? at,
  }) async {
    final gesture = await tester.startGesture(
      at ?? rect(tester).center,
      kind: kind,
    );
    await tester.pump(const Duration(milliseconds: 510));
    return gesture;
  }
}

void main() {
  for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
    testWidgets('$kind distinguishes short tap, pan, hold and accepted move', (
      tester,
    ) async {
      final h = Harness();
      await h.mount(tester);
      await tester.tapAt(h.rect(tester).center);
      await tester.pump();
      expect(h.opens, ['research']);
      final pan = await tester.startGesture(const Offset(300, 200), kind: kind);
      await pan.moveBy(const Offset(-64, 0));
      await pan.up();
      await tester.pump();
      expect(h.scrolls.last.dx, 64);
      expect(h.proposals, isEmpty);
      final drag = await h.hold(tester, kind);
      expect(h.painter(tester).editing, 'research');
      await drag.moveBy(const Offset(32, 0));
      await tester.pump();
      expect(h.proposals, isEmpty);
      expect(h.painter(tester).preview!.start, DateTime(2026, 9, 24));
      await drag.up();
      await tester.pump();
      expect(h.proposals, hasLength(1));
      expect(h.tasks.single.start, DateTime(2026, 9, 24));
      expect(h.painter(tester).preview, isNull);
      expect(h.painter(tester).editing, isNull);
    });
  }
  testWidgets(
    'both resize edges remain correct after scrolling; rejected proposals do not leak',
    (tester) async {
      final h = Harness();
      await h.mount(tester);
      await tester.dragFrom(const Offset(330, 220), const Offset(-64, 0));
      await tester.pump();
      var activation = await h.hold(tester, PointerDeviceKind.mouse);
      await activation.up();
      await tester.pump();
      var rect = h.rect(tester);
      var edge = await tester.startGesture(
        Offset(rect.left, rect.center.dy),
        kind: PointerDeviceKind.mouse,
      );
      await edge.moveBy(const Offset(-32, 0));
      await tester.pump();
      expect(h.painter(tester).preview!.start, DateTime(2026, 9, 22));
      await edge.up();
      await tester.pump();
      expect(h.tasks.single.start, DateTime(2026, 9, 22));
      h.accept = false;
      activation = await h.hold(tester, PointerDeviceKind.mouse);
      await activation.up();
      await tester.pump();
      rect = h.rect(tester);
      edge = await tester.startGesture(
        Offset(rect.right - 1, rect.center.dy),
        kind: PointerDeviceKind.mouse,
      );
      await edge.moveBy(const Offset(64, 0));
      await tester.pump();
      expect(h.painter(tester).preview!.end, DateTime(2026, 9, 28));
      await edge.up();
      await tester.pump();
      expect(h.tasks.single.end, DateTime(2026, 9, 26));
      expect(h.painter(tester).preview, isNull);
      h.accept = true;
      final move = await h.hold(tester, PointerDeviceKind.mouse);
      await move.moveBy(const Offset(32, 0));
      await move.up();
      await tester.pump();
      expect(h.tasks.single.start, DateTime(2026, 9, 23));
    },
  );
  testWidgets('Escape and pointer cancel discard active previews', (
    tester,
  ) async {
    final h = Harness();
    await h.mount(tester);
    var drag = await h.hold(tester, PointerDeviceKind.touch);
    await drag.moveBy(const Offset(32, 0));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await drag.up();
    expect(h.proposals, isEmpty);
    expect(h.painter(tester).preview, isNull);
    drag = await h.hold(tester, PointerDeviceKind.touch);
    await drag.moveBy(const Offset(32, 0));
    await drag.cancel();
    await tester.pump();
    expect(h.proposals, isEmpty);
    expect(h.painter(tester).preview, isNull);
  });
}
