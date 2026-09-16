import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:widgetbook/widgetbook.dart';

Widget buildPickerFixture(BuildContext context, String kind) => PickerFixture(
  kind: kind,
  allowTextInput: context.knobs.boolean(
    label: 'allowTextInput',
    initialValue: false,
  ),
  minuteStep: context.knobs.object.dropdown<int>(
    label: 'minuteStep',
    options: [1, 5, 15],
    initialOption: 1,
  ),
  timeZone: context.knobs.object.dropdown<String>(
    label: 'timeZone',
    options: ['UTC', 'Europe/Berlin', 'America/New_York'],
    initialOption: 'Europe/Berlin',
  ),
  locale: _pickerLocale(
    context.knobs.object.dropdown<String>(
      label: 'locale',
      options: ['inherit', ...KPickerLocale.values.map((value) => value.name)],
      initialOption: 'inherit',
    ),
  ),
  dateFormat: context.knobs.object.dropdown<KDateFormat>(
    label: 'dateFormat',
    options: KDateFormat.values,
    initialOption: KDateFormat.dayMonthYear,
    labelBuilder: (value) => value.name,
  ),
  timeFormat: context.knobs.object.dropdown<KTimeFormat>(
    label: 'timeFormat',
    options: KTimeFormat.values,
    initialOption: KTimeFormat.h24,
    labelBuilder: (value) => value.name,
  ),
  disambiguation: context.knobs.object.dropdown<KTimeDisambiguation>(
    label: 'disambiguation',
    options: KTimeDisambiguation.values,
    initialOption: KTimeDisambiguation.reject,
    labelBuilder: (value) => value.name,
  ),
);

KPickerLocale? _pickerLocale(String value) =>
    value == 'inherit' ? null : KPickerLocale.values.byName(value);

class PickerFixture extends StatefulWidget {
  const PickerFixture({
    this.kind = 'date',
    this.allowTextInput = false,
    this.minuteStep = 1,
    this.timeZone = 'Europe/Berlin',
    this.locale,
    this.dateFormat = KDateFormat.dayMonthYear,
    this.timeFormat = KTimeFormat.h24,
    this.disambiguation = KTimeDisambiguation.reject,
    super.key,
  });
  final String kind;
  final bool allowTextInput;
  final int minuteStep;
  final String timeZone;
  final KPickerLocale? locale;
  final KDateFormat dateFormat;
  final KTimeFormat timeFormat;
  final KTimeDisambiguation disambiguation;
  @override
  State<PickerFixture> createState() => _PickerFixtureState();
}

class _PickerFixtureState extends State<PickerFixture> {
  String get _initial => widget.kind == 'date'
      ? '2026-09-16'
      : widget.kind == 'time'
      ? '14:30'
      : '2026-09-16T12:30:00.000Z';
  late String? _value = _initial;

  Widget _picker({
    required String? value,
    bool enabled = true,
    bool readOnly = false,
    bool clearable = false,
  }) {
    final onChanged = enabled
        ? (String? next) => setState(() => _value = next)
        : null;
    switch (widget.kind) {
      case 'time':
        return KTimePicker(
          value: value,
          allowTextInput: widget.allowTextInput,
          minuteStep: widget.minuteStep,
          onChanged: onChanged,
          enabled: enabled,
          readOnly: readOnly,
          clearable: clearable,
          timeZone: widget.timeZone,
          locale: widget.locale,
          dateFormat: widget.dateFormat,
          timeFormat: widget.timeFormat,
          disambiguation: widget.disambiguation,
          now: DateTime.utc(2026, 9, 16, 10),
        );
      case 'date-time':
        return KDateTimePicker(
          value: value,
          allowTextInput: widget.allowTextInput,
          minuteStep: widget.minuteStep,
          onChanged: onChanged,
          enabled: enabled,
          readOnly: readOnly,
          clearable: clearable,
          timeZone: widget.timeZone,
          locale: widget.locale,
          dateFormat: widget.dateFormat,
          timeFormat: widget.timeFormat,
          disambiguation: widget.disambiguation,
          now: DateTime.utc(2026, 9, 16, 10),
        );
      default:
        return KDatePicker(
          value: value,
          allowTextInput: widget.allowTextInput,
          minuteStep: widget.minuteStep,
          onChanged: onChanged,
          enabled: enabled,
          readOnly: readOnly,
          clearable: clearable,
          timeZone: widget.timeZone,
          locale: widget.locale,
          dateFormat: widget.dateFormat,
          timeFormat: widget.timeFormat,
          disambiguation: widget.disambiguation,
          now: DateTime.utc(2026, 9, 16, 10),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final label = widget.kind == 'date'
        ? 'Date'
        : widget.kind == 'time'
        ? 'Time'
        : 'Date and time';
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: t.spaceLayoutGutter),
      child: KContainer(
        child: KStack(
          align: KLayoutAlign.stretch,
          gap: KLayoutGap.section,
          children: [
            const KText('Schedule', variant: KTextVariant.heading4),
            KField(
              label: label,
              child: _picker(value: _value, clearable: true),
            ),
            KField(
              label: 'Read only',
              child: _picker(value: _initial, readOnly: true),
            ),
            KField(
              label: 'Unavailable',
              child: _picker(value: _initial, enabled: false),
            ),
            Semantics(
              liveRegion: true,
              child: KText('Value: ${_value ?? 'None'}'),
            ),
          ],
        ),
      ),
    );
  }
}
