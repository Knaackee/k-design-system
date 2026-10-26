import '../maps/k_map_zone_models.dart';
import '../pickers/picker_model.dart' show pickerLocation;
import 'package:timezone/timezone.dart' as tz;

const kMapZoneWeekdays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
const _frequencies = ['DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'];
const _unset = Object();

class KMapZoneRecurrence {
  const KMapZoneRecurrence({
    this.frequency = 'WEEKLY',
    this.ordinal,
    this.days = const ['MO'],
    this.interval = 1,
    this.months = const [],
    this.endDate,
  });
  final String frequency;
  final int? ordinal;
  final List<String> days;
  final int interval;
  final List<int> months;
  final String? endDate;

  static KMapZoneRecurrence? parse(String rrule) {
    final fields = <String, String>{};
    for (final field in rrule.split(';')) {
      final parts = field.split('=');
      if (parts.length != 2 || fields.containsKey(parts[0])) return null;
      fields[parts[0]] = parts[1];
    }
    final frequency = fields['FREQ'];
    if (!_frequencies.contains(frequency) ||
        (frequency == 'WEEKLY' && (fields['BYDAY']?.isEmpty ?? true)) ||
        fields.keys.any(
          (key) => ![
            'FREQ',
            'INTERVAL',
            'BYDAY',
            'BYMONTH',
            'UNTIL',
            'BYSETPOS',
          ].contains(key),
        )) {
      return null;
    }
    final days = fields['BYDAY']?.split(',') ?? [];
    final ordinal = fields.containsKey('BYSETPOS')
        ? _parseInteger(fields['BYSETPOS']!)
        : null;
    if (fields.containsKey('BYSETPOS') &&
        (ordinal == null ||
            frequency != 'MONTHLY' ||
            ![1, 2, 3, 4, -1].contains(ordinal) ||
            days.length != 1)) {
      return null;
    }
    final interval = _parseInteger(fields['INTERVAL'] ?? '1') ?? 0;
    final rawMonths = fields['BYMONTH'];
    if (fields.containsKey('BYMONTH') && (rawMonths?.isEmpty ?? true)) {
      return null;
    }
    final months =
        rawMonths
            ?.split(',')
            .map((value) => _parseInteger(value) ?? 0)
            .toList() ??
        <int>[];
    final until = fields['UNTIL'];
    if (fields.containsKey('UNTIL') && (until?.isEmpty ?? true)) return null;
    if (until != null && !RegExp(r'^\d{8}$').hasMatch(until)) return null;
    final end = until == null
        ? null
        : until.length >= 8
        ? '${until.substring(0, 4)}-${until.substring(4, 6)}-${until.substring(6, 8)}'
        : '';
    if (days.any((day) => !kMapZoneWeekdays.contains(day)) ||
        interval < 1 ||
        interval > 52 ||
        months.any((month) => month < 1 || month > 12) ||
        (end != null && parseKMapZoneDate(end) == null)) {
      return null;
    }
    return KMapZoneRecurrence(
      frequency: frequency!,
      ordinal: ordinal,
      days: days.toSet().toList(),
      interval: interval,
      months: (months.toSet().toList()..sort()),
      endDate: end,
    );
  }

  String get rrule => [
    'FREQ=$frequency',
    if (interval != 1) 'INTERVAL=$interval',
    if (frequency == 'WEEKLY' || days.isNotEmpty)
      'BYDAY=${days.toSet().join(',')}',
    if (ordinal != null) 'BYSETPOS=$ordinal',
    if (months.isNotEmpty)
      'BYMONTH=${(months.toSet().toList()..sort()).join(',')}',
    if (endDate != null && endDate!.isNotEmpty)
      'UNTIL=${endDate!.replaceAll('-', '')}',
  ].join(';');

  KMapZoneRecurrence copyWith({
    String? frequency,
    Object? ordinal = _unset,
    List<String>? days,
    int? interval,
    List<int>? months,
    String? endDate,
  }) => KMapZoneRecurrence(
    frequency: frequency ?? this.frequency,
    ordinal: identical(ordinal, _unset) ? this.ordinal : ordinal as int?,
    days: days ?? this.days,
    interval: interval ?? this.interval,
    months: months ?? this.months,
    endDate: endDate ?? this.endDate,
  );
}

int? _parseInteger(String value) {
  final number = num.tryParse(value);
  return number != null && number.isFinite && number == number.roundToDouble()
      ? number.toInt()
      : null;
}

DateTime? parseKMapZoneDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
  final date = DateTime.tryParse('${value}T00:00:00Z');
  return date != null && date.toIso8601String().startsWith(value) ? date : null;
}

String kMapZoneIsoDate(DateTime date) =>
    date.toIso8601String().substring(0, 10);

List<String> nextKMapZoneOccurrences(
  KMapZoneAvailability availability, {
  DateTime? now,
  int count = 3,
}) {
  if (count < 1) return [];
  final rule = KMapZoneRecurrence.parse(availability.rrule);
  final start = parseKMapZoneDate(availability.startDate);
  if (rule == null || start == null) return [];
  late final tz.TZDateTime today;
  try {
    today = tz.TZDateTime.from(
      now ?? DateTime.now(),
      pickerLocation(availability.timeZone),
    );
  } on ArgumentError {
    return [];
  }
  var day = DateTime.utc(today.year, today.month, today.day);
  if (day.isBefore(start)) day = start;
  final anchorWeek = start.subtract(Duration(days: start.weekday - 1));
  final end = rule.endDate == null ? null : parseKMapZoneDate(rule.endDate!);
  final result = <String>[];
  final previewDays = (366 * rule.interval * count).clamp(0, 60000);
  final maxDays = previewDays < 4000 ? 4000 : previewDays;
  for (
    var i = 0;
    i < maxDays && result.length < count;
    i++, day = day.add(const Duration(days: 1))
  ) {
    if (end != null && day.isAfter(end)) break;
    final weeks = day.difference(anchorWeek).inDays ~/ 7;
    final months = (day.year - start.year) * 12 + day.month - start.month;
    final units = switch (rule.frequency) {
      'DAILY' => day.difference(start).inDays,
      'MONTHLY' => months,
      'YEARLY' => day.year - start.year,
      _ => weeks,
    };
    final sameDay = day.day == start.day;
    final ordinalMatches = rule.ordinal == -1
        ? day.add(const Duration(days: 7)).month != day.month
        : ((day.day + 6) ~/ 7) == rule.ordinal;
    if (units >= 0 &&
        units % rule.interval == 0 &&
        (rule.frequency != 'MONTHLY' ||
            (rule.ordinal != null ? ordinalMatches : sameDay)) &&
        (rule.frequency != 'YEARLY' || (sameDay && day.month == start.month)) &&
        (rule.days.isEmpty ||
            rule.days.contains(kMapZoneWeekdays[day.weekday - 1])) &&
        (rule.months.isEmpty || rule.months.contains(day.month))) {
      result.add(kMapZoneIsoDate(day));
    }
  }
  return result;
}
