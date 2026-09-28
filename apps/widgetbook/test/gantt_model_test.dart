import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/data_display/gantt/gantt_model.dart'
    show ganttDayIndex, moveGanttTask;

void main() {
  GanttTask task({
    String id = 'task',
    String? parent,
    String type = 'task',
    int start = 1,
    int? end = 4,
    double progress = 50,
    bool readOnly = false,
  }) => GanttTask(
    id: id,
    text: id,
    parent: parent,
    type: type,
    start: DateTime(2026, 9, start),
    end: end == null ? null : DateTime(2026, 9, end),
    progress: progress,
    readOnly: readOnly,
  );

  test('calendar arithmetic crosses leap, month and DST boundaries', () {
    expect(ganttAddDays(DateTime(2024, 3, 1), -1), DateTime(2024, 2, 29));
    expect(ganttAddDays(DateTime(2026, 9, 30), 1), DateTime(2026, 10, 1));
    expect(
      ganttDayIndex(DateTime(2026, 3, 30)) -
          ganttDayIndex(DateTime(2026, 3, 28)),
      2,
    );
    expect(ganttDayIndex(DateTime(1969, 12, 31)), -1);
  });

  test('move preserves duration; both resize edges clamp to one day', () {
    final source = task();
    final moved = moveGanttTask(source, 30, 'move');
    expect(moved.start, DateTime(2026, 10, 1));
    expect(moved.end, DateTime(2026, 10, 4));
    final start = moveGanttTask(source, 10, 'start');
    expect(start.start, DateTime(2026, 9, 3));
    expect(start.end, source.end);
    final end = moveGanttTask(source, -10, 'end');
    expect(end.start, source.start);
    expect(end.end, DateTime(2026, 9, 2));
    expect(source.start, DateTime(2026, 9, 1));
    final milestone = moveGanttTask(
      task(type: 'milestone', end: null),
      2,
      'move',
    );
    expect(milestone.start, DateTime(2026, 9, 3));
    expect(milestone.end, isNull);
  });

  test(
    'acceptance preserves canonical content and untouched record identity',
    () {
      final source = [task(parent: 'group'), task(id: 'other')];
      final proposed = GanttTask(
        id: 'task',
        text: 'Forged',
        parent: 'other',
        type: 'summary',
        start: DateTime(2026, 9, 3),
        end: DateTime(2026, 9, 8),
        progress: 80,
        readOnly: true,
      );
      final result = applyGanttProposal(source, proposed);
      expect(result.first.text, 'task');
      expect(result.first.parent, 'group');
      expect(result.first.type, 'task');
      expect(result.first.readOnly, isFalse);
      expect(result.first.start, proposed.start);
      expect(result.first.end, proposed.end);
      expect(result.first.progress, 80);
      expect(identical(result.last, source.last), isTrue);
      expect(source.first.progress, 50);
      expect(() => result.clear(), throwsUnsupportedError);
      expect(
        identical(applyGanttProposal(source, proposed, accept: false), source),
        isTrue,
      );
    },
  );

  test('invalid proposals, summaries and read-only tasks reject unchanged', () {
    final source = [task()];
    for (final next in [
      task(id: 'missing'),
      task(end: 1),
      task(end: null),
      task(progress: double.nan),
      task(progress: double.infinity),
      task(progress: -1),
      task(progress: 101),
      task().copyWith(start: DateTime(2026, 9, 1, 12)),
    ]) {
      expect(identical(applyGanttProposal(source, next), source), isTrue);
    }
    for (final current in [task(readOnly: true), task(type: 'summary')]) {
      final records = [current];
      expect(
        identical(applyGanttProposal(records, task(start: 2)), records),
        isTrue,
      );
    }
    final milestones = [task(type: 'milestone', end: null)];
    expect(
      identical(applyGanttProposal(milestones, task()), milestones),
      isTrue,
    );
    expect(
      applyGanttProposal(
        milestones,
        task(type: 'milestone', end: null, start: 2),
      ).first.start,
      DateTime(2026, 9, 2),
    );
  });

  test(
    'nested summaries weight leaf duration and include milestone boundary',
    () {
      final records = [
        task(id: 'root', type: 'summary'),
        task(id: 'nested', parent: 'root', type: 'summary'),
        task(id: 'short', parent: 'root', start: 2, end: 4, progress: 100),
        task(id: 'long', parent: 'nested', start: 4, end: 10, progress: 0),
        task(
          id: 'point',
          parent: 'nested',
          type: 'milestone',
          start: 12,
          end: null,
          progress: 100,
        ),
      ];
      final summaries = summarizeGanttTasks(records);
      expect(summaries.first.start, DateTime(2026, 9, 2));
      expect(summaries.first.end, DateTime(2026, 9, 13));
      expect(summaries.first.progress, 25);
      expect(summaries[1].progress, 0);
      expect(records.first.end, DateTime(2026, 9, 4));
      expect(identical(summaries[2], records[2]), isTrue);
    },
  );

  test('point-only summaries average progress and cycles terminate', () {
    final summaries = summarizeGanttTasks([
      task(id: 'a', parent: 'b', type: 'summary'),
      task(id: 'b', parent: 'a', type: 'summary'),
      task(id: 'p', parent: 'b', type: 'milestone', end: null, progress: 25),
      task(id: 'q', parent: 'a', type: 'milestone', end: null, progress: 50),
      task(id: 'empty', type: 'summary'),
    ]);
    expect(summaries.first.progress, 38);
    expect(summaries[1].progress, 38);
    expect(summaries.last.progress, 50);
  });

  test('shared fixture parses with matching summaries and dependency IDs', () {
    final fixture =
        jsonDecode(
              File('../../fixtures/gantt-reference.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final tasks = (fixture['tasks'] as List)
        .map((value) => GanttTask.fromJson(value as Map<String, dynamic>))
        .toList();
    final links = (fixture['links'] as List)
        .map((value) => GanttLink.fromJson(value as Map<String, dynamic>))
        .toList();
    final summaries = summarizeGanttTasks(
      tasks,
    ).where((task) => task.type == 'summary').toList();
    expect(tasks.length, 13);
    expect(links.length, 7);
    expect(summaries.map((task) => task.progress), [60, 25, 5]);
    expect(summaries.last.end, DateTime(2026, 10, 17));
    final ids = tasks.map((task) => task.id).toSet();
    expect(
      links.every(
        (link) => ids.contains(link.source) && ids.contains(link.target),
      ),
      isTrue,
    );
    final invalid = Map<String, dynamic>.from(
      (fixture['tasks'] as List).first as Map,
    );
    invalid['start'] = '2026-02-30';
    expect(() => GanttTask.fromJson(invalid), throwsFormatException);
  });
}
