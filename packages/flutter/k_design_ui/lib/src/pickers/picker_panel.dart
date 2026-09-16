import '../localization/k_localization.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../primitives/k_button.dart';
import '../forms/k_field.dart';
import '../forms/k_input.dart';
import '../forms/form_style.dart';
import 'picker_calendar.dart';
import 'picker_time.dart';
import 'picker_model.dart';
import 'picker_style.dart';
import 'picker_types.dart';

class PickerCommit {
  const PickerCommit(this.value);
  final String? value;
}

class PickerPanel extends StatefulWidget {
  const PickerPanel({
    required this.model,
    required this.value,
    required this.locale,
    required this.labels,
    required this.clearable,
    this.now,
    this.allowTextInput = false,
    this.minuteStep = 1,
    super.key,
  });
  final PickerModel model;
  final String? value;
  final KPickerLocale? locale;
  final KPickerLabels labels;
  final bool clearable, allowTextInput;
  final int minuteStep;
  final DateTime? now;
  @override
  State<PickerPanel> createState() => _PickerPanelState();
}

class _PickerPanelState extends State<PickerPanel> {
  late final TextEditingController _date, _time;
  final _dateFocus = FocusNode(), _timeFocus = FocusNode();
  late DateTime _selected;
  String? _error;
  bool _timeVisible = true;
  String text(String key) => widget.labels.text(
    key,
    widget.locale,
    localization: KLocalization.of(context),
  );
  @override
  void initState() {
    super.initState();
    _timeVisible = widget.model.decode(widget.value) != null;
    final initial =
        widget.model.decode(widget.value) ?? widget.model.today(widget.now);
    _selected = initial;
    if (widget.model.hasDate) {
      final low = widget.model.decode(widget.model.min);
      final high = widget.model.decode(widget.model.max);
      if (low != null && dateIso(_selected).compareTo(dateIso(low)) < 0) {
        _selected = DateTime.utc(low.year, low.month, low.day);
      } else if (high != null &&
          dateIso(_selected).compareTo(dateIso(high)) > 0) {
        _selected = DateTime.utc(high.year, high.month, high.day);
      }
    }
    _date = TextEditingController(
      text: formatDate(_selected, widget.model.dateFormat),
    );
    _time = TextEditingController(
      text: formatTime(initial, widget.model.timeFormat),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.allowTextInput) {
        (widget.model.hasDate ? _dateFocus : _timeFocus).requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _date.dispose();
    _time.dispose();
    _dateFocus.dispose();
    _timeFocus.dispose();
    super.dispose();
  }

  void _apply() {
    final result = widget.model.fromParts(_date.text, _time.text);
    if (result.error != null) {
      setState(() => _error = result.error);
      return;
    }
    Navigator.of(context).pop(PickerCommit(result.value));
  }

  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    final title = text(switch (widget.model.kind) {
      PickerKind.date => 'chooseDate',
      PickerKind.time => 'chooseTime',
      PickerKind.dateTime => 'chooseDateTime',
    });
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: title,
      explicitChildNodes: true,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width:
              widget.model.kind == PickerKind.dateTime &&
                  MediaQuery.sizeOf(context).width >= 736
              ? 720
              : 400,
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width - 16,
            maxHeight: MediaQuery.sizeOf(context).height - 16,
          ),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: t.colorSurfaceRaised,
            border: Border.all(color: t.colorBorderDefault),
            borderRadius: BorderRadius.circular(t.radiusOverlay),
            boxShadow: t.elevationOverlay,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: pickerTextStyle(context)),
                ),
                _selectionBody(context),
                if (_error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      text(_error!),
                      style: pickerTextStyle(
                        context,
                        color: t.colorStatusErrorForeground,
                      ),
                    ),
                  ),
                _footer(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionBody(BuildContext context) {
    final calendar = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        if (widget.allowTextInput)
          KField(
            label: text('date'),
            child: KInput(
              controller: _date,
              focusNode: _dateFocus,
              onChanged: (value) {
                final date = parseDate(value, widget.model.dateFormat);
                setState(() {
                  _error = null;
                  _timeVisible = date != null;
                  if (date != null) _selected = date;
                });
              },
            ),
          ),
        PickerCalendar(
          selected: _selected,
          model: widget.model,
          locale: widget.locale,
          labels: widget.labels,
          autofocus: !widget.allowTextInput,
          onBrowse: () => setState(() => _timeVisible = false),
          onSelected: (date) => setState(() {
            _timeVisible = true;
            _selected = date;
            _date.text = formatDate(date, widget.model.dateFormat);
            _error = null;
          }),
        ),
      ],
    );
    final time = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        if (widget.allowTextInput)
          KField(
            label: text('time'),
            child: KInput(
              controller: _time,
              focusNode: _timeFocus,
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
        PickerTime(
          value:
              parseTime(_time.text, widget.model.timeFormat) ??
              DateTime.utc(2000),
          format: widget.model.timeFormat,
          step: widget.minuteStep,
          locale: widget.locale,
          labels: widget.labels,
          autofocus: !widget.allowTextInput && !widget.model.hasDate,
          onChanged: (time) => setState(() {
            _time.text = formatTime(time, widget.model.timeFormat);
            _error = null;
          }),
        ),
      ],
    );
    if (!widget.model.hasDate) return time;
    if (!widget.model.hasTime) return calendar;
    if (MediaQuery.sizeOf(context).width >= 736) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: calendar),
          const SizedBox(width: 16),
          Expanded(child: _timeVisible ? time : const SizedBox.shrink()),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [calendar, if (_timeVisible) time],
    );
  }

  Widget _footer(BuildContext context) {
    final t = formTokens(context);
    final buttons = <KButton>[
      if (widget.clearable)
        KButton(
          label: text('clear'),
          variant: KButtonVariant.ghost,
          onPressed: widget.value == null
              ? null
              : () => Navigator.of(context).pop(const PickerCommit(null)),
        ),
      KButton(
        label: text('cancel'),
        variant: KButtonVariant.ghost,
        onPressed: () => Navigator.of(context).pop(),
      ),
      KButton(label: text('apply'), onPressed: _apply),
    ];
    double width(String label) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: formTextStyle(context)),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final width = painter.width + 2 * (t.spaceControlInsetInline + 1);
      painter.dispose();
      return width;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // CSS flex-grow fills only the spacer's wrapped line. Determine that
        // line with the spacer's zero basis before assigning its free space.
        final widths = [
          if (widget.clearable) width(buttons.first.label),
          0.0,
          ...buttons
              .skip(widget.clearable ? 1 : 0)
              .map((button) => width(button.label)),
        ];
        final spacerIndex = widget.clearable ? 1 : 0;
        var lineWidth = 0.0;
        var lineCount = 0;
        var hasSpacer = false;
        for (var index = 0; index < widths.length; index++) {
          final itemWidth = math.min(widths[index], constraints.maxWidth);
          final next = lineWidth + (lineCount == 0 ? 0 : 8) + itemWidth;
          if (lineCount > 0 && next > constraints.maxWidth) {
            if (hasSpacer) break;
            lineWidth = 0;
            lineCount = 0;
          }
          lineWidth += (lineCount == 0 ? 0 : 8) + itemWidth;
          lineCount++;
          hasSpacer = hasSpacer || index == spacerIndex;
        }
        final space = math.max(0.0, constraints.maxWidth - lineWidth);
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (widget.clearable) buttons.first,
            SizedBox(width: space),
            ...buttons.skip(widget.clearable ? 1 : 0),
          ],
        );
      },
    );
  }
}
