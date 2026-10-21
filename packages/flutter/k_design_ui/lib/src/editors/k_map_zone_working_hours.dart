import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../maps/k_map_polygon.dart';
import '../forms/k_input.dart';
import '../forms/k_select.dart';
import '../primitives/k_button.dart';
import '../primitives/k_layout.dart';
import '../primitives/k_text.dart';
import '../primitives/k_disclosure.dart';
import '../pickers/picker_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'k_map_zone_recurrence.dart';

bool validKMapZoneWorkingHours(List<KMapZoneWorkingDay> days) {
  final time = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$');
  return days.length == 7 &&
      days.map((day) => day.day).toSet().length == 7 &&
      days.every((day) {
        if (day.day < 1 || day.day > 7) return false;
        for (var i = 0; i < day.intervals.length; i++) {
          final slot = day.intervals[i];
          if (!time.hasMatch(slot.start) ||
              !time.hasMatch(slot.end) ||
              slot.start.compareTo(slot.end) >= 0 ||
              (i > 0 && day.intervals[i - 1].end.compareTo(slot.start) > 0)) {
            return false;
          }
        }
        return true;
      });
}

class KMapZoneWorkingHoursFields extends StatelessWidget {
  const KMapZoneWorkingHoursFields({
    required this.hours,
    this.availability,
    required this.options,
    required this.otherZones,
    required this.onChanged,
    super.key,
  });
  final KMapZoneAvailability? availability;
  final List<KMapZoneWorkingDay>? hours;
  final KMapZonePropertyOptions options;
  final List<KMapZone> otherZones;
  final ValueChanged<List<KMapZoneWorkingDay>> onChanged;
  @override
  Widget build(BuildContext context) {
    String l(String key) =>
        options.workingHoursLabels[key] ?? kMapZoneWorkingHoursLabels[key]!;
    final formatter = DateFormat.yMMMd(
      options.locale ?? Localizations.localeOf(context).toLanguageTag(),
    );
    final upcoming = nextKMapZoneWorkingWindows(
      hours,
      availability,
      options.timeZone,
    );
    final week =
        hours ??
        List.generate(
          7,
          (index) => KMapZoneWorkingDay(day: index + 1, intervals: const []),
        );
    const ids = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    String label(int day) =>
        options.weekdayOptions
            .where((option) => option.value == ids[day - 1])
            .firstOrNull
            ?.label ??
        ids[day - 1];
    void update(int day, List<KMapZoneTimeInterval> intervals) => onChanged(
      week
          .map(
            (row) => KMapZoneWorkingDay(
              day: row.day,
              intervals: List.of(row.day == day ? intervals : row.intervals),
            ),
          )
          .toList(),
    );
    final sources = otherZones
        .where(
          (zone) =>
              (zone.settings?.workingHours ?? options.defaultWorkingHours) !=
              null,
        )
        .toList();
    return KStack(
      align: KLayoutAlign.stretch,
      gap: KLayoutGap.action,
      children: [
        KText(l('title')),
        KText("${l('timeZone')}: ${options.timeZone}. ${l('constraint')}"),
        if (hours == null) KText(l('missing')),
        if (sources.isNotEmpty)
          KSelect(
            label: l('copy'),
            placeholder: l('chooseSource'),
            options: [
              for (final zone in sources)
                KSelectOption(value: zone.id, label: zone.name),
            ],
            onChanged: (id) {
              if (id == null) return;
              final source =
                  sources
                      .firstWhere((zone) => zone.id == id)
                      .settings
                      ?.workingHours ??
                  options.defaultWorkingHours!;
              onChanged(
                source
                    .map(
                      (day) => KMapZoneWorkingDay(
                        day: day.day,
                        intervals: day.intervals
                            .map(
                              (slot) => KMapZoneTimeInterval(
                                start: slot.start,
                                end: slot.end,
                              ),
                            )
                            .toList(),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        for (final day in week)
          KDisclosure(
            scrollOnOpen: true,
            title:
                '${label(day.day)} · ${day.intervals.isEmpty ? l("closed") : day.intervals.map((slot) => "${slot.start}–${slot.end}").join(", ")}',
            child: KStack(
              align: KLayoutAlign.stretch,
              children: [
                for (var index = 0; index < day.intervals.length; index++)
                  KStack(
                    align: KLayoutAlign.stretch,
                    children: [
                      _TimeInput(
                        key: ValueKey('${day.day}-$index-start'),
                        label: '${label(day.day)} Beginn ${index + 1}',
                        value: day.intervals[index].start,
                        onChanged: (value) => update(day.day, [
                          for (var i = 0; i < day.intervals.length; i++)
                            KMapZoneTimeInterval(
                              start: i == index
                                  ? value
                                  : day.intervals[i].start,
                              end: day.intervals[i].end,
                            ),
                        ]),
                      ),
                      _TimeInput(
                        key: ValueKey('${day.day}-$index-end'),
                        label: '${label(day.day)} Ende ${index + 1}',
                        value: day.intervals[index].end,
                        onChanged: (value) => update(day.day, [
                          for (var i = 0; i < day.intervals.length; i++)
                            KMapZoneTimeInterval(
                              start: day.intervals[i].start,
                              end: i == index ? value : day.intervals[i].end,
                            ),
                        ]),
                      ),
                      KButton(
                        label: l('remove'),
                        variant: KButtonVariant.ghost,
                        onPressed: () => update(day.day, [
                          for (var i = 0; i < day.intervals.length; i++)
                            if (i != index) day.intervals[i],
                        ]),
                      ),
                    ],
                  ),
                KButton(
                  label: l('add'),
                  variant: KButtonVariant.ghost,
                  onPressed: () => update(day.day, [
                    ...day.intervals,
                    const KMapZoneTimeInterval(start: '09:00', end: '17:00'),
                  ]),
                ),
              ],
            ),
          ),
        KDisclosure(
          scrollOnOpen: true,
          title: l('preview'),
          child: KStack(
            align: KLayoutAlign.stretch,
            children: [
              KText(l('previewHint')),
              for (final window in upcoming)
                KText(
                  '${options.formatDate?.call(window.date) ?? (options.dateFormat != null ? formatDate(parseKMapZoneDate(window.date)!, options.dateFormat!) : formatter.format(parseKMapZoneDate(window.date)!))} · ${window.intervals.map((slot) => '${slot.start}–${slot.end}').join(', ')}',
                ),
              if (upcoming.isEmpty) KText(l('noUpcoming')),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeInput extends StatefulWidget {
  const _TimeInput({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final String label, value;
  final ValueChanged<String> onChanged;
  @override
  State<_TimeInput> createState() => _TimeInputState();
}

class _TimeInputState extends State<_TimeInput> {
  late final controller = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(covariant _TimeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (controller.text != widget.value) controller.text = widget.value;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    child: KInput(controller: controller, onChanged: widget.onChanged),
  );
}

const kMapZoneWorkingHoursLabels = <String, String>{
  "preview": "N\u00e4chste Einsatzzeiten laut Regel",
  "previewHint":
      "Ausnahmen und bestehende Buchungen k\u00f6nnen diese Zeiten einschr\u00e4nken. Keine Zusage freier Termine.",
  "noUpcoming": "Keine Einsatzzeiten im Vorschauzeitraum.",
  "title": "Einsatzzeiten",
  "timeZone": "Zeitzone",
  "constraint":
      "Wiederholung und Zeitraum schr\u00e4nken diese Zeiten zus\u00e4tzlich ein.",
  "missing":
      "Keine Einsatzzeiten festgelegt. Tage ohne Zeitfenster sind nicht verf\u00fcgbar.",
  "copy": "Einsatzzeiten \u00fcbernehmen",
  "chooseSource": "Von anderer Zone kopieren",
  "closed": "Geschlossen",
  "start": "Beginn",
  "end": "Ende",
  "remove": "Zeitfenster entfernen",
  "add": "Zeitfenster hinzuf\u00fcgen",
  "hint": "Diese Einsatzzeiten sind eine Regel, keine Zusage freier Termine.",
  "invalid":
      "Bitte sieben Wochentage mit g\u00fcltigen, \u00fcberschneidungsfreien Zeitfenstern angeben.",
};

List<({String date, List<KMapZoneTimeInterval> intervals})>
nextKMapZoneWorkingWindows(
  List<KMapZoneWorkingDay>? hours,
  KMapZoneAvailability? availability,
  String timeZone, {
  DateTime? now,
}) {
  if (hours == null) return [];
  final current = tz.TZDateTime.from(
    now ?? DateTime.now(),
    pickerLocation(timeZone),
  );
  final today = dateIso(current);
  final currentTime = timeIso(current);
  final recurring = availability?.kind == 'recurring'
      ? nextKMapZoneOccurrences(availability!, now: current, count: 366).toSet()
      : null;
  final result = <({String date, List<KMapZoneTimeInterval> intervals})>[];
  var cursor = DateTime.utc(current.year, current.month, current.day);
  for (var i = 0; i < 3660 && result.length < 3; i++) {
    final date = kMapZoneIsoDate(cursor);
    final dayIntervals =
        hours
            .where((day) => day.day == cursor.weekday)
            .firstOrNull
            ?.intervals ??
        <KMapZoneTimeInterval>[];
    final intervals = dayIntervals
        .where((slot) => date != today || slot.end.compareTo(currentTime) > 0)
        .toList();
    if (intervals.isNotEmpty &&
        (recurring == null || recurring.contains(date)) &&
        (availability?.kind != 'date-range' ||
            date.compareTo(availability!.from) >= 0 &&
                date.compareTo(availability.to) <= 0)) {
      result.add((date: date, intervals: intervals));
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return result;
}
