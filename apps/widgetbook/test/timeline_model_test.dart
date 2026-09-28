import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/data_display/timeline/timeline_model.dart'
    show dayIndex, layoutTimeline;

void main() {
  const groups = [
    TimelineGroup(id: 'a', label: 'A'),
    TimelineGroup(id: 'b', label: 'B'),
  ];
  TimelineEntry entry(String id, int start, int end, {bool readOnly = false}) =>
      TimelineEntry(
        id: id,
        label: id,
        group: 'a',
        start: DateTime(2026, 9, start),
        end: DateTime(2026, 9, end),
        readOnly: readOnly,
      );

  test('rendered gap and point width reserve neighboring visual space', () {
    final point = TimelineEntry(
      id: 'milestone',
      label: 'Milestone',
      group: 'a',
      start: DateTime(2026, 9, 4),
    );
    final entries = [
      entry('first', 1, 3),
      entry('adjacent', 3, 4),
      point,
      entry('after-point', 5, 6),
    ];
    final visual = layoutTimeline(
      entries,
      groups,
      minimumGapDays: .25,
      pointSpanDays: 2.5,
    );
    expect(visual.entries.map((placement) => placement.lane), [0, 1, 0, 1]);
    expect(visual.laneCounts['a'], 2);
    final temporal = layoutTimeline(entries, groups);
    expect(temporal.entries.map((placement) => placement.lane), [0, 0, 0, 0]);
  });

  test('calendar arithmetic crosses month, leap year and DST boundaries', () {
    expect(addTimelineDays(DateTime(2026, 9, 30), 1), DateTime(2026, 10, 1));
    expect(addTimelineDays(DateTime(2024, 3, 1), -1), DateTime(2024, 2, 29));
    expect(
      dayIndex(DateTime(2026, 3, 30)) - dayIndex(DateTime(2026, 3, 28)),
      2,
    );
    expect(dayIndex(DateTime(1969, 12, 31)), -1);
  });

  test(
    'overlaps get separate lanes; adjacent exclusive ranges reuse a lane',
    () {
      final entries = [
        entry('long', 1, 7),
        entry('short', 1, 3),
        entry('next', 3, 7),
      ];
      final result = layoutTimeline(entries, groups);
      expect(result.entries.map((placement) => placement.entry.id), [
        'long',
        'short',
        'next',
      ]);
      expect(result.entries.map((placement) => placement.lane), [1, 0, 0]);
      expect(result.laneCounts, {'a': 2, 'b': 1});
    },
  );

  test('all shared fixture intervals pack without collisions', () {
    final json =
        jsonDecode(
              File('../../fixtures/timeline-reference.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final entries = (json['items'] as List)
        .map((value) => TimelineEntry.fromJson(value as Map<String, dynamic>))
        .toList();
    final groups = (json['groups'] as List)
        .map((value) => TimelineGroup.fromJson(value as Map<String, dynamic>))
        .toList();
    final layout = layoutTimeline(entries, groups);
    expect(layout.entries.length, 12);
    for (var i = 0; i < layout.entries.length; i++) {
      final a = layout.entries[i];
      for (var j = i + 1; j < layout.entries.length; j++) {
        final b = layout.entries[j];
        if (a.entry.group != b.entry.group || a.lane != b.lane) continue;
        final aEnd = dayIndex(a.entry.end ?? addTimelineDays(a.entry.start, 1));
        final bEnd = dayIndex(b.entry.end ?? addTimelineDays(b.entry.start, 1));
        expect(
          aEnd <= dayIndex(b.entry.start) || bEnd <= dayIndex(a.entry.start),
          isTrue,
          reason: '${a.entry.id} must not overlap ${b.entry.id}',
        );
      }
    }
  });

  test('controlled acceptance is immutable and preserves entry content', () {
    final original = [entry('editable', 1, 3), entry('other', 4, 6)];
    final next = TimelineEntry(
      id: 'editable',
      label: 'untrusted',
      group: 'b',
      start: DateTime(2026, 9, 2),
      end: DateTime(2026, 9, 4),
      tone: 'changed',
    );
    expect(
      identical(
        applyTimelineProposal(original, next, groups, accept: false),
        original,
      ),
      isTrue,
    );
    final accepted = applyTimelineProposal(original, next, groups);
    expect(original.first.start.day, 1);
    expect(accepted.first.start.day, 2);
    expect(accepted.first.group, 'b');
    expect(accepted.first.label, 'editable');
    expect(accepted.first.tone, 'primary');
    expect(identical(accepted[1], original[1]), isTrue);
    expect(() => accepted.clear(), throwsUnsupportedError);
  });

  test(
    'readonly, invalid range, unknown group and changed kind are rejected',
    () {
      final editable = entry('editable', 1, 3);
      final locked = entry('locked', 1, 3, readOnly: true);
      final original = [editable, locked];
      for (final proposal in [
        locked.copyWith(start: DateTime(2026, 9, 2)),
        editable.copyWith(end: DateTime(2026, 9, 1)),
        editable.copyWith(group: 'missing'),
        TimelineEntry(
          id: editable.id,
          label: editable.label,
          group: 'a',
          start: editable.start,
        ),
        entry('missing', 1, 2),
      ]) {
        expect(
          identical(
            applyTimelineProposal(original, proposal, groups),
            original,
          ),
          isTrue,
        );
      }
    },
  );

  test('point copies remain points and reserve a visible day', () {
    final point = TimelineEntry(
      id: 'point',
      label: 'Milestone',
      group: 'a',
      start: DateTime(2026, 9, 2),
    );
    expect(point.copyWith(end: DateTime(2026, 9, 4)).end, isNull);
    final layout = layoutTimeline([
      entry('range', 1, 3),
      point,
      entry('after', 3, 4),
    ], groups);
    expect(layout.entries.map((placement) => placement.lane), [0, 1, 0]);
  });
}
