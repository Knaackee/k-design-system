import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_button.dart';
import '../primitives/k_text.dart';
import '../extended_components.dart' show KSpinner;
import 'k_chart_types.dart';
import 'k_chart_parts.dart';
import 'k_family_plot.dart';

/// Controlled, renderer-independent line chart. Data stays in caller order.
class KCartesianChart extends StatefulWidget {
  const KCartesianChart({
    required this.series,
    required this.xAxis,
    required this.yAxis,
    required this.label,
    this.description,
    this.area = false,
    this.stacked = false,
    this.orientation = KChartOrientation.vertical,
    this.selectedPoint,
    this.onSelectionChange,
    this.visibleSeriesIds,
    this.onVisibleSeriesChange,
    this.showDataTable = false,
    this.dataTableLabel = 'Data table',
    this.dataTableXAxisLabel = 'Date',
    this.loading = false,
    this.error,
    this.emptyContent,
    this.loadingContent,
    this.errorContent,
    this.height,
    super.key,
  });
  final List<KChartSeries> series;
  final KChartAxis xAxis;
  final KChartAxis yAxis;
  final String label;
  final String? description;
  final bool area;
  final bool stacked;
  final KChartOrientation orientation;
  final KChartSelection? selectedPoint;
  final ValueChanged<KChartSelection?>? onSelectionChange;
  final List<String>? visibleSeriesIds;
  final ValueChanged<List<String>>? onVisibleSeriesChange;
  final bool showDataTable;
  final String dataTableLabel;
  final String dataTableXAxisLabel;
  final bool loading;
  final String? error;
  final Widget? emptyContent;
  final Widget? loadingContent;
  final Widget? errorContent;
  final double? height;
  @override
  State<KCartesianChart> createState() => _KCartesianChartState();
}

class _KCartesianChartState extends State<KCartesianChart> {
  final _focus = FocusNode();
  KChartSelection? _hover;
  bool _valid(KChartPoint p) =>
      p.y != null &&
      p.x.isFinite &&
      p.y!.isFinite &&
      p.x >= widget.xAxis.min &&
      p.x <= widget.xAxis.max;
  void _select(KChartSelection? selection) {
    if (selection != widget.selectedPoint) {
      widget.onSelectionChange?.call(selection);
    }
  }

  List<KChartSeries> get _visible => widget.series
      .where(
        (s) =>
            widget.visibleSeriesIds == null ||
            widget.visibleSeriesIds!.contains(s.id),
      )
      .toList();
  List<(KChartSeries, KChartPoint)> get _points => [
    for (final s in _visible)
      for (final p in s.points)
        if (_valid(p)) (s, p),
  ];
  (KChartSeries, KChartPoint)? _resolve(KChartSelection? selection) {
    for (final entry in _points) {
      if (entry.$1.id == selection?.seriesId &&
          entry.$2.id == selection?.pointId) {
        return entry;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KChartSelection? _nearest(Offset local, Size size, KDesignTokens t) {
    final width =
        size.width - t.componentChartInsetLeft - t.componentChartInsetRight;
    final height =
        size.height - t.componentChartInsetTop - t.componentChartInsetBottom;
    if (width <= 0 || height <= 0) return null;
    final horizontal = widget.orientation == KChartOrientation.horizontal;
    final plot = Rect.fromLTWH(
      t.componentChartInsetLeft,
      t.componentChartInsetTop,
      width,
      height,
    );
    if (!plot.contains(local)) return null;
    final xs = _points.map((entry) => entry.$2.x).toSet().toList()..sort();
    var spacing = widget.xAxis.max - widget.xAxis.min;
    for (var i = 1; i < xs.length; i++) {
      if (xs[i] - xs[i - 1] < spacing) spacing = xs[i] - xs[i - 1];
    }
    final band =
        .72 *
        spacing /
        (widget.xAxis.max - widget.xAxis.min) *
        (horizontal ? height : width);
    double distance = double.infinity;
    KChartSelection? result;
    for (final (s, p) in _points) {
      final value = familyValue(_visible, s, p, widget.stacked);
      final base = widget.stacked ? value - p.y! : 0.0;
      final category =
          widget.xAxis.fraction(p.x) * (horizontal ? height : width);
      final slot = widget.stacked ? band : band / _visible.length;
      final start =
          category -
          band / 2 +
          (widget.stacked ? 0 : _visible.indexOf(s) * slot);
      final v0 = widget.yAxis.fraction(base) * (horizontal ? width : height);
      final v1 = widget.yAxis.fraction(value) * (horizontal ? width : height);
      if (!widget.area) {
        final min = v0 < v1 ? v0 : v1, max = v0 > v1 ? v0 : v1;
        final rect = horizontal
            ? Rect.fromLTWH(plot.left + min, plot.top + start, max - min, slot)
            : Rect.fromLTWH(
                plot.left + start,
                plot.top + height - max,
                slot,
                max - min,
              );
        if (rect.contains(local)) {
          return KChartSelection(seriesId: s.id, pointId: p.id);
        }
      } else {
        final dx = plot.left + category - local.dx;
        final dy = plot.top + height - v1 - local.dy;
        final d = dx * dx + dy * dy;
        if (d < distance) {
          distance = d;
          result = KChartSelection(seriesId: s.id, pointId: p.id);
        }
      }
    }
    return result;
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _hover = null);
      _select(null);
      return KeyEventResult.handled;
    }
    final direction = event.logicalKey == LogicalKeyboardKey.arrowRight
        ? 1
        : event.logicalKey == LogicalKeyboardKey.arrowLeft
        ? -1
        : 0;
    final home = event.logicalKey == LogicalKeyboardKey.home;
    final end = event.logicalKey == LogicalKeyboardKey.end;
    if ((!home && !end && direction == 0) || _points.isEmpty) {
      return KeyEventResult.ignored;
    }
    final selected = _resolve(widget.selectedPoint);
    final series = selected?.$1 ?? _points.first.$1;
    final points = series.points.where(_valid).toList()
      ..sort((a, b) => a.x.compareTo(b.x));
    final current = points.indexWhere((p) => p.id == selected?.$2.id);
    final next = home
        ? 0
        : end
        ? points.length - 1
        : current < 0
        ? (direction > 0 ? 0 : points.length - 1)
        : (current + direction).clamp(0, points.length - 1);
    setState(() => _hover = null);
    _select(KChartSelection(seriesId: series.id, pointId: points[next].id));
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final active = _resolve(_hover) ?? _resolve(widget.selectedPoint);
    final message = widget.loading
        ? widget.loadingContent ?? const KSpinner(label: 'Loading chart')
        : widget.error != null
        ? widget.errorContent ?? KText(widget.error!)
        : _points.isEmpty
        ? widget.emptyContent ?? const KText('No data to display')
        : null;
    return TapRegion(
      onTapOutside: (_) {
        _select(null);
        if (_hover != null) setState(() => _hover = null);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: t.spaceControlGap,
            runSpacing: t.spaceControlGap,
            children: [
              for (final s in widget.series)
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
                      onPressed: widget.onVisibleSeriesChange == null
                          ? null
                          : () {
                              final ids = _visible.map((v) => v.id).toList();
                              ids.contains(s.id)
                                  ? ids.remove(s.id)
                                  : ids.add(s.id);
                              widget.onVisibleSeriesChange!(ids);
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
                    builder: (context, constraints) => Semantics(
                      label: widget.label,
                      hint: widget.description,
                      child: Focus(
                        focusNode: _focus,
                        onKeyEvent: _key,
                        child: MouseRegion(
                          onHover: (event) {
                            final hover = _nearest(
                              event.localPosition,
                              constraints.biggest,
                              t,
                            );
                            if (hover != _hover) setState(() => _hover = hover);
                          },
                          onExit: (_) => setState(() => _hover = null),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (event) {
                              _focus.requestFocus();
                              setState(() => _hover = null);
                              _select(
                                _nearest(
                                  event.localPosition,
                                  constraints.biggest,
                                  t,
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: KFamilyPlot(
                                    area: widget.area,
                                    stacked: widget.stacked,
                                    orientation: widget.orientation,
                                    series: _visible,
                                    xAxis: widget.xAxis,
                                    yAxis: widget.yAxis,
                                    activeX: active?.$2.x,
                                  ),
                                ),
                                if (active != null)
                                  Positioned(
                                    top: t.componentChartInsetTop,
                                    right: t.componentChartInsetRight,
                                    child: IgnorePointer(
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              (constraints.maxWidth -
                                                      t.componentChartInsetLeft -
                                                      t.componentChartInsetRight)
                                                  .clamp(0, double.infinity),
                                        ),
                                        child: KChartTooltip(
                                          colorForSeries: (s) =>
                                              familyColor(t, s.colorIndex),
                                          series: _visible,
                                          x: active.$2.x,
                                          xAxis: widget.xAxis,
                                          yAxis: widget.yAxis,
                                        ),
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
          ),
          if (widget.showDataTable)
            KChartDataTable(
              series: widget.series,
              xAxis: widget.xAxis,
              yAxis: widget.yAxis,
              label: widget.dataTableLabel,
              xAxisLabel: widget.dataTableXAxisLabel,
            ),
        ],
      ),
    );
  }
}
