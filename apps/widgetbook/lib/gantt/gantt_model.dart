/// Gallery-only calendar tasks. Range ends are exclusive; milestones have none.
class GanttTask {
  const GanttTask({
    required this.id,
    required this.text,
    this.parent,
    required this.start,
    this.end,
    required this.type,
    required this.progress,
    this.readOnly = false,
  });

  factory GanttTask.fromJson(Map<String, dynamic> json) => GanttTask(
    id: json['id'] as String,
    text: json['text'] as String,
    parent: json['parent'] as String?,
    start: _parseDate(json['start'] as String),
    end: json['end'] == null ? null : _parseDate(json['end'] as String),
    type: json['type'] as String,
    progress: (json['progress'] as num).toDouble(),
    readOnly: json['readOnly'] as bool? ?? false,
  );

  final String id;
  final String text;
  final String? parent;
  final DateTime start;
  final DateTime? end;
  final String type;
  final double progress;
  final bool readOnly;

  GanttTask copyWith({DateTime? start, DateTime? end, double? progress}) =>
      GanttTask(
        id: id,
        text: text,
        parent: parent,
        start: start ?? this.start,
        end: end ?? this.end,
        type: type,
        progress: progress ?? this.progress,
        readOnly: readOnly,
      );
}

class GanttLink {
  const GanttLink({
    required this.id,
    required this.source,
    required this.target,
    required this.type,
  });

  factory GanttLink.fromJson(Map<String, dynamic> json) => GanttLink(
    id: json['id'] as String,
    source: json['source'] as String,
    target: json['target'] as String,
    type: json['type'] as String,
  );

  final String id;
  final String source;
  final String target;
  final String type;
}

DateTime _parseDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw FormatException('Expected a calendar date', value);
  }
  final date = DateTime.parse(value);
  if (date.year != int.parse(value.substring(0, 4)) ||
      date.month != int.parse(value.substring(5, 7)) ||
      date.day != int.parse(value.substring(8, 10))) {
    throw FormatException('Invalid calendar date', value);
  }
  return date;
}

/// Use UTC only for arithmetic, retaining the calendar fields across DST.
int ganttDayIndex(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;

DateTime ganttAddDays(DateTime value, int days) =>
    DateTime(value.year, value.month, value.day + days);

GanttTask moveGanttTask(GanttTask task, int days, String edge) {
  var start = edge == 'end' ? task.start : ganttAddDays(task.start, days);
  var end = task.end == null
      ? null
      : edge == 'start'
      ? task.end
      : ganttAddDays(task.end!, days);
  if (end != null && ganttDayIndex(start) >= ganttDayIndex(end)) {
    if (edge == 'start') {
      start = ganttAddDays(end, -1);
    } else {
      end = ganttAddDays(start, 1);
    }
  }
  return task.copyWith(start: start, end: end);
}

bool _isDateOnly(DateTime value) =>
    value.hour == 0 &&
    value.minute == 0 &&
    value.second == 0 &&
    value.millisecond == 0 &&
    value.microsecond == 0;

/// Consumer acceptance changes editable values only, preserving content identity.
/// Rejection returns the exact original list.
List<GanttTask> applyGanttProposal(
  List<GanttTask> tasks,
  GanttTask next, {
  bool accept = true,
}) {
  final index = tasks.indexWhere((task) => task.id == next.id);
  if (!accept || index < 0) return tasks;
  final current = tasks[index];
  if (current.readOnly ||
      current.type == 'summary' ||
      !_isDateOnly(next.start) ||
      !next.progress.isFinite ||
      next.progress < 0 ||
      next.progress > 100) {
    return tasks;
  }
  if (current.type == 'milestone') {
    if (next.end != null) return tasks;
  } else if (next.end == null ||
      !_isDateOnly(next.end!) ||
      ganttDayIndex(next.end!) <= ganttDayIndex(next.start)) {
    return tasks;
  }
  return List.unmodifiable([
    for (var i = 0; i < tasks.length; i++)
      if (i == index)
        current.copyWith(
          start: next.start,
          end: next.end,
          progress: next.progress,
        )
      else
        tasks[i],
  ]);
}

/// Derive nested summaries from leaf tasks without modifying consumer records.
List<GanttTask> summarizeGanttTasks(List<GanttTask> tasks) {
  List<GanttTask> descendants(String parent, Set<String> visited) {
    if (visited.contains(parent)) return [];
    final nextVisited = {...visited, parent};
    return [
      for (final child in tasks.where((task) => task.parent == parent))
        if (child.type == 'summary')
          ...descendants(child.id, nextVisited)
        else
          child,
    ];
  }

  return List.unmodifiable(
    tasks.map((task) {
      if (task.type != 'summary') return task;
      final children = descendants(task.id, {});
      if (children.isEmpty) return task;
      var start = children.first.start;
      var end = start;
      var totalDays = 0;
      var weightedProgress = 0.0;
      var progressSum = 0.0;
      for (final child in children) {
        if (ganttDayIndex(child.start) < ganttDayIndex(start)) {
          start = child.start;
        }
        final boundary = child.end ?? ganttAddDays(child.start, 1);
        if (ganttDayIndex(boundary) > ganttDayIndex(end)) end = boundary;
        final days = child.end == null
            ? 0
            : ganttDayIndex(child.end!) - ganttDayIndex(child.start);
        totalDays += days;
        weightedProgress += days * child.progress;
        progressSum += child.progress;
      }
      return task.copyWith(
        start: start,
        end: end,
        progress:
            (totalDays > 0
                    ? weightedProgress / totalDays
                    : progressSum / children.length)
                .roundToDouble(),
      );
    }),
  );
}
