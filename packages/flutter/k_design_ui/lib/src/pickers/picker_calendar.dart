import '../localization/k_localization.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../forms/form_style.dart';
import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';
import 'picker_model.dart';
import 'picker_style.dart';
import 'picker_types.dart';

class PickerCalendar extends StatefulWidget {
  const PickerCalendar({
    required this.selected,
    required this.onSelected,
    required this.model,
    required this.locale,
    required this.labels,
    this.autofocus = false,
    this.onBrowse,
    super.key,
  });
  final DateTime selected;
  final bool autofocus;
  final VoidCallback? onBrowse;
  final ValueChanged<DateTime> onSelected;
  final PickerModel model;
  final KPickerLocale? locale;
  final KPickerLabels labels;
  @override
  State<PickerCalendar> createState() => _PickerCalendarState();
}

class _PickerCalendarState extends State<PickerCalendar> {
  int _view = 0;
  int _yearPage = 1;
  late DateTime _month;
  late DateTime _active;
  final _focus = <String, FocusNode>{};
  @override
  void initState() {
    super.initState();
    _active = _bounded(widget.selected);
    _month = DateTime.utc(_active.year, _active.month);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus[dateIso(_active)]?.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant PickerCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (dateIso(widget.selected) != dateIso(oldWidget.selected)) {
      _active = _bounded(widget.selected);
      _month = DateTime.utc(_active.year, _active.month);
      if (widget.autofocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focus[dateIso(_active)]?.requestFocus();
        });
      }
    }
  }

  @override
  void dispose() {
    for (final node in _focus.values) {
      node.dispose();
    }
    super.dispose();
  }

  DateTime _bounded(DateTime next) {
    final low = widget.model.decode(widget.model.min);
    final high = widget.model.decode(widget.model.max);
    if (low != null && dateIso(next).compareTo(dateIso(low)) < 0) {
      return DateTime.utc(low.year, low.month, low.day);
    }
    if (high != null && dateIso(next).compareTo(dateIso(high)) > 0) {
      return DateTime.utc(high.year, high.month, high.day);
    }
    return next;
  }

  DateTime _shiftMonth(DateTime date, int months) => DateTime.utc(
    date.year,
    date.month + months,
    math.min(date.day, DateTime.utc(date.year, date.month + months + 1, 0).day),
  );
  void _move(DateTime next, {bool focus = true}) {
    if (next.year < 1 || next.year > 9999) return;
    final low = widget.model.decode(widget.model.min);
    final high = widget.model.decode(widget.model.max);
    if (low != null && dateIso(next).compareTo(dateIso(low)) < 0) {
      next = DateTime.utc(low.year, low.month, low.day);
    }
    if (high != null && dateIso(next).compareTo(dateIso(high)) > 0) {
      next = DateTime.utc(high.year, high.month, high.day);
    }
    setState(() {
      _active = next;
      _month = DateTime.utc(next.year, next.month);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && focus) _focus[dateIso(_active)]?.requestFocus();
    });
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final firstDay =
        KLocalization.of(
              context,
            ).calendar(locale: widget.locale?.name)['firstDay']
            as int;
    final weekOffset = (_active.weekday % 7 - firstDay + 7) % 7;
    DateTime? next;
    if (key == LogicalKeyboardKey.arrowLeft) {
      next = _active.subtract(const Duration(days: 1));
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      next = _active.add(const Duration(days: 1));
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      next = _active.subtract(const Duration(days: 7));
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      next = _active.add(const Duration(days: 7));
    }
    if (key == LogicalKeyboardKey.home) {
      next = _active.subtract(Duration(days: weekOffset));
    }
    if (key == LogicalKeyboardKey.end) {
      next = _active.add(Duration(days: 6 - weekOffset));
    }
    if (key == LogicalKeyboardKey.pageUp) {
      next = _shiftMonth(
        _active,
        HardwareKeyboard.instance.isShiftPressed ? -12 : -1,
      );
    }
    if (key == LogicalKeyboardKey.pageDown) {
      next = _shiftMonth(
        _active,
        HardwareKeyboard.instance.isShiftPressed ? 12 : 1,
      );
    }
    if (next == null) return KeyEventResult.ignored;
    _move(next);
    return KeyEventResult.handled;
  }

  bool _canShift(int direction) {
    final next = DateTime.utc(_month.year, _month.month + direction);
    if (next.year < 1 || next.year > 9999) return false;
    final low = widget.model.decode(widget.model.min);
    final high = widget.model.decode(widget.model.max);
    final month = dateIso(next).substring(0, 7);
    return (low == null ||
            month.compareTo(dateIso(low).substring(0, 7)) >= 0) &&
        (high == null || month.compareTo(dateIso(high).substring(0, 7)) <= 0);
  }

  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    final scaled = MediaQuery.textScalerOf(context).scale(t.fontControlSize);
    final dayHeight = math.max(
      math.max(t.sizeControl, t.sizeHitTarget),
      scaled + 16,
    );
    final calendar = KLocalization.of(
      context,
    ).calendar(locale: widget.locale?.name);
    final firstDay = calendar['firstDay'] as int;
    final names = List<String>.from(calendar['weekdays'] as List);
    final weekdayNames = List.generate(
      7,
      (index) => names[(index + firstDay) % 7],
    );
    final weekdays = weekdayNames
        .map((name) => name.characters.take(2).toString())
        .toList();
    final months = List<String>.from(calendar['months'] as List);
    final offset = (_month.weekday % 7 - firstDay + 7) % 7;
    final start = _month.subtract(Duration(days: offset));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(months),
        if (_view != 0) _choices(months, dayHeight),
        if (_view == 0)
          Row(
            children: [
              for (final (index, name) in weekdays.indexed)
                Expanded(
                  child: SizedBox(
                    height: math.max(24, scaled + 8),
                    child: Center(
                      child: Text(
                        name,
                        semanticsLabel: weekdayNames[index],
                        style: pickerTextStyle(
                          context,
                          color: t.colorTextMuted,
                        ).copyWith(fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (_view == 0)
          for (var row = 0; row < 6; row++)
            Row(
              children: [
                for (var column = 0; column < 7; column++)
                  Expanded(
                    child: _day(
                      start.add(Duration(days: row * 7 + column)),
                      dayHeight,
                    ),
                  ),
              ],
            ),
      ],
    );
  }

  bool _monthAllowed(int year, int month) {
    if (year < 1 || year > 9999) return false;
    final first = DateTime.utc(year, month),
        last = DateTime.utc(year, month + 1, 0);
    final low = widget.model.decode(widget.model.min),
        high = widget.model.decode(widget.model.max);
    return (low == null || dateIso(last).compareTo(dateIso(low)) >= 0) &&
        (high == null || dateIso(first).compareTo(dateIso(high)) <= 0);
  }

  bool _yearAllowed(int year) =>
      year >= 1 &&
      year <= 9999 &&
      List.generate(
        12,
        (i) => i + 1,
      ).any((month) => _monthAllowed(year, month));
  bool _canNavigate(int direction) => _view == 0
      ? _canShift(direction)
      : _view == 1
      ? _yearAllowed(_month.year + direction)
      : List.generate(
          12,
          (i) => _yearPage + direction * 12 + i,
        ).any(_yearAllowed);
  void _navigate(int direction) {
    widget.onBrowse?.call();
    if (_view == 0) {
      _move(_shiftMonth(_active, direction), focus: false);
    } else {
      setState(() {
        if (_view == 1) {
          _month = DateTime.utc(_month.year + direction, _month.month);
        } else {
          _yearPage += direction * 12;
        }
      });
    }
  }

  void _openView(int view) {
    widget.onBrowse?.call();
    setState(() {
      _view = view;
      _yearPage = ((_month.year - 1) ~/ 12) * 12 + 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _view != view) return;
      int? first, selected;
      for (var index = 0; index < 12; index++) {
        final year = view == 1 ? _month.year : _yearPage + index;
        final enabled = view == 1
            ? _monthAllowed(year, index + 1)
            : _yearAllowed(year);
        if (!enabled) continue;
        first ??= index;
        if (year == _active.year && (view == 2 || index + 1 == _active.month)) {
          selected = index;
        }
      }
      final index = selected ?? first;
      if (index != null) _focus['choice-$view-$index']?.requestFocus();
    });
  }

  Widget _header(List<String> months) {
    String text(String key) => widget.labels.text(
      key,
      widget.locale,
      localization: KLocalization.of(context),
    );
    final previous = _view == 0
        ? 'previousMonth'
        : _view == 1
        ? 'previousYear'
        : 'previousYears';
    final next = _view == 0
        ? 'nextMonth'
        : _view == 1
        ? 'nextYear'
        : 'nextYears';
    return Row(
      spacing: 8,
      children: [
        KIconButton(
          label: text(previous),
          icon: KIconName.chevronLeft,
          onPressed: _canNavigate(-1) ? () => _navigate(-1) : null,
        ),
        if (_view == 0) ...[
          Expanded(
            child: PickerAction(
              label: months[_month.month - 1],
              semanticLabel: '${text('month')}: ${months[_month.month - 1]}',
              onPressed: () => _openView(1),
            ),
          ),
          PickerAction(
            label: '${_month.year}',
            semanticLabel: '${text('year')}: ${_month.year}',
            onPressed: () => _openView(2),
          ),
        ] else
          Expanded(
            child: Center(
              child: Text(
                _view == 1
                    ? '${_month.year}'
                    : '$_yearPage–${math.min(9999, _yearPage + 11)}',
                style: pickerTextStyle(context),
              ),
            ),
          ),
        KIconButton(
          label: text(next),
          icon: KIconName.chevronRight,
          onPressed: _canNavigate(1) ? () => _navigate(1) : null,
        ),
      ],
    );
  }

  Widget _choices(List<String> months, double height) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var row = 0; row < 4; row++)
        Row(
          children: [
            for (var column = 0; column < 3; column++)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final index = row * 3 + column;
                    final year = _view == 1 ? _month.year : _yearPage + index;
                    final month = _view == 1 ? index + 1 : _month.month;
                    final enabled = _view == 1
                        ? _monthAllowed(year, month)
                        : _yearAllowed(year);
                    return PickerAction(
                      label: _view == 1
                          ? months[index].characters.take(3).toString()
                          : '$year',
                      semanticLabel: _view == 1 ? months[index] : '$year',
                      focusNode: _focus.putIfAbsent(
                        'choice-$_view-$index',
                        FocusNode.new,
                      ),
                      height: height,
                      width: double.infinity,
                      selected: _view == 1
                          ? year == _active.year && month == _active.month
                          : year == _active.year,
                      onPressed: !enabled
                          ? null
                          : () {
                              setState(() => _view = 0);
                              _move(
                                DateTime.utc(
                                  year,
                                  month,
                                  math.min(
                                    _active.day,
                                    DateTime.utc(year, month + 1, 0).day,
                                  ),
                                ),
                              );
                            },
                    );
                  },
                ),
              ),
          ],
        ),
    ],
  );
  Widget _day(DateTime day, double height) {
    final key = dateIso(day);
    final enabled =
        day.year >= 1 && day.year <= 9999 && widget.model.dayEnabled(day);
    final node = _focus.putIfAbsent(key, () => FocusNode());
    node.skipTraversal = key != dateIso(_active);
    return PickerAction(
      label: '${day.day}',
      semanticLabel: formatDate(day, widget.model.dateFormat),
      height: height,
      focusNode: node,
      width: double.infinity,
      selected: key == dateIso(widget.selected),
      muted: day.month != _month.month,
      onKeyEvent: _key,
      onPressed: enabled
          ? () {
              _active = day;
              widget.onSelected(day);
            }
          : null,
    );
  }
}
