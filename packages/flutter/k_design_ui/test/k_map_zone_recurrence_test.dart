import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/src/editors/k_map_zone_recurrence.dart';
import 'package:k_design_ui/src/maps/k_map_zone_models.dart';

void main() {
  test(
    'same web recurrence fixture combines week interval, months and inclusive end',
    () {
      const availability = KMapZoneAvailability.recurring(
        rrule: 'FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE;BYMONTH=1,2;UNTIL=20260228',
        startDate: '2026-01-05',
        timeZone: 'Europe/Berlin',
      );
      expect(
        nextKMapZoneOccurrences(
          availability,
          now: DateTime.parse('2026-01-05T08:00:00Z'),
        ),
        ['2026-01-05', '2026-01-07', '2026-01-19'],
      );
      expect(
        nextKMapZoneOccurrences(
          const KMapZoneAvailability.recurring(
            rrule: 'FREQ=WEEKLY;BYDAY=MO;UNTIL=20260105',
            startDate: '2026-01-05',
            timeZone: 'Europe/Berlin',
          ),
          now: DateTime.parse('2026-01-04T08:00:00Z'),
        ),
        ['2026-01-05'],
      );
    },
  );
  test('preview uses configured timezone date at midnight boundary', () {
    final now = DateTime.parse('2026-01-04T23:30:00Z');
    expect(
      nextKMapZoneOccurrences(
        const KMapZoneAvailability.recurring(
          rrule: 'FREQ=WEEKLY;BYDAY=MO',
          startDate: '2026-01-05',
          timeZone: 'Europe/Berlin',
        ),
        now: now,
        count: 1,
      ),
      ['2026-01-05'],
    );
    expect(
      nextKMapZoneOccurrences(
        const KMapZoneAvailability.recurring(
          rrule: 'FREQ=WEEKLY;BYDAY=SU',
          startDate: '2026-01-04',
          timeZone: 'America/New_York',
        ),
        now: now,
        count: 1,
      ),
      ['2026-01-04'],
    );
  });
  test(
    'unsupported and malformed recurrence is rejected without lossy conversion',
    () {
      for (final rule in [
        'FREQ=WEEKLY;BYDAY=MO;COUNT=3',
        'FREQ=WEEKLY;BYDAY=MO;INTERVAL=0',
        'FREQ=WEEKLY;BYDAY=MO;UNTIL=20260230',
        'FREQ=WEEKLY;BYDAY=MO;WKST=SU',
        'FREQ=WEEKLY',
        'FREQ=MONTHLY;BYDAY=MO;BYSETPOS=0',
        'FREQ=MONTHLY;BYDAY=MO,TU;BYSETPOS=2',
        'FREQ=YEARLY;BYDAY=MO;BYSETPOS=2',
      ]) {
        expect(KMapZoneRecurrence.parse(rule), isNull, reason: rule);
      }
      expect(parseKMapZoneDate('2026-02-30'), isNull);
    },
  );

  test('RRULE parse and serialization match the supported web subset', () {
    final rule = KMapZoneRecurrence.parse(
      'FREQ=MONTHLY;INTERVAL=2;BYDAY=MO;BYSETPOS=-1;BYMONTH=12,1,12;UNTIL=20270131',
    );
    expect(rule, isNotNull);
    expect(rule!.frequency, 'MONTHLY');
    expect(rule.ordinal, -1);
    expect(rule.days, ['MO']);
    expect(rule.months, [1, 12]);
    expect(
      rule.rrule,
      'FREQ=MONTHLY;INTERVAL=2;BYDAY=MO;BYSETPOS=-1;BYMONTH=1,12;UNTIL=20270131',
    );
    expect(
      rule.copyWith(ordinal: null).rrule,
      'FREQ=MONTHLY;INTERVAL=2;BYDAY=MO;BYMONTH=1,12;UNTIL=20270131',
    );
    expect(const KMapZoneRecurrence().frequency, 'WEEKLY');
    expect(KMapZoneRecurrence.parse('FREQ=WEEKLY;BYDAY=MO,MO,WE')!.days, [
      'MO',
      'WE',
    ]);
    expect(
      KMapZoneRecurrence.parse(
        'FREQ=MONTHLY;INTERVAL=2.0;BYDAY=MO;BYSETPOS=2.0;BYMONTH=1.0',
      )?.rrule,
      'FREQ=MONTHLY;INTERVAL=2;BYDAY=MO;BYSETPOS=2;BYMONTH=1',
    );
  });

  test('daily, monthly and yearly previews preserve calendar behavior', () {
    List<String> preview(String rrule, String startDate) =>
        nextKMapZoneOccurrences(
          KMapZoneAvailability.recurring(
            rrule: rrule,
            startDate: startDate,
            timeZone: 'UTC',
          ),
          now: DateTime.parse('${startDate}T00:00:00Z'),
        );

    expect(preview('FREQ=DAILY;INTERVAL=3', '2026-01-01'), [
      '2026-01-01',
      '2026-01-04',
      '2026-01-07',
    ]);
    expect(preview('FREQ=MONTHLY', '2026-01-31'), [
      '2026-01-31',
      '2026-03-31',
      '2026-05-31',
    ]);
    expect(preview('FREQ=MONTHLY;BYDAY=MO;BYSETPOS=2', '2026-01-12'), [
      '2026-01-12',
      '2026-02-09',
      '2026-03-09',
    ]);
    expect(preview('FREQ=YEARLY', '2024-02-29'), [
      '2024-02-29',
      '2028-02-29',
      '2032-02-29',
    ]);
  });

  test('preview rejects invalid count and timezone like web', () {
    const availability = KMapZoneAvailability.recurring(
      rrule: 'FREQ=DAILY',
      startDate: '2026-01-01',
      timeZone: 'Invalid/Zone',
    );
    expect(nextKMapZoneOccurrences(availability), isEmpty);
    expect(
      nextKMapZoneOccurrences(
        const KMapZoneAvailability.recurring(
          rrule: 'FREQ=DAILY',
          startDate: '2026-01-01',
          timeZone: 'UTC',
        ),
        count: 0,
      ),
      isEmpty,
    );
  });
}
