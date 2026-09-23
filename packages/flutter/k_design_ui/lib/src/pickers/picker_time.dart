import '../localization/k_localization.dart';
import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../forms/form_style.dart';
import 'picker_model.dart';
import 'picker_style.dart';
import 'picker_types.dart';

class PickerTime extends StatelessWidget {
  const PickerTime({
    required this.value,
    required this.onChanged,
    required this.format,
    required this.step,
    required this.locale,
    required this.labels,
    this.autofocus = false,
    super.key,
  });
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final KTimeFormat format;
  final int step;
  final KPickerLocale? locale;
  final KPickerLabels labels;
  final bool autofocus;
  @override
  Widget build(BuildContext context) {
    final minutes = {
      for (var minute = 0; minute < 60; minute += step) minute,
      value.minute,
    }.toList()..sort();
    final h12 = format == KTimeFormat.h12;
    void update(int hour, int minute) =>
        onChanged(DateTime.utc(2000, 1, 1, hour, minute));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: PickerTimeColumn(
            label: labels.text(
              'hours',
              locale,
              localization: KLocalization.of(context),
            ),
            values: List.generate(h12 ? 12 : 24, (i) => two(h12 ? i + 1 : i)),
            selected: two(
              h12 ? (value.hour % 12 == 0 ? 12 : value.hour % 12) : value.hour,
            ),
            autofocus: autofocus,
            onChanged: (hour) => update(
              h12
                  ? int.parse(hour) % 12 + (value.hour >= 12 ? 12 : 0)
                  : int.parse(hour),
              value.minute,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PickerTimeColumn(
            label: labels.text(
              'minutes',
              locale,
              localization: KLocalization.of(context),
            ),
            values: minutes.map(two).toList(),
            selected: two(value.minute),
            onChanged: (minute) => update(value.hour, int.parse(minute)),
          ),
        ),
        if (h12) ...[
          const SizedBox(width: 8),
          Expanded(
            child: PickerTimeColumn(
              label: labels.text(
                'period',
                locale,
                localization: KLocalization.of(context),
              ),
              values: const ['AM', 'PM'],
              selected: value.hour < 12 ? 'AM' : 'PM',
              onChanged: (period) => update(
                value.hour % 12 + (period == 'PM' ? 12 : 0),
                value.minute,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class PickerTimeColumn extends StatefulWidget {
  const PickerTimeColumn({
    required this.label,
    required this.values,
    required this.selected,
    required this.onChanged,
    this.autofocus = false,
    super.key,
  });
  final String label, selected;
  final List<String> values;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  @override
  State<PickerTimeColumn> createState() => _PickerTimeColumnState();
}

class _PickerTimeColumnState extends State<PickerTimeColumn> {
  final _scroll = ScrollController();
  final _nodes = <String, FocusNode>{};
  double _height = 32;
  @override
  void initState() {
    super.initState();
    _reveal(focus: widget.autofocus);
  }

  @override
  void didUpdateWidget(covariant PickerTimeColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _reveal(focus: _nodes.values.any((node) => node.hasFocus));
    }
  }

  void _reveal({bool focus = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scroll.hasClients) {
        final target = (widget.values.indexOf(widget.selected) - 2) * _height;
        _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
      }
      if (focus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _nodes[widget.selected]?.requestFocus();
        });
      }
    });
  }

  void _choose(String value) {
    widget.onChanged(value);
    _nodes[value]?.requestFocus();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    var index = widget.values.indexOf(widget.selected);
    if (key == LogicalKeyboardKey.arrowDown) {
      index++;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      index--;
    } else if (key == LogicalKeyboardKey.home) {
      index = 0;
    } else if (key == LogicalKeyboardKey.end) {
      index = widget.values.length - 1;
    } else {
      return KeyEventResult.ignored;
    }
    _choose(widget.values[index.clamp(0, widget.values.length - 1)]);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    _height = math.max(
      math.max(t.sizeControl, t.sizeHitTarget),
      MediaQuery.textScalerOf(context).scale(t.fontControlSize) + 16,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: t.spaceControlGap,
      children: [
        Text(widget.label, style: pickerTextStyle(context)),
        Semantics(
          container: true,
          label: widget.label,
          child: SizedBox(
            height: _height * 5,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  ...ScrollConfiguration.of(context).dragDevices,
                  PointerDeviceKind.mouse,
                },
              ),
              child: Scrollbar(
                controller: _scroll,
                child: ListView(
                  controller: _scroll,
                  padding: EdgeInsets.zero,
                  itemExtent: _height,
                  children: [
                    for (final value in widget.values)
                      Builder(
                        builder: (context) {
                          final node = _nodes.putIfAbsent(
                            value,
                            () => FocusNode(),
                          );
                          node.skipTraversal = value != widget.selected;
                          return PickerAction(
                            label: value,
                            semanticLabel: value,
                            height: _height,
                            width: double.infinity,
                            selected: value == widget.selected,
                            focusNode: node,
                            onKeyEvent: _key,
                            onPressed: () => _choose(value),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
