import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gantt/flutter_gantt.dart';
import 'package:flutter_gantt/src/widgets/row.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('a second drag without movement must not reuse previous delta', (
    tester,
  ) async {
    final activity = GanttActivity(
      key: 'one',
      start: DateTime(2026, 9, 3),
      end: DateTime(2026, 9, 5),
      title: 'Task',
    );
    final controller = GanttController(
      startDate: DateTime(2026, 9, 1),
      daysViews: 10,
    );
    controller.gridWidth = 500;
    final proposals = <DateTime?>[];
    controller.addOnActivityChangedListener(
      (item, start, end) => proposals.add(start),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: controller),
              Provider.value(value: const GanttTheme()),
            ],
            child: const SizedBox.shrink(),
            builder: (context, child) => SizedBox(
              width: 500,
              height: 24,
              child: GanttActivityRow(activity: activity),
            ),
          ),
        ),
      ),
    );
    final drag = tester
        .widgetList<LongPressDraggable<GanttActivity>>(
          find.byType(LongPressDraggable<GanttActivity>),
        )
        .first;
    drag.onDragStarted!();
    drag.onDragUpdate!(
      DragUpdateDetails(
        globalPosition: const Offset(150, 12),
        delta: Offset.zero,
      ),
    );
    drag.onDragUpdate!(
      DragUpdateDetails(
        globalPosition: const Offset(200, 12),
        delta: const Offset(50, 0),
      ),
    );
    drag.onDragEnd!(
      DraggableDetails(
        wasAccepted: false,
        velocity: Velocity.zero,
        offset: Offset.zero,
      ),
    );
    expect(proposals.map((d) => [d!.year, d.month, d.day]).toList(), [
      [2026, 9, 4],
    ]);
    // Consumer rejects the proposal. Canonical range stays unchanged.
    drag.onDragStarted!();
    drag.onDragEnd!(
      DraggableDetails(
        wasAccepted: false,
        velocity: Velocity.zero,
        offset: Offset.zero,
      ),
    );
    expect(
      proposals.length,
      1,
      reason:
          'Starting and ending a drag without moving must not propose the old one-day displacement again.',
    );
  });
}
