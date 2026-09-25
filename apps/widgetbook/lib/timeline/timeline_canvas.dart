import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'timeline_model.dart';
import 'timeline_painter.dart';

class TimelineCanvas extends StatefulWidget {
  const TimelineCanvas({
    super.key,
    required this.items,
    required this.groups,
    required this.selectedId,
    required this.onSelect,
    required this.onItemOpen,
    required this.onPropose,
    required this.windowStart,
    required this.windowEnd,
    required this.onWindowChange,
    required this.today,
  });
  final List<TimelineEntry> items;
  final List<TimelineGroup> groups;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final ValueChanged<String> onItemOpen;
  final ValueChanged<TimelineEntry> onPropose;
  final DateTime windowStart, windowEnd, today;
  final void Function(DateTime, DateTime) onWindowChange;
  @override
  State<TimelineCanvas> createState() => _TimelineCanvasState();
}

class _TimelineCanvasState extends State<TimelineCanvas> {
  Timer? _hold;
  int? _pointer;
  Offset? _origin;
  TimelineEntry? _original, _preview;
  String? _editing;
  String _mode = 'pan';
  bool _moved = false, _activated = false;
  int _panDays = 0;
  double _scroll = 0, _initialScroll = 0;
  DateTime? _initialStart, _initialEnd;
  late TimelineGeometry _geometry;
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _hold?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _cancel() {
    _hold?.cancel();
    setState(() {
      _pointer = null;
      _origin = null;
      _preview = null;
      _original = null;
      _editing = null;
      _panDays = 0;
    });
  }

  void _down(PointerDownEvent event) {
    if (_pointer != null || event.buttons != 1) return;
    _focus.requestFocus();
    _pointer = event.pointer;
    _origin = event.localPosition;
    _initialStart = widget.windowStart;
    _initialEnd = widget.windowEnd;
    _initialScroll = _scroll;
    _moved = false;
    _activated = false;
    _mode = 'pan';
    _original = null;
    // Handles extend beyond the bar while their centre stays on its edge.
    if (_editing != null) {
      final rect = _geometry.rects[_editing];
      final entry = widget.items.where((e) => e.id == _editing).firstOrNull;
      if (rect != null && entry != null && entry.end != null) {
        for (final side in ['start', 'end']) {
          final center = Offset(
            side == 'start' ? rect.left : rect.right,
            rect.center.dy,
          );
          if (Rect.fromCenter(
            center: center,
            width: 44,
            height: 44,
          ).contains(event.localPosition)) {
            _mode = side;
            _original = entry;
            return;
          }
        }
      }
    }
    for (final entry in widget.items.reversed) {
      if (!(_geometry.rects[entry.id]?.contains(event.localPosition) ??
          false)) {
        continue;
      }
      if (event.localPosition.dx < _geometry.labelWidth ||
          event.localPosition.dy < TimelineGeometry.axisHeight) {
        break;
      }
      _original = entry;
      if (_editing == entry.id && !entry.readOnly) {
        _mode = 'move';
        return;
      }
      _hold = Timer(const Duration(milliseconds: 500), () {
        if (!mounted || _pointer == null || _moved || entry.readOnly) return;
        setState(() {
          _editing = entry.id;
          _mode = 'move';
          _activated = true;
        });
        widget.onSelect(entry.id);
      });
      break;
    }
  }

  void _move(PointerMoveEvent event) {
    if (_pointer != event.pointer || _origin == null) return;
    final delta = event.localPosition - _origin!;
    if (delta.distance > 7) {
      _moved = true;
      _hold?.cancel();
    }
    if (!_moved) return;
    final days = (delta.dx / _geometry.dayWidth).round();
    if (_mode == 'pan') {
      setState(() {
        _panDays = -days;
        _scroll = (_initialScroll - delta.dy).clamp(
          0,
          math.max(0, _geometry.contentHeight - 420),
        );
      });
      return;
    }
    final entry = _original;
    if (entry == null || entry.readOnly) return;
    TimelineEntry next;
    if (_mode == 'start') {
      final start = addTimelineDays(entry.start, days);
      if (dayIndex(start) >= dayIndex(entry.end!)) return;
      next = entry.copyWith(start: start);
    } else if (_mode == 'end') {
      final end = addTimelineDays(entry.end!, days);
      if (dayIndex(end) <= dayIndex(entry.start)) return;
      next = entry.copyWith(end: end);
    } else {
      final group = _geometry.groupAt(event.localPosition.dy) ?? entry.group;
      next = entry.copyWith(
        start: addTimelineDays(entry.start, days),
        end: entry.end == null ? null : addTimelineDays(entry.end!, days),
        group: group,
      );
    }
    setState(() => _preview = next);
  }

  void _up(PointerUpEvent event) {
    if (_pointer != event.pointer) return;
    _hold?.cancel();
    final proposal = _preview;
    if (_moved && _mode == 'pan') {
      widget.onWindowChange(
        addTimelineDays(_initialStart!, _panDays),
        addTimelineDays(_initialEnd!, _panDays),
      );
    } else if (_moved && proposal != null) {
      widget.onPropose(proposal);
    } else if (!_activated &&
        !_moved &&
        _original != null &&
        _editing != _original!.id) {
      widget.onSelect(_original!.id);
      widget.onItemOpen(_original!.id);
    } else if (!_activated && !_moved && _original == null) {
      _editing = null;
      widget.onSelect(null);
    }
    setState(() {
      if (_moved) _editing = null;
      _pointer = null;
      _origin = null;
      _preview = null;
      _original = null;
      _panDays = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Focus(
      focusNode: _focus,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _cancel();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          _geometry = TimelineGeometry(
            widget.items,
            widget.groups,
            constraints.maxWidth,
            addTimelineDays(widget.windowStart, _panDays),
            dayIndex(widget.windowEnd) - dayIndex(widget.windowStart),
            tokens.sizeControl + tokens.borderWidthDefault * 2,
            tokens.spaceControlGap,
            _scroll,
          );
          return SizedBox(
            height: 420,
            child: RawGestureDetector(
              gestures: {
                EagerGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<
                      EagerGestureRecognizer
                    >(EagerGestureRecognizer.new, (_) {}),
              },
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _down,
                onPointerMove: _move,
                onPointerUp: _up,
                onPointerCancel: (_) => _cancel(),
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    final dx = event.scrollDelta.dx != 0
                        ? event.scrollDelta.dx
                        : event.scrollDelta.dy;
                    final days = (dx / _geometry.dayWidth).round();
                    if (days != 0) {
                      widget.onWindowChange(
                        addTimelineDays(widget.windowStart, days),
                        addTimelineDays(widget.windowEnd, days),
                      );
                    }
                  }
                },
                child: CustomPaint(
                  painter: TimelinePainter(
                    tokens,
                    _geometry,
                    widget.items,
                    widget.groups,
                    widget.selectedId,
                    _editing,
                    _preview,
                    widget.today,
                  ),
                  child: Stack(
                    children: [
                      for (final entry in widget.items)
                        if (_geometry.rects[entry.id] case final rect?
                            when rect.overlaps(
                              Rect.fromLTWH(
                                _geometry.labelWidth,
                                TimelineGeometry.axisHeight,
                                math.max(
                                  0,
                                  constraints.maxWidth - _geometry.labelWidth,
                                ),
                                420 - TimelineGeometry.axisHeight,
                              ),
                            ))
                          Positioned.fromRect(
                            rect: rect.intersect(
                              Rect.fromLTWH(
                                _geometry.labelWidth,
                                TimelineGeometry.axisHeight,
                                math.max(
                                  0,
                                  constraints.maxWidth - _geometry.labelWidth,
                                ),
                                420 - TimelineGeometry.axisHeight,
                              ),
                            ),
                            child: Semantics(
                              label: entry.label,
                              button: true,
                              selected: widget.selectedId == entry.id,
                              onTap: () {
                                widget.onSelect(entry.id);
                                widget.onItemOpen(entry.id);
                              },
                              onLongPress: entry.readOnly
                                  ? null
                                  : () {
                                      setState(() => _editing = entry.id);
                                      widget.onSelect(entry.id);
                                    },
                              child: const SizedBox.expand(),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
