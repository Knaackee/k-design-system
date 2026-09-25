import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_button.dart';
import '../primitives/k_text.dart';
import 'k_chart_parts.dart';
import '../extended_components.dart' show KSpinner;
import 'k_chart_types.dart';
import 'k_family_plot.dart';

class KDonutChart extends StatefulWidget {
  const KDonutChart({
    required this.segments,
    required this.label,
    this.description,
    this.selectedId,
    this.onSelectionChange,
    this.visibleSegmentIds,
    this.onVisibleSegmentsChange,
    this.formatValue,
    this.innerRadiusRatio = .65,
    this.centerContent,
    this.height,
    this.loading = false,
    this.error,
    this.emptyContent,
    this.loadingContent,
    this.errorContent,
    super.key,
  });
  final List<KChartSegment> segments;
  final String label;
  final String? description, selectedId, error;
  final ValueChanged<String?>? onSelectionChange;
  final List<String>? visibleSegmentIds;
  final ValueChanged<List<String>>? onVisibleSegmentsChange;
  final String Function(double)? formatValue;
  final double innerRadiusRatio;
  final Widget? centerContent, emptyContent, loadingContent, errorContent;
  final double? height;
  final bool loading;
  @override
  State<KDonutChart> createState() => _KDonutChartState();
}

class _KDonutChartState extends State<KDonutChart> {
  final _focus = FocusNode();
  String? _hover;
  double get _ratio => widget.innerRadiusRatio.isFinite
      ? widget.innerRadiusRatio.clamp(0.0, .95)
      : .65;
  List<KChartSegment> get _visible => widget.segments
      .where(
        (s) =>
            (widget.visibleSegmentIds == null ||
            widget.visibleSegmentIds!.contains(s.id)),
      )
      .toList();
  List<KChartSegment> get _valid =>
      _visible.where((s) => s.value.isFinite && s.value > 0).toList();
  String _format(double value) =>
      widget.formatValue?.call(value) ??
      (value == value.truncateToDouble()
          ? value.toInt().toString()
          : value.toString());
  void _select(String? id) {
    if (id != widget.selectedId) widget.onSelectionChange?.call(id);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _hover = null);
      _select(null);
      return KeyEventResult.handled;
    }
    final next =
        event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowDown;
    final previous =
        event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowUp;
    final home = event.logicalKey == LogicalKeyboardKey.home,
        end = event.logicalKey == LogicalKeyboardKey.end;
    if (_valid.isEmpty || (!next && !previous && !home && !end)) {
      return KeyEventResult.ignored;
    }
    final current = _valid.indexWhere((s) => s.id == widget.selectedId);
    final index = home
        ? 0
        : end
        ? _valid.length - 1
        : current < 0
        ? (previous ? _valid.length - 1 : 0)
        : (current + (next ? 1 : -1)).clamp(0, _valid.length - 1);
    setState(() => _hover = null);
    _select(_valid[index].id);
    return KeyEventResult.handled;
  }

  String? _hit(Offset p, Size size, KDesignTokens t) {
    final w =
        size.width - t.componentChartInsetLeft - t.componentChartInsetRight;
    final h =
        size.height - t.componentChartInsetTop - t.componentChartInsetBottom;
    final center = Offset(
      t.componentChartInsetLeft + w / 2,
      t.componentChartInsetTop + h / 2,
    );
    final radius = math.min(w, h) / 2;
    final delta = p - center;
    if (delta.distance > radius || delta.distance < radius * _ratio) {
      return null;
    }
    final angle =
        (math.atan2(delta.dy, delta.dx) + math.pi / 2) % (2 * math.pi);
    final total = _valid.fold(0.0, (sum, s) => sum + s.value);
    var cumulative = 0.0;
    for (final s in _valid) {
      cumulative += s.value / total * 2 * math.pi;
      if (angle <= cumulative) return s.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final active = _valid
        .where((s) => s.id == (_hover ?? widget.selectedId))
        .firstOrNull;
    final message = widget.loading
        ? (widget.loadingContent ?? const KSpinner(label: 'Loading chart'))
        : widget.error != null
        ? (widget.errorContent ?? KText(widget.error!))
        : _valid.isEmpty
        ? (widget.emptyContent ?? const KText('No data to display'))
        : null;
    return TapRegion(
      onTapOutside: (_) {
        _select(null);
        setState(() => _hover = null);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: t.spaceControlGap,
            runSpacing: t.spaceControlGap,
            children: [
              for (final s in widget.segments)
                Semantics(
                  toggled: _visible.any((v) => v.id == s.id),
                  child: Opacity(
                    opacity: _visible.any((v) => v.id == s.id)
                        ? 1
                        : t.opacityDisabled,
                    child: KButton(
                      label: s.label,
                      variant: KButtonVariant.ghost,
                      leading: Container(
                        width: t.componentChartPointRadius * 2,
                        height: t.componentChartPointRadius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: familyColor(t, s.colorIndex),
                        ),
                      ),
                      onPressed: widget.onVisibleSegmentsChange == null
                          ? null
                          : () {
                              final ids = _visible.map((s) => s.id).toList();
                              ids.contains(s.id)
                                  ? ids.remove(s.id)
                                  : ids.add(s.id);
                              widget.onVisibleSegmentsChange!(ids);
                            },
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: t.spaceContentActionGap),
          SizedBox(
            height: widget.height ?? t.componentChartHeight,
            child: message != null
                ? Center(child: message)
                : LayoutBuilder(
                    builder: (context, c) {
                      final w = math.max(
                        1.0,
                        c.maxWidth -
                            t.componentChartInsetLeft -
                            t.componentChartInsetRight,
                      );
                      final h = math.max(
                        1.0,
                        c.maxHeight -
                            t.componentChartInsetTop -
                            t.componentChartInsetBottom,
                      );
                      final radius = math.min(w, h) / 2;
                      return Semantics(
                        label: widget.label,
                        hint: widget.description,
                        child: Focus(
                          focusNode: _focus,
                          onKeyEvent: _key,
                          child: MouseRegion(
                            onHover: (event) {
                              final id = _hit(
                                event.localPosition,
                                c.biggest,
                                t,
                              );
                              if (id != _hover) setState(() => _hover = id);
                            },
                            onExit: (_) => setState(() => _hover = null),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (event) {
                                _focus.requestFocus();
                                setState(() => _hover = null);
                                _select(
                                  _hit(event.localPosition, c.biggest, t),
                                );
                              },
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: t.componentChartInsetLeft,
                                    top: t.componentChartInsetTop,
                                    width: w,
                                    height: h,
                                    child: IgnorePointer(
                                      child: PieChart(
                                        PieChartData(
                                          startDegreeOffset: 270,
                                          centerSpaceRadius: radius * _ratio,
                                          sectionsSpace: 0,
                                          borderData: FlBorderData(show: false),
                                          pieTouchData: PieTouchData(
                                            enabled: false,
                                          ),
                                          sections: [
                                            for (final s in _valid)
                                              PieChartSectionData(
                                                value: s.value,
                                                borderSide: BorderSide(
                                                  color: s.id == active?.id
                                                      ? t.colorTextPrimary
                                                      : t.colorSurfaceRaised,
                                                  width:
                                                      t.componentChartLineWidth,
                                                ),
                                                color: familyColor(
                                                  t,
                                                  s.colorIndex,
                                                ),
                                                radius: radius * (1 - _ratio),
                                                showTitle: false,
                                              ),
                                          ],
                                        ),
                                        duration:
                                            MediaQuery.disableAnimationsOf(
                                              context,
                                            )
                                            ? Duration.zero
                                            : t.motionFast,
                                      ),
                                    ),
                                  ),
                                  if (widget.centerContent != null &&
                                      _ratio > 0)
                                    Positioned(
                                      left:
                                          t.componentChartInsetLeft +
                                          w / 2 -
                                          radius * _ratio,
                                      top:
                                          t.componentChartInsetTop +
                                          h / 2 -
                                          radius * _ratio,
                                      width: radius * _ratio * 2,
                                      height: radius * _ratio * 2,
                                      child: IgnorePointer(
                                        child: Center(
                                          child: widget.centerContent,
                                        ),
                                      ),
                                    ),
                                  if (active != null)
                                    Positioned(
                                      top: t.componentChartInsetTop,
                                      right: t.componentChartInsetRight,
                                      child: IgnorePointer(
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: w,
                                          ),
                                          child: KChartTooltip(
                                            series: [
                                              KChartSeries(
                                                id: active.id,
                                                label: active.label,
                                                colorIndex: active.colorIndex,
                                                points: [
                                                  KChartPoint(
                                                    id: active.id,
                                                    x: 0,
                                                    y: active.value,
                                                  ),
                                                ],
                                              ),
                                            ],
                                            x: 0,
                                            xAxis: KChartAxis(
                                              min: 0,
                                              max: 1,
                                              ticks: const [],
                                              format: (_) => active.label,
                                            ),
                                            yAxis: KChartAxis(
                                              min: 0,
                                              max: active.value,
                                              ticks: const [],
                                              format: _format,
                                            ),
                                            colorForSeries: (s) =>
                                                familyColor(t, s.colorIndex),
                                          ),
                                        ),
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
          ),
        ],
      ),
    );
  }
}
