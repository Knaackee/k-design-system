import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class CalendarDemoEvent {
  const CalendarDemoEvent({
    required this.id,
    required this.title,
    required this.project,
    required this.start,
    required this.end,
    this.allDay = false,
  });
  final String id, title, project;
  final DateTime? start, end;
  final bool allDay;
  CalendarDemoEvent copyWith({
    String? title,
    DateTime? start,
    DateTime? end,
    bool? allDay,
  }) => CalendarDemoEvent(
    id: id,
    title: title ?? this.title,
    project: project,
    start: start ?? this.start,
    end: end ?? this.end,
    allDay: allDay ?? this.allDay,
  );
}

List<CalendarDemoEvent> calendarDemoEvents() => [
  CalendarDemoEvent(
    id: 'CAL-101',
    title: 'Design review',
    project: 'Orbit',
    start: DateTime.parse('2026-09-21T09:00:00+02:00'),
    end: DateTime.parse('2026-09-21T10:30:00+02:00'),
  ),
  CalendarDemoEvent(
    id: 'CAL-102',
    title: 'Planning',
    project: 'Workspace',
    start: DateTime.parse('2026-09-22T11:00:00+02:00'),
    end: DateTime.parse('2026-09-22T12:00:00+02:00'),
  ),
  CalendarDemoEvent(
    id: 'CAL-103',
    title: 'Customer call',
    project: 'Orbit',
    start: DateTime.parse('2026-09-24T14:00:00+02:00'),
    end: DateTime.parse('2026-09-24T15:30:00+02:00'),
  ),
  const CalendarDemoEvent(
    id: 'CAL-104',
    title: 'Unscheduled research',
    project: 'Research',
    start: null,
    end: null,
  ),
  CalendarDemoEvent(
    id: 'CAL-105',
    title: 'Release preparation',
    project: 'Orbit',
    start: DateTime.utc(2026, 9, 21),
    end: DateTime.utc(2026, 9, 24),
    allDay: true,
  ),
  CalendarDemoEvent(
    id: 'CAL-106',
    title: 'Team workshop',
    project: 'Workspace',
    start: DateTime.utc(2026, 9, 22),
    end: DateTime.utc(2026, 9, 23),
    allDay: true,
  ),
  CalendarDemoEvent(
    id: 'CAL-107',
    title: 'Research handoff',
    project: 'Research',
    start: DateTime.parse('2026-09-21T09:30:00+02:00'),
    end: DateTime.parse('2026-09-21T11:00:00+02:00'),
  ),
];

class CalendarDemoCard extends StatelessWidget {
  const CalendarDemoCard({
    required this.event,
    required this.compact,
    super.key,
  });
  final CalendarDemoEvent event;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: t.colorTextPrimary,
            fontFamily: t.fontFamily,
            fontSize: t.fontLabelSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!compact)
          Row(
            children: [
              KIcon(KIconName.folder, size: 12, color: t.colorTextMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  event.project,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.colorTextMuted,
                    fontFamily: t.fontFamily,
                    fontSize: t.fontCaptionSize,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
