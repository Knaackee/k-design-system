class ActivityIssue {
  const ActivityIssue(
    this.id,
    this.title,
    this.project,
    this.person,
    this.status,
    this.date,
  );
  final String id, title, project, person, status;
  final DateTime? date;
}

final activityToday = DateTime.utc(2026, 10, 2);
const activityMonths = [
  'Januar',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];
String activityDateLabel(DateTime date) =>
    '${date.day}. ${activityMonths[date.month - 1]}';
DateTime activityDay(int offset) => DateTime.utc(2026, 6, 29 + offset);

final activityIssues = List.generate(140, (i) {
  const titles = [
    'Projekt-Icons angleichen',
    'Artefakte bereitstellen',
    'Orbit-Filter verbessern',
    'Webvorschau prüfen',
    'Profilwechsel absichern',
    'Dokumentation aktualisieren',
  ];
  final completed = i < 100;
  return ActivityIssue(
    'ISS-${600 + i}',
    titles[i % 6],
    i % 2 == 0 ? 'Tasks' : 'Orbit',
    i % 3 == 0 ? 'Hans' : 'Denis',
    completed
        ? 'done'
        : i % 2 == 1
        ? 'in-progress'
        : 'backlog',
    completed
        ? activityDay((i * i * 13 + i * 7) % 96)
        : i % 7 != 0
        ? activityDay(96 + ((i * 7) % 85))
        : null,
  );
});
