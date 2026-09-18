import '../localization/k_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../actions/action_control.dart';
import '../forms/form_style.dart';
import '../forms/k_input.dart';
import '../data/k_editable_cell.dart';
import '../primitives/k_icon.dart';
import 'picker_model.dart';
import 'picker_panel.dart';
import 'picker_style.dart';
import 'picker_types.dart';
export 'picker_types.dart'
    show
        KPickerLocale,
        KDateFormat,
        KTimeFormat,
        KTimeDisambiguation,
        KPickerLabels;

enum KPickerPresentation { standard, inline }

class KDatePicker extends StatefulWidget {
  const KDatePicker({
    required this.value,
    required this.onChanged,
    this.onOpenChange,
    this.label,
    this.presentation = KPickerPresentation.standard,
    this.min,
    this.max,
    this.enabled = true,
    this.readOnly = false,
    this.clearable = false,
    this.allowTextInput = false,
    this.minuteStep = 1,
    this.timeZone,
    this.locale,
    this.dateFormat,
    this.timeFormat,
    this.disambiguation = KTimeDisambiguation.reject,
    this.labels = const KPickerLabels(),
    this.now,
    super.key,
  });
  final String? value, label, min, max;
  final KPickerPresentation presentation;
  final ValueChanged<String?>? onChanged;

  /// Modal ownership: true before opening, false after value/focus updates.
  final ValueChanged<bool>? onOpenChange;
  final bool enabled, readOnly, clearable, allowTextInput;
  final int minuteStep;
  final String? timeZone;
  final KPickerLocale? locale;
  final KDateFormat? dateFormat;
  final KTimeFormat? timeFormat;
  final KTimeDisambiguation disambiguation;
  final KPickerLabels labels;
  final DateTime? now;
  PickerKind get kind => PickerKind.date;
  @override
  State<KDatePicker> createState() => _KDatePickerState();
}

class KTimePicker extends KDatePicker {
  const KTimePicker({
    required super.value,
    required super.onChanged,
    super.onOpenChange,
    super.label,
    super.presentation,
    super.min,
    super.max,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.allowTextInput,
    super.minuteStep,
    super.timeZone,
    super.locale,
    super.dateFormat,
    super.timeFormat,
    super.disambiguation,
    super.labels,
    super.now,
    super.key,
  });
  @override
  PickerKind get kind => PickerKind.time;
}

class KDateTimePicker extends KDatePicker {
  const KDateTimePicker({
    required super.value,
    required super.onChanged,
    super.onOpenChange,
    super.label,
    super.presentation,
    super.min,
    super.max,
    super.enabled,
    super.readOnly,
    super.clearable,
    super.allowTextInput,
    super.minuteStep,
    super.timeZone,
    super.locale,
    super.dateFormat,
    super.timeFormat,
    super.disambiguation,
    super.labels,
    super.now,
    super.key,
  });
  @override
  PickerKind get kind => PickerKind.dateTime;
}

class _KDatePickerState extends State<KDatePicker> {
  final _text = TextEditingController();
  final _inputFocus = FocusNode(), _triggerFocus = FocusNode();
  String? _error;
  bool _opening = false;
  ValueChanged<bool>? _openListener;
  RawDialogRoute<PickerCommit>? _dialogRoute;
  bool _initialized = false;
  final _dialogLocale = ValueNotifier(const KLocalizationData());
  bool get _enabled => widget.enabled && widget.onChanged != null;
  KLocalizationData _localization = const KLocalizationData();
  String _label(String key) =>
      widget.labels.text(key, widget.locale, localization: _localization);
  PickerModel get _model => PickerModel(
    kind: widget.kind,
    timeZone: widget.timeZone ?? _localization.timeZone,
    dateFormat: widget.dateFormat ?? _localization.dateFormat,
    timeFormat: widget.timeFormat ?? _localization.timeFormat,
    disambiguation: widget.disambiguation,
    min: widget.min,
    max: widget.max,
  );
  @override
  void initState() {
    super.initState();
    _inputFocus.addListener(_blur);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final previous = _localization;
    _localization = KLocalization.of(context);
    if (!_initialized ||
        (widget.dateFormat == null &&
            previous.dateFormat != _localization.dateFormat) ||
        (widget.timeFormat == null &&
            previous.timeFormat != _localization.timeFormat) ||
        (widget.timeZone == null &&
            previous.timeZone != _localization.timeZone)) {
      _text.text = _model.display(widget.value);
      _error = null;
    }
    _initialized = true;
    if (_opening) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _opening) _dialogLocale.value = _localization;
      });
    }
  }

  void _blur() {
    if (!_inputFocus.hasFocus && !_opening) _commit();
  }

  @override
  void didUpdateWidget(covariant KDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.timeZone != widget.timeZone ||
        oldWidget.dateFormat != widget.dateFormat ||
        oldWidget.timeFormat != widget.timeFormat) {
      _text.text = _model.display(widget.value);
      _error = null;
    }
  }

  @override
  void dispose() {
    _releaseOwnership();
    final route = _dialogRoute;
    final navigator = route?.navigator;
    if (route != null && navigator != null) {
      Future.microtask(() {
        if (navigator.mounted && route.isActive) navigator.removeRoute(route);
      });
    }
    _inputFocus.removeListener(_blur);
    _inputFocus.dispose();
    _triggerFocus.dispose();
    _text.dispose();
    _dialogLocale.dispose();
    super.dispose();
  }

  void _commit() {
    if (!_enabled || widget.readOnly || !widget.allowTextInput) return;
    if (_text.text == _model.display(widget.value)) {
      if (_error != null) setState(() => _error = null);
      return;
    }
    if (_text.text.trim().isEmpty) {
      setState(() => _error = null);
      if (widget.value != null) widget.onChanged?.call(null);
      return;
    }
    final result = _model.parse(_text.text);
    setState(() => _error = result.error);
    if (result.error == null) {
      _text.text = _model.display(result.value);
      if (result.value != widget.value) widget.onChanged?.call(result.value);
    }
  }

  void _releaseOwnership() {
    if (!_opening) return;
    _opening = false;
    final listener = _openListener;
    _openListener = null;
    listener?.call(false);
  }

  Future<void> _open() async {
    if (!_enabled || widget.readOnly || _opening) return;
    final previousFocus = FocusManager.instance.primaryFocus;
    _opening = true;
    _openListener = widget.onOpenChange;
    _openListener?.call(true);
    _dialogLocale.value = _localization;
    final model = _model;
    final themes = InheritedTheme.capture(
      from: context,
      to: Navigator.of(context).context,
    );
    final textScaler = MediaQuery.textScalerOf(context);
    final route = RawDialogRoute<PickerCommit>(
      barrierDismissible: true,
      barrierLabel: _label('cancel'),
      barrierColor: const Color(0x52000000),
      transitionDuration: Duration.zero,
      pageBuilder: (routeContext, animation, secondary) => themes.wrap(
        MediaQuery(
          data: MediaQuery.of(routeContext).copyWith(textScaler: textScaler),
          child: Center(
            child: ValueListenableBuilder<KLocalizationData>(
              valueListenable: _dialogLocale,
              builder: (context, data, child) => data.wrap(
                PickerPanel(
                  model: model,
                  value: widget.value,
                  locale: widget.locale,
                  labels: widget.labels,
                  clearable: widget.clearable,
                  allowTextInput: widget.allowTextInput,
                  minuteStep: widget.minuteStep,
                  now: widget.now,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    _dialogRoute = route;
    try {
      final result = await Navigator.of(context).push(route);
      if (!mounted) return;
      if (result != null) {
        setState(() => _error = null);
        _text.text = _model.display(result.value);
        widget.onChanged?.call(result.value);
      }
      if (widget.presentation == KPickerPresentation.inline) {
        if (previousFocus?.context != null) previousFocus?.requestFocus();
      } else {
        _triggerFocus.requestFocus();
      }
    } finally {
      _dialogRoute = null;
      _releaseOwnership();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.minuteStep < 1 ||
        widget.minuteStep > 30 ||
        60 % widget.minuteStep != 0) {
      throw ArgumentError.value(
        widget.minuteStep,
        'minuteStep',
        'Must be a positive divisor of 60, at most 30',
      );
    }
    final t = formTokens(context);
    final model = _model;
    final placeholder = [
      if (model.hasDate)
        switch (model.dateFormat) {
          KDateFormat.iso => 'YYYY-MM-DD',
          KDateFormat.dayMonthYear => 'DD.MM.YYYY',
          KDateFormat.monthDayYear => 'MM/DD/YYYY',
        },
      if (model.hasTime)
        model.timeFormat == KTimeFormat.h24 ? 'HH:mm' : 'hh:mm AM',
    ].join(' ');
    final title = _label(switch (widget.kind) {
      PickerKind.date => 'chooseDate',
      PickerKind.time => 'chooseTime',
      PickerKind.dateTime => 'chooseDateTime',
    });
    if (widget.presentation == KPickerPresentation.inline) {
      return KEditableCell(
        label: widget.label ?? title,
        display: Text(
          widget.value == null ? placeholder : model.display(widget.value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        editor: const SizedBox.shrink(),
        onEdit: _enabled && !widget.readOnly ? _open : null,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: t.spaceControlGap,
      children: [
        Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.enter ||
                    (!widget.allowTextInput &&
                        event.logicalKey == LogicalKeyboardKey.space)) &&
                _inputFocus.hasFocus) {
              if (widget.allowTextInput) {
                _commit();
              } else {
                _open();
              }
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  onTap: !widget.allowTextInput && _enabled && !widget.readOnly
                      ? _open
                      : null,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTap:
                        !widget.allowTextInput && _enabled && !widget.readOnly
                        ? _open
                        : null,
                    child: AbsorbPointer(
                      absorbing: !widget.allowTextInput,
                      child: KInput(
                        controller: _text,
                        focusNode: _inputFocus,
                        label: widget.label,
                        placeholder: placeholder,
                        enabled: _enabled,
                        readOnly: widget.readOnly || !widget.allowTextInput,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: t.spaceControlGap),
              KActionControl(
                label: title,
                onPressed: _enabled && !widget.readOnly ? _open : null,
                focusNode: _triggerFocus,
                icon: widget.kind == PickerKind.time
                    ? KIconName.clock
                    : KIconName.calendar,
                iconOnly: true,
              ),
            ],
          ),
        ),
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              _label(_error!),
              style: pickerTextStyle(
                context,
                color: t.colorStatusErrorForeground,
              ),
            ),
          ),
      ],
    );
  }
}
