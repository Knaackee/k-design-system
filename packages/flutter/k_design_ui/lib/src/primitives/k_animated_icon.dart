import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../generated/k_icons.g.dart';
import 'k_icon.dart';
import 'animated_icon_core/core.dart' as morph;

enum KAnimatedIconSpring { smooth, snappy, bouncy }

enum KAnimatedIconReducedMotion { user, always, never }

/// Morphs the same Lucide path geometry as the Web component. Decorative by
/// default. Provide [label] for an independently meaningful icon.
class KAnimatedIcon extends StatefulWidget {
  const KAnimatedIcon(
    KIconName name, {
    this.size = 16,
    this.strokeWidth = 2,
    this.color,
    this.label,
    this.spring = KAnimatedIconSpring.snappy,
    this.reducedMotion = KAnimatedIconReducedMotion.user,
    this.from,
    this.progress,
    this.onAnimationStart,
    this.onAnimationEnd,
    super.key,
  }) : _name = name,
       fromSvg = null,
       _svg = null;

  /// Accepts stroke-based Lucide SVG geometry, including icons not bundled in
  /// the library catalog. Unsupported SVG features throw rather than disappear.
  const KAnimatedIcon.svg(
    String svg, {
    this.size = 16,
    this.strokeWidth = 2,
    this.color,
    this.label,
    this.spring = KAnimatedIconSpring.snappy,
    this.reducedMotion = KAnimatedIconReducedMotion.user,
    this.fromSvg,
    this.progress,
    this.onAnimationStart,
    this.onAnimationEnd,
    super.key,
  }) : _svg = svg,
       from = null,
       _name = null;

  final KIconName? _name;
  final KIconName? from;
  final String? _svg;
  final String? fromSvg;
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? label;
  final KAnimatedIconSpring spring;
  final KAnimatedIconReducedMotion reducedMotion;

  /// Controlled interpolation in [0, 1]; requires a source icon.
  final double? progress;
  final VoidCallback? onAnimationStart, onAnimationEnd;
  String get _target => _svg ?? kIconSvg[_name]!;
  String? get _source => fromSvg ?? (from == null ? null : kIconSvg[from]);
  @override
  State<KAnimatedIcon> createState() => _KAnimatedIconState();
}

class _Geometry {
  _Geometry(String svg) {
    final nodes = <morph.IconNode>[];
    final tags = RegExp(r'<\s*([\w:-]+)\b([^>]*)>').allMatches(svg);
    const supported = {
      'path',
      'line',
      'circle',
      'ellipse',
      'rect',
      'polyline',
      'polygon',
    };
    for (final tag in tags) {
      final name = tag[1]!;
      final attrs = <String, Object?>{};
      for (final attr in RegExp(
        r'''([\w:-]+)\s*=\s*(["'])(.*?)\2''',
        dotAll: true,
      ).allMatches(tag[2]!)) {
        if (attr[1] == 'transform' || attr[1] == 'style') {
          throw ArgumentError(
            'KAnimatedIcon supports untransformed stroke geometry only.',
          );
        }
        attrs[attr[1]!] = attr[3]!;
      }
      // Lucide's tiny filled circles are already covered by its 2-unit stroke.
      // Morphicons lowers these to the same circle centerline on Web.
      final fill = attrs['fill'];
      final lucideDot =
          name == 'circle' &&
          fill == 'currentColor' &&
          (double.tryParse('${attrs['r']}') ?? double.infinity) <= 1;
      if (fill != null && fill != 'none' && !lucideDot) {
        throw ArgumentError(
          'KAnimatedIcon supports stroke geometry and Lucide dots only.',
        );
      }
      if (name == 'svg') {
        final viewBox = attrs['viewBox'] as String?;
        if (viewBox != null &&
            viewBox.trim().split(RegExp(r'[ ,]+')).join(' ') != '0 0 24 24') {
          throw ArgumentError(
            'KAnimatedIcon SVG must use viewBox="0 0 24 24".',
          );
        }
        continue;
      }
      if (!supported.contains(name)) {
        throw ArgumentError('Unsupported animated SVG element: $name');
      }
      nodes.add(morph.IconNode(name, attrs));
    }
    if (nodes.isEmpty) {
      throw ArgumentError('KAnimatedIcon SVG has no supported geometry.');
    }
    samples = morph.resampleIcon(nodes);
    canonical = Path();
    for (final segment in morph.iconToCubics(nodes)) {
      final p = segment.pts;
      canonical.moveTo(_round(p[0], 10000), _round(p[1], 10000));
      for (var i = 2; i < p.length; i += 6) {
        canonical.cubicTo(
          _round(p[i], 10000),
          _round(p[i + 1], 10000),
          _round(p[i + 2], 10000),
          _round(p[i + 3], 10000),
          _round(p[i + 4], 10000),
          _round(p[i + 5], 10000),
        );
      }
      if (segment.closed) canonical.close();
    }
  }
  late final List<morph.Sampled> samples;
  late final Path canonical;
}

// Match JavaScript Math.round, including negative half values.
double _round(double v, double scale) =>
    (v * scale + .5).floorToDouble() / scale;
final _geometryCache = <String, _Geometry>{};
_Geometry _geometry(String svg) {
  final existing = _geometryCache[svg];
  if (existing != null) return existing;
  if (_geometryCache.length >= 128) {
    _geometryCache.remove(_geometryCache.keys.first);
  }
  return _geometryCache[svg] = _Geometry(svg);
}

class _KAnimatedIconState extends State<KAnimatedIcon>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _spring = morph.MorphSpring();
  late String _target;
  late Path _path;
  morph.MorphPlan? _plan;
  List<Float64List>? _outputs;
  Duration? _last;
  String? _controlledSource;
  bool _motionOff = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _target = widget._target;
    _path = _geometry(_target).canonical;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  @override
  void didUpdateWidget(KAnimatedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configure();
  }

  void _configure() {
    _motionOff =
        widget.reducedMotion == KAnimatedIconReducedMotion.always ||
        (widget.reducedMotion == KAnimatedIconReducedMotion.user &&
            MediaQuery.disableAnimationsOf(context));
    final progress = widget.progress;
    if (progress != null) {
      if (!progress.isFinite || widget._source == null) {
        throw ArgumentError(
          'Controlled progress requires a source and a finite value in [0, 1].',
        );
      }
      _ticker.stop();
      _spring.v = 0;
      if (_controlledSource != widget._source ||
          _target != widget._target ||
          _plan == null) {
        _controlledSource = widget._source;
        _target = widget._target;
        _plan = morph.buildPlan(
          _geometry(widget._source!).samples,
          _geometry(_target).samples,
        );
        _outputs = morph.allocOutputs(_plan!);
      }
      final t = progress.clamp(0.0, 1.0);
      _render(t);
      if (t == 0 || t == 1) {
        _path = _geometry(t == 0 ? widget._source! : _target).canonical;
      }
      return;
    }
    _controlledSource = null;
    if (_motionOff) {
      final changed = widget._target != _target;
      if (changed) _notify(widget.onAnimationStart);
      _settle(notify: changed || _ticker.isActive);
      return;
    }
    if (widget._target == _target && (_plan == null || _ticker.isActive)) {
      return;
    }
    final source = _plan == null
        ? _geometry(_target).samples
        : [
            for (var i = 0; i < _outputs!.length; i++)
              morph.Sampled(
                Float64List.fromList(_outputs![i]),
                _plan!.items[i].closed,
              ),
          ];
    _target = widget._target;
    _plan = morph.buildPlan(source, _geometry(_target).samples);
    _outputs = morph.allocOutputs(_plan!);
    final preset = morph.springPresets[widget.spring.name]!;
    _spring.config(preset.k, preset.c);
    _spring.start();
    _render(0);
    if (!_ticker.isActive) {
      _last = null;
      _ticker.start();
    }
    _notify(widget.onAnimationStart);
  }

  void _notify(VoidCallback? callback) {
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
  }

  void _tick(Duration elapsed) {
    final dt = _last == null
        ? 0.0
        : ((elapsed - _last!).inMicroseconds / 1000000).clamp(0.0, .1);
    _last = elapsed;
    final done = _spring.step(dt);
    setState(() {
      _render(_spring.x);
      if (done) _settle();
    });
  }

  void _render(double t) {
    morph.interpPolar(_plan!, t, _outputs!);
    final path = Path();
    for (var k = 0; k < _outputs!.length; k++) {
      final p = _outputs![k];
      path.moveTo(_round(p[0], 100), _round(p[1], 100));
      for (var i = 2; i < p.length; i += 2) {
        path.lineTo(_round(p[i], 100), _round(p[i + 1], 100));
      }
      if (_plan!.items[k].closed) path.close();
    }
    _path = path;
  }

  void _settle({bool notify = true}) {
    _ticker.stop();
    _target = widget._target;
    _path = _geometry(_target).canonical;
    _plan = null;
    _outputs = null;
    _spring.x = 1;
    _spring.v = 0;
    if (notify) _notify(widget.onAnimationEnd);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = KIconSizeScope.maybeOf(context) ?? widget.size;
    if (!size.isFinite || size <= 0) {
      throw ArgumentError.value(size, 'size');
    }
    if (!widget.strokeWidth.isFinite || widget.strokeWidth <= 0) {
      throw ArgumentError.value(widget.strokeWidth, 'strokeWidth');
    }
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    return Semantics(
      label: widget.label,
      image: widget.label?.isNotEmpty ?? false,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: _IconPainter(
            _path,
            widget.color ?? tokens.colorTextPrimary,
            widget.strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  const _IconPainter(this.path, this.color, this.strokeWidth);
  final double strokeWidth;
  final Path path;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_IconPainter oldDelegate) =>
      oldDelegate.path != path ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
