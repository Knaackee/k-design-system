import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_map_zone_editor.dart';
import 'package:k_design_ui/src/editors/k_map_zone_working_hours.dart';

void main() {
  List<KMapZoneWorkingDay> week() => List.generate(
    7,
    (index) => KMapZoneWorkingDay(
      day: index + 1,
      intervals: index == 0
          ? [const KMapZoneTimeInterval(start: '09:00', end: '17:00')]
          : [],
    ),
  );
  final now = DateTime.utc(2026, 10, 19, 7);
  test('complete unique week required and overlap rejected', () {
    expect(validKMapZoneWorkingHours(week()), isTrue);
    expect(validKMapZoneWorkingHours([]), isFalse);
    final invalid = week();
    invalid[1] = invalid[0];
    expect(validKMapZoneWorkingHours(invalid), isFalse);
    final overlap = week();
    overlap[0] = const KMapZoneWorkingDay(
      day: 1,
      intervals: [
        KMapZoneTimeInterval(start: '09:00', end: '17:00'),
        KMapZoneTimeInterval(start: '16:00', end: '18:00'),
      ],
    );
    expect(validKMapZoneWorkingHours(overlap), isFalse);
  });
  test(
    'missing hours never imply round-the-clock and previews intersect date constraints',
    () {
      expect(
        nextKMapZoneWorkingWindows(null, null, 'Europe/Berlin', now: now),
        isEmpty,
      );
      expect(
        nextKMapZoneWorkingWindows(
          week(),
          null,
          'Europe/Berlin',
          now: now,
        ).map((slot) => slot.date),
        ['2026-10-19', '2026-10-26', '2026-11-02'],
      );
      expect(
        nextKMapZoneWorkingWindows(
          week(),
          const KMapZoneAvailability.dateRange(
            from: '2026-10-20',
            to: '2026-10-30',
          ),
          'Europe/Berlin',
          now: now,
        ).map((slot) => slot.date),
        ['2026-10-26'],
      );
      expect(
        nextKMapZoneWorkingWindows(
          week(),
          const KMapZoneAvailability.recurring(
            rrule: 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO',
            startDate: '2026-10-19',
            timeZone: 'Europe/Berlin',
          ),
          'Europe/Berlin',
          now: now,
        ).map((slot) => slot.date),
        ['2026-10-19', '2026-11-02', '2026-11-16'],
      );
    },
  );
  test('preview excludes elapsed local intervals and retains ongoing ones', () {
    final splitWeek = week();
    splitWeek[0] = const KMapZoneWorkingDay(
      day: 1,
      intervals: [
        KMapZoneTimeInterval(start: '09:00', end: '12:00'),
        KMapZoneTimeInterval(start: '13:00', end: '17:00'),
      ],
    );
    final midday = nextKMapZoneWorkingWindows(
      splitWeek,
      null,
      'Europe/Berlin',
      now: DateTime.utc(2026, 10, 19, 10),
    );
    expect(midday.first.date, '2026-10-19');
    expect(midday.first.intervals.map((slot) => slot.start), ['13:00']);
    final ongoing = nextKMapZoneWorkingWindows(
      splitWeek,
      null,
      'Europe/Berlin',
      now: DateTime.utc(2026, 10, 19, 12, 30),
    );
    expect(ongoing.first.date, '2026-10-19');
    expect(ongoing.first.intervals.map((slot) => slot.start), ['13:00']);
    final ended = nextKMapZoneWorkingWindows(
      splitWeek,
      null,
      'Europe/Berlin',
      now: DateTime.utc(2026, 10, 19, 15),
    );
    expect(ended.first.date, '2026-10-26');
  });
}
