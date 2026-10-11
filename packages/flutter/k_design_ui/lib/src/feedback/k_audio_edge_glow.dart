import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Consumer-owned capture lifecycle for [KAudioEdgeGlow].
enum KAudioEdgeGlowState { inactive, capturing, processing }

/// A decorative, audio-reactive edge shimmer. Place inside a bounded Stack.
/// The consumer owns its character color and microphone/capture state.
///
/// Broad, blurred color fields travel around the viewport even in silence.
/// Microphone energy only increases their reach and opacity, keeping the
/// recording state obvious without turning the effect into a waveform.
final class KAudioEdgeGlow extends StatefulWidget {
  const KAudioEdgeGlow({
    required this.color,
    this.state = KAudioEdgeGlowState.inactive,
    this.audioLevel = 0,
    this.voiceDetected = false,
    this.reducedMotion = false,
    super.key,
  });

  final KAudioEdgeGlowState state;
  final Color color;

  /// Normalized microphone energy, clamped to 0–1; processing ignores energy.
  final double audioLevel;
  final bool voiceDetected;

  /// Also respects MediaQuery.disableAnimations and TickerMode.
  final bool reducedMotion;
  bool get active => state != KAudioEdgeGlowState.inactive;

  @override
  State<KAudioEdgeGlow> createState() => _KAudioEdgeGlowState();
}

final class _KAudioEdgeGlowState extends State<KAudioEdgeGlow>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 13),
  )..addListener(_tick);

  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  double _smoothedLevel = 0;
  double _phase = 0;
  Duration _previousElapsed = Duration.zero;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lifecycle =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    _updateMotion();
  }

  @override
  void didUpdateWidget(KAudioEdgeGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reduceMotion =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    _updateMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    _updateMotion();
  }

  void _updateMotion() {
    final shouldAnimate =
        widget.active &&
        !_reduceMotion &&
        TickerMode.valuesOf(context).enabled &&
        _lifecycle == AppLifecycleState.resumed;
    if (shouldAnimate) {
      if (!_motion.isAnimating) unawaited(_motion.repeat());
      return;
    }
    _motion.stop();
    _previousElapsed = Duration.zero;
    if (!widget.active) _smoothedLevel = 0;
    if (_reduceMotion && widget.active) _smoothedLevel = _targetLevel();
  }

  void _tick() {
    final elapsed = _motion.lastElapsedDuration ?? Duration.zero;
    var delta = elapsed - _previousElapsed;
    if (delta < Duration.zero) delta += _motion.duration!;
    _previousElapsed = elapsed;
    _phase +=
        delta.inMicroseconds /
        const Duration(seconds: 13).inMicroseconds *
        math.pi *
        2;

    final target = _targetLevel();
    final timeConstant = target > _smoothedLevel ? 70.0 : 260.0;
    final alpha = 1 - math.exp(-delta.inMilliseconds / timeConstant);
    _smoothedLevel += (target - _smoothedLevel) * alpha;
  }

  double _targetLevel() {
    if (widget.state != KAudioEdgeGlowState.capturing) return 0;
    final input = widget.audioLevel.isFinite ? widget.audioLevel : 0.0;
    final normalized = ((input - .008) / .42).clamp(0.0, 1.0);
    return math.max(math.sqrt(normalized), widget.voiceDetected ? .08 : 0.0);
  }

  Color _tone(Color color, double mix) {
    double channel(double value) =>
        mix >= 0 ? value + (1 - value) * mix : value * (1 + mix);
    return color.withValues(
      red: channel(color.r),
      green: channel(color.g),
      blue: channel(color.b),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('k-audio-edge-glow'),
            painter: _AudioEdgeGlowPainter(
              motion: _motion,
              phase: () => _phase,
              level: () => _smoothedLevel,
              colors: [
                _tone(widget.color, .22),
                widget.color,
                _tone(widget.color, -.14),
              ],
              reduceMotion: _reduceMotion,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion
      ..removeListener(_tick)
      ..dispose();
    super.dispose();
  }
}

final class _AudioEdgeGlowPainter extends CustomPainter {
  _AudioEdgeGlowPainter({
    required this.motion,
    required this.phase,
    required this.level,
    required this.colors,
    required this.reduceMotion,
  }) : super(repaint: motion);

  final Animation<double> motion;
  final double Function() phase;
  final double Function() level;
  final List<Color> colors;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || colors.isEmpty) return;
    final energy = level();
    final angle = reduceMotion ? 0.0 : phase();
    final shortest = math.min(size.width, size.height);
    final radius = Radius.circular(math.min(28, shortest * .07));

    // A quiet full-perimeter body makes recording readable without speech.
    _paintLayer(
      canvas,
      size,
      radius,
      stroke: 10 + energy * 10,
      softness: 13 + energy * 10,
      strength: .24 + energy * .16,
      rotation: angle * .07,
      palette: colors,
    );

    // Differently paced lobes avoid a mechanical spinner. Their overlap
    // creates the soft aurora pockets visible in Gemini-like voice surfaces.
    _paintLayer(
      canvas,
      size,
      radius,
      stroke: 20 + energy * 34,
      softness: 24 + energy * 28,
      strength: .40 + energy * .38,
      rotation: angle * .16,
      palette: _transparentLobes(colors, offset: 0),
    );
    _paintLayer(
      canvas,
      size,
      radius,
      stroke: 14 + energy * 25,
      softness: 18 + energy * 22,
      strength: .34 + energy * .34,
      rotation: -angle * .11 + 1.7,
      palette: _transparentLobes(colors.reversed.toList(), offset: 1),
    );
    _paintLayer(
      canvas,
      size,
      radius,
      stroke: 9 + energy * 17,
      softness: 11 + energy * 15,
      strength: .42 + energy * .32,
      rotation: angle * .23 + 3.1,
      palette: _transparentLobes(colors, offset: 2),
    );
  }

  void _paintLayer(
    Canvas canvas,
    Size size,
    Radius radius, {
    required double stroke,
    required double softness,
    required double strength,
    required double rotation,
    required List<Color> palette,
  }) {
    final inset = stroke / 2;
    final bounds = (Offset.zero & size).deflate(inset);
    if (bounds.isEmpty) return;
    final shader = SweepGradient(
      colors: palette
          .map((color) => color.withValues(alpha: color.a * strength))
          .toList(growable: false),
      transform: GradientRotation(rotation),
    ).createShader(bounds);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = shader
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, softness);
    canvas.drawRRect(RRect.fromRectAndRadius(bounds, radius), paint);
  }

  List<Color> _transparentLobes(List<Color> source, {required int offset}) {
    final values = <Color>[];
    for (var index = 0; index < source.length; index++) {
      final color = source[(index + offset) % source.length];
      values
        ..add(color.withValues(alpha: 0))
        ..add(color)
        ..add(color.withValues(alpha: 0));
    }
    return values;
  }

  @override
  bool shouldRepaint(_AudioEdgeGlowPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.reduceMotion != reduceMotion;
}
