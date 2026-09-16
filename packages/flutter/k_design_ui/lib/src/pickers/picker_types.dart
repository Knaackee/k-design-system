import '../localization/k_localization.dart';

enum KPickerLocale { en, de, fr, es, it, pt, nl, pl, cs, sv, da, nb, fi, tr }

enum KDateFormat { iso, dayMonthYear, monthDayYear }

enum KTimeFormat { h24, h12 }

enum KTimeDisambiguation { reject, earlier, later }

enum PickerKind { date, time, dateTime }

class KPickerLabels {
  const KPickerLabels({
    this.hours,
    this.minutes,
    this.period,
    this.month,
    this.year,
    this.previousYear,
    this.nextYear,
    this.previousYears,
    this.nextYears,
    this.date,
    this.time,
    this.chooseDate,
    this.chooseTime,
    this.chooseDateTime,
    this.previousMonth,
    this.nextMonth,
    this.apply,
    this.cancel,
    this.clear,
    this.invalid,
    this.outOfRange,
    this.nonexistent,
    this.ambiguous,
  });
  final String? hours,
      minutes,
      period,
      month,
      year,
      previousYear,
      nextYear,
      previousYears,
      nextYears;
  final String? date, time, chooseDate, chooseTime, chooseDateTime;
  final String? previousMonth, nextMonth, apply, cancel, clear;
  final String? invalid, outOfRange, nonexistent, ambiguous;
  String text(
    String key,
    KPickerLocale? locale, {
    KLocalizationData? localization,
  }) {
    final overrides = {
      'hours': hours,
      'minutes': minutes,
      'period': period,
      'month': month,
      'year': year,
      'previousYear': previousYear,
      'nextYear': nextYear,
      'previousYears': previousYears,
      'nextYears': nextYears,
      'date': date,
      'time': time,
      'chooseDate': chooseDate,
      'chooseTime': chooseTime,
      'chooseDateTime': chooseDateTime,
      'previousMonth': previousMonth,
      'nextMonth': nextMonth,
      'apply': apply,
      'cancel': cancel,
      'clear': clear,
      'invalid': invalid,
      'outOfRange': outOfRange,
      'nonexistent': nonexistent,
      'ambiguous': ambiguous,
    };
    return overrides[key] ??
        (localization ?? const KLocalizationData()).text(
          key,
          locale: locale?.name,
        );
  }
}
