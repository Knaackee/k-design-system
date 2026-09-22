import 'package:timezone/timezone.dart' as tz;
import '../pickers/picker_model.dart' show pickerLocation;
import 'k_calendar_types.dart';

String calendarDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
DateTime calendarDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);
DateTime calendarLocal(DateTime value, String timeZone) =>
    tz.TZDateTime.from(value, pickerLocation(timeZone));
KCalendarSlot calendarSlot(
  DateTime day,
  int minutes,
  bool allDay,
  String zone,
) {
  final value = calendarDay(day).add(Duration(minutes: minutes));
  return KCalendarSlot(
    date: calendarDateKey(value),
    minutes: value.hour * 60 + value.minute,
    allDay: allDay,
    timeZone: zone,
  );
}

/// Converts a wall-clock slot to an instant using the named IANA zone.
DateTime kCalendarSlotToDate(KCalendarSlot slot) {
  final date = DateTime.parse(slot.date);
  if (slot.allDay) {
    return DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).add(Duration(minutes: slot.minutes));
  }
  return tz.TZDateTime(
    pickerLocation(slot.timeZone),
    date.year,
    date.month,
    date.day,
    slot.minutes ~/ 60,
    slot.minutes % 60,
  ).toUtc();
}

List<DateTime> calendarDays(
  DateTime date,
  KCalendarView view,
  int firstDayOfWeek,
) {
  var start = calendarDay(date);
  if (view == KCalendarView.month) start = DateTime.utc(date.year, date.month);
  if (view == KCalendarView.week || view == KCalendarView.month) {
    start = start.subtract(
      Duration(days: (start.weekday - firstDayOfWeek + 7) % 7),
    );
  }
  final count = switch (view) {
    KCalendarView.day => 1,
    KCalendarView.threeDay => 3,
    KCalendarView.week => 7,
    KCalendarView.month => 42,
  };
  return List.generate(count, (i) => start.add(Duration(days: i)));
}
