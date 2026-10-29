import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../basic_display.dart';
import '../extended_components.dart' show KSwitch;
import '../primitives/k_icon.dart';
import '../primitives/k_button.dart';
import '../forms/k_field.dart';
import '../forms/k_input.dart';
import '../forms/k_select.dart';
import '../maps/k_map_polygon.dart';
import '../pickers/k_date_picker.dart';
import '../primitives/k_disclosure.dart';
import '../primitives/k_text.dart';
import 'k_map_zone_editor_labels.dart';
import 'k_map_zone_recurrence.dart';
import 'k_map_zone_working_hours.dart';

/// The same reusable fields serve every host and the gallery. Values are kept
/// local until the enclosing editor applies this properties transaction.
class KMapZoneProperties extends StatefulWidget {
  const KMapZoneProperties({
    required this.zone,
    this.otherZones = const [],
    required this.labels,
    required this.onChange,
    required this.onValidityChanged,
    this.options,
    super.key,
  });
  final KMapZone zone;
  final List<KMapZone> otherZones;
  final KMapZoneEditorLabels labels;
  final KMapZonePropertyOptions? options;
  final ValueChanged<KMapZone> onChange;
  final ValueChanged<bool> onValidityChanged;
  @override
  State<KMapZoneProperties> createState() => _KMapZonePropertiesState();
}

class _KMapZonePropertiesState extends State<KMapZoneProperties> {
  late final name = TextEditingController(text: widget.zone.name);
  late final travel = TextEditingController(
    text: (widget.zone.settings?.travelCost?.amount ?? 0).toString(),
  );
  late final surcharge = TextEditingController(
    text: (widget.zone.settings?.surcharge ?? 0).toString(),
  );
  late String color = widget.zone.color ?? '#155dfc';
  late String travelKind = widget.zone.settings?.travelCost?.kind ?? 'free';
  late String travelCurrency =
      widget.zone.settings?.travelCost?.currency ??
      widget.options?.currency ??
      'EUR';
  late bool requestRequired = widget.zone.settings?.requestRequired ?? false;
  late List<KMapZoneWorkingDay>? workingHours =
      widget.zone.settings?.workingHours ?? widget.options?.defaultWorkingHours;
  bool colorsOpen = false;
  late String mode = widget.zone.settings?.availability?.kind ?? 'always';
  late KMapZoneAvailability recurring =
      widget.zone.settings?.availability?.kind == 'recurring'
      ? widget.zone.settings!.availability!
      : KMapZoneAvailability.recurring(
          rrule: KMapZoneRecurrence(
            days:
                widget.options?.weekdayOptions
                    .where((day) => !day.disabled)
                    .take(1)
                    .map((day) => day.value)
                    .toList() ??
                ['MO'],
          ).rrule,
          startDate: _initialStart(),
          timeZone: widget.options?.timeZone ?? 'UTC',
        );
  late KMapZoneAvailability range =
      widget.zone.settings?.availability?.kind == 'date-range'
      ? widget.zone.settings!.availability!
      : const KMapZoneAvailability.dateRange(from: '', to: '');
  late KMapZoneRecurrence rule =
      KMapZoneRecurrence.parse(recurring.rrule) ??
      const KMapZoneRecurrence(days: []);
  bool anchorTouched = false;
  final _inputs = <String, TextEditingController>{};
  final _travelAmounts = <String, String>{};

  String _initialStart() {
    final now = DateTime.now();
    var day = DateTime.utc(now.year, now.month, now.day);
    final allowed =
        widget.options?.weekdayOptions
            .where((day) => !day.disabled)
            .map((day) => day.value)
            .toList() ??
        ['MO'];
    for (var i = 0; i < 7; i++) {
      if (allowed.contains(kMapZoneWeekdays[day.weekday - 1])) {
        return kMapZoneIsoDate(day);
      }
      day = day.add(const Duration(days: 1));
    }
    return kMapZoneIsoDate(day);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onValidityChanged(_error == null);
    });
  }

  @override
  void dispose() {
    name.dispose();
    travel.dispose();
    surcharge.dispose();
    for (final input in _inputs.values) {
      input.dispose();
    }
    super.dispose();
  }

  String? get _error {
    final l = widget.labels;
    if (name.text.trim().isEmpty) return l.zoneNameRequired;
    if (widget.options == null) return null;
    final amount = double.tryParse(travel.text.replaceAll(',', '.'));
    if (travelKind != 'free' &&
        (amount == null || !amount.isFinite || amount < 0)) {
      return l.invalidTravelCost;
    }
    final extra = double.tryParse(surcharge.text.replaceAll(',', '.'));
    if (extra == null || !extra.isFinite || extra < 0) {
      return l.invalidSurcharge;
    }
    if (workingHours != null && !validKMapZoneWorkingHours(workingHours!)) {
      return widget.options?.workingHoursLabels['invalid'] ??
          kMapZoneWorkingHoursLabels['invalid'];
    }
    if (mode == 'recurring') {
      if (rule.frequency == 'WEEKLY' && rule.days.isEmpty) {
        return l.chooseWeekday;
      }
      if (KMapZoneRecurrence.parse(recurring.rrule) == null ||
          parseKMapZoneDate(recurring.startDate) == null) {
        return l.invalidRecurrence;
      }
      if (rule.days.isNotEmpty &&
          !rule.days.contains(
            kMapZoneWeekdays[parseKMapZoneDate(recurring.startDate)!.weekday -
                1],
          )) {
        return l.startWeekdayMismatch;
      }
      if (rule.months.isNotEmpty &&
          !rule.months.contains(
            parseKMapZoneDate(recurring.startDate)!.month,
          )) {
        return l.invalidRecurrence;
      }
      if (rule.endDate != null &&
          rule.endDate!.compareTo(recurring.startDate) < 0) {
        return l.invalidDateRange;
      }
      if (rule.days.any(
        (day) => widget.options!.weekdayOptions.any(
          (option) => option.value == day && option.disabled,
        ),
      )) {
        return l.chooseWeekday;
      }
    }
    if (mode == 'date-range' &&
        (parseKMapZoneDate(range.from) == null ||
            parseKMapZoneDate(range.to) == null ||
            range.from.compareTo(range.to) > 0)) {
      return l.invalidDateRange;
    }
    return null;
  }

  void _emit() {
    final options = widget.options;
    final settings = options == null
        ? (widget.zone.settings ?? const KMapZoneSettings()).copyWith(
            requestRequired: requestRequired,
          )
        : KMapZoneSettings(
            workingHours: workingHours,
            travelCost: KMapZoneTravelCost(
              kind: travelKind,
              amount: double.tryParse(travel.text.replaceAll(',', '.')) ?? 0,
              currency: travelCurrency,
            ),
            surcharge:
                (double.tryParse(surcharge.text.replaceAll(',', '.')) ?? 0) == 0
                ? null
                : double.tryParse(surcharge.text.replaceAll(',', '.')),
            surchargeCurrency: options.currency,
            requestRequired: requestRequired,
            availability: mode == 'recurring'
                ? recurring
                : mode == 'date-range'
                ? range
                : null,
          );
    widget.onChange(
      widget.zone.copyWith(name: name.text, color: color, settings: settings),
    );
    widget.onValidityChanged(_error == null);
    setState(() {});
  }

  void _rule(KMapZoneRecurrence next) {
    rule = next;
    var start = recurring.startDate;
    if (rule.frequency == 'WEEKLY' && !anchorTouched && rule.days.isNotEmpty) {
      var date = parseKMapZoneDate(start);
      if (date != null) {
        date = date.subtract(Duration(days: date.weekday - 1));
        for (var i = 0; i < 366; i++) {
          if (rule.days.contains(kMapZoneWeekdays[date!.weekday - 1]) &&
              (rule.months.isEmpty || rule.months.contains(date.month))) {
            start = kMapZoneIsoDate(date);
            break;
          }
          date = date.add(const Duration(days: 1));
        }
      }
    }
    recurring = KMapZoneAvailability.recurring(
      rrule: rule.rrule,
      startDate: start,
      timeZone: recurring.timeZone,
    );
    _emit();
  }

  void _updateStart(String value) {
    anchorTouched = true;
    final anchor = parseKMapZoneDate(value);
    if (rule.ordinal != null && anchor != null) {
      rule = rule.copyWith(
        ordinal: anchor.day > 28 ? -1 : ((anchor.day - 1) ~/ 7) + 1,
        days: [kMapZoneWeekdays[anchor.weekday - 1]],
      );
    }
    recurring = KMapZoneAvailability.recurring(
      rrule: rule.rrule,
      startDate: value,
      timeZone: recurring.timeZone,
    );
    _emit();
  }

  Widget _field(String label, Widget child) =>
      KField(label: label, child: child);
  Widget _input(
    String label,
    String value,
    ValueChanged<String> changed, {
    bool number = false,
  }) {
    if (!number) {
      return _field(
        label,
        KDatePicker(
          label: label,
          value: value.isEmpty ? null : value,
          timeZone: widget.options?.timeZone,
          dateFormat: widget.options?.dateFormat,
          locale: KPickerLocale.values
              .where(
                (locale) =>
                    locale.name ==
                    widget.options?.locale?.split(RegExp('[-_]')).first,
              )
              .firstOrNull,
          clearable: true,
          allowTextInput: true,
          onChanged: (next) => changed(next ?? ''),
        ),
      );
    }
    final controller = _inputs.putIfAbsent(
      label,
      () => TextEditingController(text: value),
    );
    if (controller.text != value) controller.text = value;
    return _field(
      label,
      KInput(key: ValueKey(label), controller: controller, onChanged: changed),
    );
  }

  KDesignTokens get _tokens => Theme.of(context).extension<KDesignTokens>()!;

  Widget _toggle(
    String label,
    String short,
    bool selected,
    VoidCallback? action,
  ) => Semantics(
    label: label,
    toggled: selected,
    button: true,
    child: Tooltip(
      message: label,
      child: InkWell(
        onTap: action,
        borderRadius: BorderRadius.circular(_tokens.radiusFull),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: _tokens.sizeControl + _tokens.spaceControlGap,
            minHeight: _tokens.sizeControl + _tokens.spaceControlGap,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: KBadge(
              variant: selected ? KBadgeVariant.primary : KBadgeVariant.outline,
              child: Text(short),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final l = widget.labels, options = widget.options;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final locale =
        options?.locale ?? Localizations.localeOf(context).toLanguageTag();
    String formatCost(KMapZoneTravelCost cost) {
      if (cost.kind == 'free') return l.freeTravelCost;
      final format = NumberFormat.simpleCurrency(
        locale: locale,
        name: cost.currency,
      );
      final label = cost.kind == 'per-kilometer'
          ? l.perKilometerTravelCost
          : l.flatRateTravelCost;
      return '$label · ${format.format(cost.amount)}${cost.kind == 'per-kilometer' ? '/km' : ''}';
    }

    String costLabel(String kind, String label) {
      final amount =
          double.tryParse(
            (kind == travelKind ? travel.text : _travelAmounts[kind] ?? '0')
                .replaceAll(',', '.'),
          ) ??
          0;
      return formatCost(
        KMapZoneTravelCost(
          kind: kind,
          amount: amount,
          currency: travelCurrency,
        ),
      );
    }

    final copySources = widget.otherZones
        .where((zone) => zone.settings?.travelCost != null)
        .toList(growable: false);
    final palette = [
      if (!kMapZonePalette.any((entry) => entry.light == color.toLowerCase()))
        (name: 'Bisherige Farbe', light: color, dark: color),
      ...kMapZonePalette,
    ];
    final selectedColor = palette.firstWhere(
      (entry) => entry.light == color.toLowerCase(),
      orElse: () => palette.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: t.spaceControlGap,
      children: [
        _field(
          l.zoneName,
          KInput(
            controller: name,
            onChanged: (_) => _emit(),
            pill: true,
            leading: Semantics(
              label: l.zoneColor,
              button: true,
              expanded: colorsOpen,
              child: Tooltip(
                message: l.zoneColor,
                child: KButton(
                  label: '',
                  variant: KButtonVariant.ghost,
                  leading: Container(
                    width: t.sizeIndicatorSmall,
                    height: t.sizeIndicatorSmall,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(
                        int.parse(
                          'ff${(dark ? selectedColor.dark : selectedColor.light).substring(1)}',
                          radix: 16,
                        ),
                      ),
                    ),
                  ),
                  trailing: AnimatedRotation(
                    turns: colorsOpen ? .5 : 0,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : t.motionFast,
                    child: KIcon(KIconName.chevronDown),
                  ),
                  onPressed: () => setState(() => colorsOpen = !colorsOpen),
                ),
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : t.motionFast,
          alignment: Alignment.topCenter,
          child: !colorsOpen
              ? const SizedBox.shrink()
              : _field(
                  l.zoneColor,
                  Wrap(
                    spacing: t.spaceMicro,
                    children: [
                      for (final entry in palette)
                        Semantics(
                          label: entry.name,
                          checked: color.toLowerCase() == entry.light,
                          inMutuallyExclusiveGroup: true,
                          child: Tooltip(
                            message: entry.name,
                            child: InkWell(
                              onTap: () {
                                color = entry.light;
                                _emit();
                              },
                              borderRadius: BorderRadius.circular(
                                _tokens.radiusFull,
                              ),
                              child: Container(
                                width: t.sizeControl + t.spaceControlGap,
                                height: t.sizeControl + t.spaceControlGap,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    width: t.borderWidthStrong,
                                    color: color.toLowerCase() == entry.light
                                        ? t.colorTextPrimary
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Container(
                                  width: t.sizeSmallControl,
                                  height: t.sizeSmallControl,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(
                                      int.parse(
                                        'ff${(dark ? entry.dark : entry.light).substring(1)}',
                                        radix: 16,
                                      ),
                                    ),
                                  ),
                                  child: color.toLowerCase() == entry.light
                                      ? Icon(
                                          Icons.check,
                                          size: 15,
                                          color: dark
                                              ? t.colorActionPrimaryForeground
                                              : t.colorActionPrimaryForeground,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        KSwitch(
          label: l.requestRequired,
          value: requestRequired,
          onChanged: (value) {
            requestRequired = value;
            _emit();
          },
        ),
        if (options != null) ...[
          _field(
            l.travelCost,
            KSelect(
              label: l.travelCost,
              value: travelKind,
              options: [
                KSelectOption(
                  value: 'per-kilometer',
                  label: costLabel('per-kilometer', l.perKilometerTravelCost),
                  leading: KIcon(
                    KIconName.carFront,
                    strokeWidth:
                        (t.borderWidthDefault + t.borderWidthStrong) / 2,
                  ),
                ),
                KSelectOption(
                  value: 'flat-rate',
                  label: costLabel('flat-rate', l.flatRateTravelCost),
                  leading: KIcon(
                    KIconName.banknote,
                    strokeWidth:
                        (t.borderWidthDefault + t.borderWidthStrong) / 2,
                  ),
                ),
                KSelectOption(
                  value: 'free',
                  label: l.freeTravelCost,
                  leading: KIcon(
                    KIconName.gift,
                    strokeWidth:
                        (t.borderWidthDefault + t.borderWidthStrong) / 2,
                  ),
                ),
              ],
              onChanged: (value) {
                _travelAmounts[travelKind] = travel.text;
                travelKind = value ?? 'free';
                travel.text = _travelAmounts[travelKind] ?? '0';
                travelCurrency = options.currency;
                _emit();
              },
            ),
          ),
          if (travelKind != 'free')
            _field(
              '${l.travelCostAmount} ($travelCurrency)',
              KInput(
                controller: travel,
                label: l.travelCostAmount,
                onChanged: (_) => _emit(),
              ),
            ),
          if (copySources.isNotEmpty)
            _field(
              l.copyTravelCost,
              KSelect(
                label: l.copyTravelCost,
                placeholder: l.selectTravelCostZone,
                options: [
                  for (final source in copySources)
                    KSelectOption(
                      value: source.id,
                      label:
                          '${source.name} · ${formatCost(source.settings!.travelCost!)}',
                      leading: KIcon(
                        switch (source.settings!.travelCost!.kind) {
                          'per-kilometer' => KIconName.carFront,
                          'flat-rate' => KIconName.banknote,
                          _ => KIconName.gift,
                        },
                        strokeWidth:
                            (t.borderWidthDefault + t.borderWidthStrong) / 2,
                      ),
                    ),
                ],
                onChanged: (id) {
                  if (id == null) return;
                  final source = copySources.firstWhere(
                    (zone) => zone.id == id,
                  );
                  final cost = source.settings!.travelCost!;
                  _travelAmounts[travelKind] = travel.text;
                  travelKind = cost.kind;
                  travelCurrency = cost.currency;
                  travel.text = cost.amount.toString();
                  _travelAmounts[cost.kind] = travel.text;
                  _emit();
                },
              ),
            ),
          _field(
            '${l.surchargeAmount} (${options.currency})',
            KInput(controller: surcharge, onChanged: (_) => _emit()),
          ),
          if (options.showScheduling)
            KMapZoneWorkingHoursFields(
              hours: workingHours,
              availability: mode == 'recurring'
                  ? recurring
                  : mode == 'date-range'
                  ? range
                  : null,
              options: options,
              otherZones: widget.otherZones
                  .where((zone) => zone.id != widget.zone.id)
                  .toList(),
              onChanged: (value) {
                workingHours = value;
                _emit();
              },
            ),
          if (options.showScheduling)
            _field(
              l.availability,
              KSelect(
                label: l.availability,
                value: mode,
                options: [
                  KSelectOption(
                    value: 'always',
                    label: l.alwaysAvailability,
                    leading: KIcon(
                      KIconName.infinity,
                      strokeWidth:
                          (t.borderWidthDefault + t.borderWidthStrong) / 2,
                    ),
                  ),
                  KSelectOption(
                    value: 'recurring',
                    label: l.recurringAvailability,
                    leading: KIcon(
                      KIconName.repeat,
                      strokeWidth:
                          (t.borderWidthDefault + t.borderWidthStrong) / 2,
                    ),
                  ),
                  KSelectOption(
                    value: 'date-range',
                    label: l.dateRangeAvailability,
                    leading: KIcon(
                      KIconName.calendarRange,
                      strokeWidth:
                          (t.borderWidthDefault + t.borderWidthStrong) / 2,
                    ),
                  ),
                ],
                onChanged: (value) {
                  mode = value ?? 'always';
                  _emit();
                },
              ),
            ),
          if (options.showScheduling && mode == 'recurring') ...[
            Row(
              spacing: t.spaceControlGap,
              children: [
                KText(l.recurrenceEvery),
                SizedBox(
                  width: t.sizeControl * 1.6,
                  child: KInput(
                    controller: _inputs.putIfAbsent(
                      'interval',
                      () => TextEditingController(text: '${rule.interval}'),
                    ),
                    onChanged: (value) => _rule(
                      rule.copyWith(interval: int.tryParse(value) ?? 0),
                    ),
                  ),
                ),
                Expanded(
                  child: KSelect(
                    label: l.recurrenceUnit,
                    value: rule.frequency,
                    options: [
                      KSelectOption(value: 'DAILY', label: l.recurrenceDays),
                      KSelectOption(value: 'WEEKLY', label: l.recurrenceWeeks),
                      KSelectOption(
                        value: 'MONTHLY',
                        label: l.recurrenceMonths,
                      ),
                      KSelectOption(value: 'YEARLY', label: l.recurrenceYears),
                    ],
                    onChanged: (value) => _rule(
                      KMapZoneRecurrence(
                        frequency: value ?? 'WEEKLY',
                        interval: rule.interval,
                        months: rule.months,
                        endDate: rule.endDate,
                        days: value == 'WEEKLY'
                            ? options.weekdayOptions
                                  .where((day) => !day.disabled)
                                  .take(1)
                                  .map((day) => day.value)
                                  .toList()
                            : [],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (rule.frequency == 'MONTHLY')
              KSelect(
                label: l.recurrenceMonthlyMode,
                value: rule.ordinal == null ? 'date' : 'weekday',
                options: [
                  KSelectOption(value: 'date', label: l.recurrenceMonthDate),
                  KSelectOption(
                    value: 'weekday',
                    label: l.recurrenceMonthWeekday,
                  ),
                ],
                onChanged: (value) {
                  final anchor = parseKMapZoneDate(recurring.startDate)!;
                  _rule(
                    KMapZoneRecurrence(
                      frequency: rule.frequency,
                      interval: rule.interval,
                      months: rule.months,
                      endDate: rule.endDate,
                      ordinal: value == 'weekday'
                          ? (anchor.day > 28 ? -1 : ((anchor.day - 1) ~/ 7) + 1)
                          : null,
                      days: value == 'weekday'
                          ? [kMapZoneWeekdays[anchor.weekday - 1]]
                          : [],
                    ),
                  );
                },
              ),
            if (rule.frequency == 'MONTHLY' || rule.frequency == 'YEARLY')
              _input(l.intervalAnchor, recurring.startDate, _updateStart),
            if (rule.frequency == 'WEEKLY')
              Wrap(
                spacing: t.spaceTight,
                children: [
                  for (final day in options.weekdayOptions)
                    _toggle(
                      day.label,
                      day.shortLabel ?? day.label,
                      rule.days.contains(day.value),
                      day.disabled
                          ? null
                          : () => _rule(
                              rule.copyWith(
                                days: rule.days.contains(day.value)
                                    ? rule.days
                                          .where((id) => id != day.value)
                                          .toList()
                                    : [...rule.days, day.value],
                              ),
                            ),
                    ),
                ],
              ),
            KText(
              '${l.recurrenceEvery} ${rule.interval} ${{'DAILY': l.recurrenceDays, 'WEEKLY': l.recurrenceWeeks, 'MONTHLY': l.recurrenceMonths, 'YEARLY': l.recurrenceYears}[rule.frequency]}${rule.days.isNotEmpty ? ' · ${options.weekdayOptions.where((day) => rule.days.contains(day.value)).map((day) => day.label).join(', ')}' : ''}',
              style: TextStyle(
                color: t.colorTextMuted,
                fontSize: t.fontCaptionSize,
              ),
            ),
            KDisclosure(
              title: l.recurrenceDetails,
              scrollOnOpen: true,
              titleWidget: Text(
                l.recurrenceDetails,
                style: TextStyle(
                  fontSize: t.fontLabelSize,
                  color: t.colorTextMuted,
                ),
              ),
              presentation: KDisclosurePresentation.compact,
              child: Column(
                spacing: t.spaceControlGap,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _input(l.intervalAnchor, recurring.startDate, _updateStart),
                  _input(
                    l.endDate,
                    rule.endDate ?? '',
                    (value) => _rule(rule.copyWith(endDate: value)),
                  ),
                  KText(l.months, variant: KTextVariant.label),
                  Wrap(
                    spacing: t.spaceTight,
                    children: [
                      for (var month = 1; month <= 12; month++)
                        _toggle(
                          DateFormat.MMMM(locale).format(DateTime(2024, month)),
                          DateFormat.MMM(locale).format(DateTime(2024, month)),
                          rule.months.contains(month),
                          () => _rule(
                            rule.copyWith(
                              months: rule.months.contains(month)
                                  ? rule.months
                                        .where((id) => id != month)
                                        .toList()
                                  : [...rule.months, month],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (options.showScheduling && mode == 'date-range') ...[
            _input(l.startDate, range.from, (value) {
              range = KMapZoneAvailability.dateRange(from: value, to: range.to);
              _emit();
            }),
            _input(l.endDate, range.to, (value) {
              range = KMapZoneAvailability.dateRange(
                from: range.from,
                to: value,
              );
              _emit();
            }),
          ],
        ],
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: KText(
              _error!,
              style: TextStyle(color: t.colorStatusErrorForeground),
            ),
          ),
      ],
    );
  }
}
