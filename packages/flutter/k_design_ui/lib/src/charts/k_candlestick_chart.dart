import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_surface.dart';
import '../primitives/k_text.dart';
import '../extended_components.dart' show KSpinner;
import 'k_candle_types.dart';
import 'k_candle_plot.dart';
import 'k_chart_types.dart';

/// Controlled OHLC chart. Range, selection and data remain consumer-owned.
class KCandlestickChart extends StatefulWidget {
  const KCandlestickChart({
    required this.data,
    required this.xAxis,
    required this.yAxis,
    required this.label,
    this.description,
    this.height,
    this.selectedId,
    this.onSelectionChange,
    this.visibleRange,
    this.ohlcLabels = const KChartOhlcLabels(),
    this.formatVolume,
    this.loading = false,
    this.error,
    this.loadingContent,
    this.errorContent,
    this.emptyContent,
    super.key,
  });
  final List<KChartCandle> data;
  final KChartAxis xAxis, yAxis;
  final String label;
  final String? description, selectedId, error;
  final double? height;
  final ValueChanged<String?>? onSelectionChange;
  final KChartVisibleRange? visibleRange;
  final KChartOhlcLabels ohlcLabels;
  final String Function(double)? formatVolume;
  final bool loading;
  final Widget? loadingContent, errorContent, emptyContent;
  @override
  State<KCandlestickChart> createState() => _KCandlestickChartState();
}

class _KCandlestickChartState extends State<KCandlestickChart> {
  final _focus = FocusNode();
  String? _hover;
  KChartAxis get _x {
    final range = widget.visibleRange;
    return range == null
        ? widget.xAxis
        : KChartAxis(
            min: range.min,
            max: range.max,
            ticks: widget.xAxis.ticks,
            format: widget.xAxis.format,
          );
  }

  List<KChartCandle> get _data =>
      widget.data
          .where((c) => c.isValid && c.x >= _x.min && c.x <= _x.max)
          .toList()
        ..sort((a, b) => a.x.compareTo(b.x));
  KChartCandle? _resolve(String? id) {
    for (final c in _data) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _select(String? id) {
    if (id != widget.selectedId) widget.onSelectionChange?.call(id);
  }

  String? _nearest(Offset p, Size size, KDesignTokens t) {
    final rect = Rect.fromLTRB(
      t.componentChartInsetLeft,
      t.componentChartInsetTop,
      size.width - t.componentChartInsetRight,
      size.height - t.componentChartInsetBottom,
    );
    if (!rect.contains(p) || rect.width <= 0) return null;
    final x = _x.min + (p.dx - rect.left) / rect.width * (_x.max - _x.min);
    KChartCandle? nearest;
    for (final c in _data) {
      if (nearest == null || (c.x - x).abs() < (nearest.x - x).abs()) {
        nearest = c;
      }
    }
    return nearest?.id;
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _hover = null);
      _select(null);
      return KeyEventResult.handled;
    }
    final delta = event.logicalKey == LogicalKeyboardKey.arrowRight
        ? 1
        : event.logicalKey == LogicalKeyboardKey.arrowLeft
        ? -1
        : 0;
    final home = event.logicalKey == LogicalKeyboardKey.home,
        end = event.logicalKey == LogicalKeyboardKey.end;
    final data = _data;
    if ((delta == 0 && !home && !end) || data.isEmpty) {
      return KeyEventResult.ignored;
    }
    final current = data.indexWhere((c) => c.id == widget.selectedId);
    final next = home
        ? 0
        : end
        ? data.length - 1
        : current < 0
        ? (delta > 0 ? 0 : data.length - 1)
        : (current + delta).clamp(0, data.length - 1);
    setState(() => _hover = null);
    _select(data[next].id);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final active = _resolve(_hover) ?? _resolve(widget.selectedId);
    final message = widget.loading
        ? widget.loadingContent ?? const KSpinner(label: 'Loading chart')
        : widget.error != null
        ? widget.errorContent ?? KText(widget.error!)
        : _data.isEmpty
        ? widget.emptyContent ?? const KText('No data to display')
        : null;
    return TapRegion(
      onTapOutside: (_) {
        _select(null);
        if (_hover != null) setState(() => _hover = null);
      },
      child: SizedBox(
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
                        final next = _nearest(
                          event.localPosition,
                          constraints.biggest,
                          t,
                        );
                        if (next != _hover) setState(() => _hover = next);
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
                              child: KCandlePlot(
                                data: _data,
                                xAxis: _x,
                                yAxis: widget.yAxis,
                                activeX: active?.x,
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
                                    child: _tooltip(active, t),
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
    );
  }

  Widget _tooltip(KChartCandle c, KDesignTokens t) {
    final labels = widget.ohlcLabels;
    final rows = [
      (labels.open, widget.yAxis.format(c.open)),
      (labels.high, widget.yAxis.format(c.high)),
      (labels.low, widget.yAxis.format(c.low)),
      (labels.close, widget.yAxis.format(c.close)),
      if (c.volume != null && c.volume!.isFinite)
        (
          labels.volume,
          widget.formatVolume?.call(c.volume!) ??
              (c.volume == c.volume!.truncateToDouble()
                  ? c.volume!.toStringAsFixed(0)
                  : c.volume.toString()),
        ),
    ];
    return Semantics(
      liveRegion: true,
      child: KSurface(
        elevation: KSurfaceElevation.overlay,
        radius: KSurfaceRadius.overlay,
        child: Padding(
          padding: EdgeInsets.all(t.spaceControlInsetInline),
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KText(
                  widget.xAxis.format(c.x),
                  variant: KTextVariant.bodySmall,
                  style: TextStyle(fontWeight: t.fontLabelWeight),
                ),
                for (final row in rows)
                  Padding(
                    padding: EdgeInsets.only(top: t.spaceControlGap),
                    child: Row(
                      children: [
                        Expanded(
                          child: KText(
                            row.$1,
                            variant: KTextVariant.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: t.spaceControlGap),
                        KText(
                          row.$2,
                          variant: KTextVariant.bodySmall,
                          style: TextStyle(fontWeight: t.fontLabelWeight),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
