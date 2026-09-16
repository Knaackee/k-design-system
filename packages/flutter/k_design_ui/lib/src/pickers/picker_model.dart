import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;
import 'picker_types.dart';

bool _initialized = false;
tz.Location pickerLocation(String name) {
  if (name == 'UTC') return tz.UTC;
  if (!_initialized) {
    data.initializeTimeZones();
    _initialized = true;
  }
  try {
    return tz.getLocation(name);
  } on tz.LocationNotFoundException {
    throw ArgumentError.value(name, 'timeZone', 'Unknown IANA time zone');
  }
}

String two(int value) => value.toString().padLeft(2, '0');
String dateIso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
String timeIso(DateTime date) => '${two(date.hour)}:${two(date.minute)}';
DateTime? validDate(int year, int month, int day) {
  if (year < 1 ||
      year > 9999 ||
      month < 1 ||
      month > 12 ||
      day < 1 ||
      day > 31) {
    return null;
  }
  final result = DateTime.utc(year, month, day);
  return result.year == year && result.month == month && result.day == day
      ? result
      : null;
}

DateTime? parseDate(String value, KDateFormat format) {
  final pattern = switch (format) {
    KDateFormat.iso => RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$'),
    KDateFormat.dayMonthYear => RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$'),
    KDateFormat.monthDayYear => RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$'),
  };
  final match = pattern.firstMatch(value.trim());
  if (match == null) return null;
  final a = int.parse(match[1]!);
  final b = int.parse(match[2]!);
  final c = int.parse(match[3]!);
  return switch (format) {
    KDateFormat.iso => validDate(a, b, c),
    KDateFormat.dayMonthYear => validDate(c, b, a),
    KDateFormat.monthDayYear => validDate(c, a, b),
  };
}

String formatDate(DateTime date, KDateFormat format) => switch (format) {
  KDateFormat.iso => dateIso(date),
  KDateFormat.dayMonthYear =>
    '${two(date.day)}.${two(date.month)}.${date.year.toString().padLeft(4, '0')}',
  KDateFormat.monthDayYear =>
    '${two(date.month)}/${two(date.day)}/${date.year.toString().padLeft(4, '0')}',
};
DateTime? parseTime(String value, KTimeFormat format) {
  final match =
      (format == KTimeFormat.h24
              ? RegExp(r'^(\d{2}):(\d{2})$')
              : RegExp(r'^(\d{1,2}):(\d{2})\s+(AM|PM)$', caseSensitive: false))
          .firstMatch(value.trim());
  if (match == null) return null;
  var hour = int.parse(match[1]!);
  final minute = int.parse(match[2]!);
  if (minute > 59 ||
      (format == KTimeFormat.h24 ? hour > 23 : hour < 1 || hour > 12)) {
    return null;
  }
  if (format == KTimeFormat.h12) {
    hour = hour % 12 + (match[3]!.toUpperCase() == 'PM' ? 12 : 0);
  }
  return DateTime.utc(2000, 1, 1, hour, minute);
}

String formatTime(DateTime date, KTimeFormat format) =>
    format == KTimeFormat.h24
    ? timeIso(date)
    : '${two(date.hour % 12 == 0 ? 12 : date.hour % 12)}:${two(date.minute)} ${date.hour < 12 ? 'AM' : 'PM'}';
DateTime? parseInstant(String value) {
  if (!RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:00(?:\.000)?Z$',
  ).hasMatch(value)) {
    return null;
  }
  final day = parseDate(value.substring(0, 10), KDateFormat.iso);
  final time = parseTime(value.substring(11, 16), KTimeFormat.h24);
  return day == null || time == null
      ? null
      : DateTime.utc(day.year, day.month, day.day, time.hour, time.minute);
}

class PickerResult {
  const PickerResult({this.value, this.error});
  final String? value, error;
}

class PickerModel {
  PickerModel({
    required this.kind,
    required this.timeZone,
    required this.dateFormat,
    required this.timeFormat,
    required this.disambiguation,
    this.min,
    this.max,
  }) {
    location = pickerLocation(timeZone);
    for (final bound in [min, max]) {
      if (bound != null && decode(bound) == null) {
        throw ArgumentError.value(
          bound,
          'min/max',
          'Invalid canonical picker value',
        );
      }
    }
    if (min != null && max != null && compare(min!, max!) > 0) {
      throw ArgumentError('min must not exceed max');
    }
  }
  final PickerKind kind;
  final String timeZone;
  final KDateFormat dateFormat;
  final KTimeFormat timeFormat;
  final KTimeDisambiguation disambiguation;
  final String? min, max;
  late final tz.Location location;
  bool get hasDate => kind != PickerKind.time;
  bool get hasTime => kind != PickerKind.date;
  DateTime today(DateTime? now) =>
      tz.TZDateTime.from((now ?? DateTime.now()).toUtc(), location);
  DateTime? decode(String? value) {
    if (value == null) return null;
    return switch (kind) {
      PickerKind.date =>
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)
            ? parseDate(value, KDateFormat.iso)
            : null,
      PickerKind.time => parseTime(value, KTimeFormat.h24),
      PickerKind.dateTime =>
        parseInstant(value) == null
            ? null
            : tz.TZDateTime.from(parseInstant(value)!, location),
    };
  }

  int compare(String a, String b) => kind == PickerKind.dateTime
      ? parseInstant(a)!.compareTo(parseInstant(b)!)
      : a.compareTo(b);
  bool inRange(String value) =>
      (min == null || compare(value, min!) >= 0) &&
      (max == null || compare(value, max!) <= 0);
  String display(String? value) {
    final d = decode(value);
    if (d == null) return '';
    return [
      if (hasDate) formatDate(d, dateFormat),
      if (hasTime) formatTime(d, timeFormat),
    ].join(' ');
  }

  PickerResult fromParts(String date, String time) {
    final d = hasDate ? parseDate(date, dateFormat) : DateTime.utc(2000);
    final t = hasTime ? parseTime(time, timeFormat) : DateTime.utc(2000);
    if (d == null || t == null) return const PickerResult(error: 'invalid');
    String result;
    if (kind == PickerKind.date) {
      result = dateIso(d);
    } else if (kind == PickerKind.time) {
      result = timeIso(t);
    } else {
      final wall = DateTime.utc(d.year, d.month, d.day, t.hour, t.minute);
      final candidates = <DateTime>[];
      for (final offset in location.zones.map((z) => z.offset).toSet()) {
        final instant = wall.subtract(offset);
        final local = tz.TZDateTime.from(instant, location);
        if (local.year == d.year &&
            local.month == d.month &&
            local.day == d.day &&
            local.hour == t.hour &&
            local.minute == t.minute &&
            local.second == 0) {
          candidates.add(instant);
        }
      }
      candidates.sort();
      if (candidates.isEmpty) return const PickerResult(error: 'nonexistent');
      if (candidates.length > 1 &&
          disambiguation == KTimeDisambiguation.reject) {
        return const PickerResult(error: 'ambiguous');
      }
      final chosen = disambiguation == KTimeDisambiguation.later
          ? candidates.last
          : candidates.first;
      result = '${dateIso(chosen)}T${timeIso(chosen)}:00.000Z';
    }
    return inRange(result)
        ? PickerResult(value: result)
        : const PickerResult(error: 'outOfRange');
  }

  PickerResult parse(String draft) {
    draft = draft.trim();
    if (kind == PickerKind.date) return fromParts(draft, '');
    if (kind == PickerKind.time) return fromParts('', draft);
    final split = draft.trim().indexOf(' ');
    if (split < 0) return const PickerResult(error: 'invalid');
    return fromParts(draft.substring(0, split), draft.substring(split + 1));
  }

  bool dayEnabled(DateTime day) {
    final date = dateIso(day);
    final low = decode(min);
    final high = decode(max);
    return (low == null || date.compareTo(dateIso(low)) >= 0) &&
        (high == null || date.compareTo(dateIso(high)) <= 0);
  }
}
