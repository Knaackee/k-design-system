import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'gantt_model.dart';
import 'gantt_painter.dart';

/// Controlled reference: edits are proposals; only incoming tasks change data.
class GanttCanvas extends StatefulWidget {
  const GanttCanvas({
    super.key,
    required this.tasks,
    required this.links,
    required this.start,
    required this.end,
    required this.onPropose,
    required this.onOpen,
    this.onSelect,
    this.selectedId,
    this.scale = 'weeks',
    this.height = 480,
    this.expanded,
    this.onScroll,
    this.monthLabel,
    this.semanticLabel = 'Timeline',
  });
  final List<GanttTask> tasks;
  final List<GanttLink> links;
  final DateTime start, end;
  final String scale, semanticLabel;
  final double height;
  final String? selectedId;
  final Set<String>? expanded;
  final ValueChanged<GanttTask> onPropose;
  final ValueChanged<String> onOpen;
  final ValueChanged<String?>? onSelect;
  final ValueChanged<Offset>? onScroll;
  final String Function(DateTime)? monthLabel;
  @override
  State<GanttCanvas> createState() => _GanttCanvasState();
}

class _GanttCanvasState extends State<GanttCanvas> {
  Timer? _hold;
  int? _pointer;
  Offset? _origin;
  Offset _scroll = Offset.zero, _initialScroll = Offset.zero;
  GanttTask? _original, _preview;
  String? _editing;
  String _mode = 'pan';
  bool _moved = false, _activated = false;
  late GanttGeometry _geometry;
  final _focus = FocusNode();

  @override
  void didUpdateWidget(covariant GanttCanvas old) {
    super.didUpdateWidget(old);
    if (old.tasks != widget.tasks ||
        old.start != widget.start ||
        old.end != widget.end ||
        old.scale != widget.scale ||
        old.expanded != widget.expanded) {
      _reset();
    }
  }

  void _reset() {
    _hold?.cancel();
    _pointer = null;
    _origin = null;
    _original = _preview = null;
    _editing = null;
  }

  void _cancel() {
    setState(_reset);
  }

  @override
  void dispose() {
    _hold?.cancel();
    _focus.dispose();
    super.dispose();
  }

  Offset _clamp(Offset value) => Offset(
    value.dx.clamp(0, math.max(0, _geometry.contentWidth - _geometry.width)),
    value.dy.clamp(0, math.max(0, _geometry.contentHeight - widget.height)),
  );
  void _pan(Offset value) {
    setState(() => _scroll = _clamp(value));
    widget.onScroll?.call(_scroll);
  }

  bool _editable(GanttTask task) => !task.readOnly && task.type != 'summary';

  void _down(PointerDownEvent event) {
    if (_pointer != null || event.buttons != kPrimaryButton) return;
    _focus.requestFocus();
    _pointer = event.pointer;
    _origin = event.localPosition;
    _initialScroll = _scroll;
    _moved = _activated = false;
    _original = _preview = null;
    _mode = 'pan';
    if (event.localPosition.dy < GanttGeometry.axisHeight) {
      setState(() => _editing = null);
      return;
    }
    if (_editing != null) {
      final task = widget.tasks.where((t) => t.id == _editing).firstOrNull;
      final rect = _geometry.rects[_editing];
      if (task != null && rect != null && task.end != null && _editable(task)) {
        for (final edge in ['start', 'end']) {
          final target = Rect.fromCenter(
            center: Offset(
              edge == 'start' ? rect.left : rect.right,
              rect.center.dy,
            ),
            width: 44,
            height: 44,
          );
          if (target.contains(event.localPosition)) {
            _original = task;
            _mode = edge;
            return;
          }
        }
      }
    }
    for (final task in _geometry.visible.reversed) {
      if (!(_geometry.rects[task.id]?.contains(event.localPosition) ?? false)) {
        continue;
      }
      _original = task;
      if (_editing == task.id && _editable(task)) {
        _mode = 'move';
        return;
      }
      _hold = Timer(const Duration(milliseconds: 500), () {
        if (!mounted || _pointer == null || _moved || !_editable(task)) return;
        setState(() {
          _editing = task.id;
          _mode = 'move';
          _activated = true;
        });
        widget.onSelect?.call(task.id);
      });
      return;
    }
    setState(() => _editing = null);
  }

  void _move(PointerMoveEvent event) {
    if (_pointer != event.pointer || _origin == null) return;
    final delta = event.localPosition - _origin!;
    if (delta.distance > 8) {
      _moved = true;
      _hold?.cancel();
    }
    if (!_moved) return;
    if (_mode == 'pan') {
      _pan(_initialScroll - delta);
      return;
    }
    if (_original case final task?) {
      final days = (delta.dx / _geometry.dayWidth).round();
      setState(() => _preview = moveGanttTask(task, days, _mode));
    }
  }

  void _up(PointerUpEvent event) {
    if (_pointer != event.pointer) return;
    _hold?.cancel();
    final proposal = _preview;
    final original = _original;
    final open =
        !_moved && !_activated && original != null && _editing != original.id;
    final changed =
        proposal != null &&
        original != null &&
        (ganttDayIndex(proposal.start) != ganttDayIndex(original.start) ||
            proposal.end != original.end);
    setState(() {
      _pointer = null;
      _origin = null;
      _original = _preview = null;
      if (_moved) _editing = null;
    });
    if (_moved && changed) widget.onPropose(proposal);
    if (open) {
      widget.onSelect?.call(original.id);
      widget.onOpen(original.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return TapRegion(
      onTapOutside: (_) => _cancel(),
      child: Focus(
        focusNode: _focus,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _cancel();
            return KeyEventResult.handled;
          }
          final delta = switch (event.logicalKey) {
            LogicalKeyboardKey.arrowLeft => const Offset(-32, 0),
            LogicalKeyboardKey.arrowRight => const Offset(32, 0),
            LogicalKeyboardKey.arrowUp => const Offset(0, -48),
            LogicalKeyboardKey.arrowDown => const Offset(0, 48),
            _ => null,
          };
          if (delta != null) {
            _pan(_scroll + delta);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            GanttGeometry geometry(Offset scroll) => GanttGeometry(
              tasks: summarizeGanttTasks(widget.tasks),
              start: widget.start,
              end: widget.end,
              width: constraints.maxWidth,
              height: widget.height,
              rowHeight: t.sizeControl + 12,
              scale: widget.scale,
              scroll: scroll,
              expanded: widget.expanded,
            );
            _geometry = geometry(_scroll);
            final bounded = _clamp(_scroll);
            if (bounded != _scroll) {
              _scroll = bounded;
              _geometry = geometry(_scroll);
            }
            final plot = Rect.fromLTWH(
              0,
              GanttGeometry.axisHeight,
              constraints.maxWidth,
              math.max(0, widget.height - GanttGeometry.axisHeight),
            );
            return SizedBox(
              height: widget.height,
              child: Semantics(
                label: widget.semanticLabel,
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
                        GestureBinding.instance.pointerSignalResolver.register(
                          event,
                          (_) {
                            _pan(_scroll + event.scrollDelta);
                          },
                        );
                      }
                    },
                    onPointerPanZoomUpdate: (event) =>
                        _pan(_scroll - event.panDelta),
                    child: ClipRect(
                      child: CustomPaint(
                        painter: GanttPainter(
                          tokens: t,
                          geometry: _geometry,
                          links: widget.links,
                          selected: widget.selectedId,
                          editing: _editing,
                          preview: _preview,
                          monthLabel: widget.monthLabel,
                        ),
                        child: Stack(
                          children: [
                            for (final task in _geometry.visible)
                              if (_geometry.rects[task.id] case final rect?
                                  when rect.overlaps(plot))
                                Positioned.fromRect(
                                  rect: rect.intersect(plot),
                                  child: Semantics(
                                    label: task.text,
                                    button: true,
                                    selected: widget.selectedId == task.id,
                                    onTap: () {
                                      widget.onSelect?.call(task.id);
                                      widget.onOpen(task.id);
                                    },
                                    onLongPress: !_editable(task)
                                        ? null
                                        : () => setState(
                                            () => _editing = task.id,
                                          ),
                                    child: Focus(
                                      onKeyEvent: (_, event) {
                                        if (event is KeyDownEvent &&
                                            (event.logicalKey ==
                                                    LogicalKeyboardKey.enter ||
                                                event.logicalKey ==
                                                    LogicalKeyboardKey.space)) {
                                          widget.onSelect?.call(task.id);
                                          widget.onOpen(task.id);
                                          return KeyEventResult.handled;
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
