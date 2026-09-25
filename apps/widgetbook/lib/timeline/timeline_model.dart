/// Calendar-only entries. Range ends are exclusive; a missing end is a point.
class TimelineEntry {
  const TimelineEntry({
    required this.id,
    required this.label,
    required this.group,
    required this.start,
    this.end,
    this.tone = 'primary',
    this.readOnly = false,
  });

  factory TimelineEntry.fromJson(Map<String, dynamic> json) => TimelineEntry(
    id: json['id'] as String,
    label: json['label'] as String,
    group: json['group'] as String,
    start: DateTime.parse(json['start'] as String),
    end: json['end'] == null ? null : DateTime.parse(json['end'] as String),
    tone: json['tone'] as String? ?? 'primary',
    readOnly: json['readOnly'] as bool? ?? false,
  );

  final String id;
  final String label;
  final String group;
  final DateTime start;
  final DateTime? end;
  final String tone;
  final bool readOnly;

  TimelineEntry copyWith({DateTime? start, DateTime? end, String? group}) =>
      TimelineEntry(
        id: id,
        label: label,
        group: group ?? this.group,
        start: start ?? this.start,
        end: this.end == null ? null : (end ?? this.end),
        tone: tone,
        readOnly: readOnly,
      );
}

class TimelineGroup {
  const TimelineGroup({required this.id, required this.label});

  factory TimelineGroup.fromJson(Map<String, dynamic> json) =>
      TimelineGroup(id: json['id'] as String, label: json['label'] as String);

  final String id;
  final String label;
}

/// Comparing local dates through UTC prevents DST from changing day distances.
int dayIndex(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

DateTime addTimelineDays(DateTime value, int days) =>
    DateTime(value.year, value.month, value.day + days);

class TimelinePlacement {
  const TimelinePlacement({required this.entry, required this.lane});
  final TimelineEntry entry;
  final int lane;
}

class TimelineLayout {
  TimelineLayout({
    required List<TimelinePlacement> entries,
    required Map<String, int> laneCounts,
  }) : entries = List.unmodifiable(entries),
       laneCounts = Map.unmodifiable(laneCounts);

  final List<TimelinePlacement> entries;
  final Map<String, int> laneCounts;
}

/// Packs half-open ranges into the first available lane in each group.
/// Points reserve one calendar day, so a milestone remains distinguishable.
TimelineLayout layoutTimeline(
  List<TimelineEntry> entries,
  List<TimelineGroup> groups, {
  double minimumGapDays = 0,
  double pointSpanDays = 1,
}) {
  final lanes = <int, int>{};
  final counts = <String, int>{};
  for (final group in groups) {
    final indices = <int>[
      for (var i = 0; i < entries.length; i++)
        if (entries[i].group == group.id) i,
    ];
    double finish(TimelineEntry entry) => entry.end == null
        ? dayIndex(entry.start) + pointSpanDays
        : dayIndex(entry.end!).toDouble();
    indices.sort((a, b) {
      final startOrder = dayIndex(
        entries[a].start,
      ).compareTo(dayIndex(entries[b].start));
      if (startOrder != 0) return startOrder;
      final endOrder = finish(entries[a]).compareTo(finish(entries[b]));
      return endOrder == 0 ? a.compareTo(b) : endOrder;
    });
    final laneEnds = <double>[];
    for (final index in indices) {
      final entry = entries[index];
      final start = dayIndex(entry.start);
      var lane = laneEnds.indexWhere((end) => end + minimumGapDays <= start);
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(finish(entry));
      } else {
        laneEnds[lane] = finish(entry);
      }
      lanes[index] = lane;
    }
    counts[group.id] = laneEnds.isEmpty ? 1 : laneEnds.length;
  }
  return TimelineLayout(
    entries: [
      for (var i = 0; i < entries.length; i++)
        if (lanes.containsKey(i))
          TimelinePlacement(entry: entries[i], lane: lanes[i]!),
    ],
    laneCounts: counts,
  );
}

/// Canonical state changes only when the consuming application accepts a move.
List<TimelineEntry> applyTimelineProposal(
  List<TimelineEntry> original,
  TimelineEntry next,
  List<TimelineGroup> groups, {
  bool accept = true,
}) {
  final index = original.indexWhere((entry) => entry.id == next.id);
  if (!accept || index < 0) return original;
  final current = original[index];
  if (current.readOnly ||
      !groups.any((group) => group.id == next.group) ||
      (current.end == null) != (next.end == null) ||
      (next.end != null && dayIndex(next.end!) <= dayIndex(next.start))) {
    return original;
  }
  return List.unmodifiable([
    for (var i = 0; i < original.length; i++)
      if (i == index)
        current.copyWith(start: next.start, end: next.end, group: next.group)
      else
        original[i],
  ]);
}
