import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

/// A decorative, non-blocking reveal. Remount to replay an active celebration.
class KCelebration extends StatefulWidget {
  const KCelebration({
    super.key,
    required this.child,
    this.active = false,
    this.durationMs = 1100,
    this.particleCount = 24,
    this.colors,
  });
  final Widget child;
  final bool active;
  final int durationMs, particleCount;
  final List<Color>? colors;
  @override
  State<KCelebration> createState() => _KCelebrationState();
}

class _KCelebrationState extends State<KCelebration>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);
  bool _started = false;
  bool get _reduced => MediaQuery.disableAnimationsOf(context);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(KCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active) _started = false;
    _sync();
  }

  void _sync() {
    if (_reduced || !widget.active) {
      _controller.stop();
      if (_reduced) _controller.value = 1;
      return;
    }
    if (!_started) {
      _started = true;
      _controller.duration = Duration(
        milliseconds: math.max(480, widget.durationMs + 75),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || _reduced) return widget.child;
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final elapsed =
            _controller.value * _controller.duration!.inMilliseconds;
        final reveal = const Cubic(
          .16,
          1,
          .3,
          1,
        ).transform((elapsed / 480).clamp(0.0, 1.0));
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: _Particles(
                      elapsed,
                      widget.durationMs,
                      widget.particleCount.clamp(0, 60),
                      widget.colors?.isNotEmpty == true
                          ? widget.colors!
                          : [
                              t.colorActionPrimaryBackground,
                              t.colorBorderFocus,
                              t.colorTextMuted,
                            ],
                    ),
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: reveal,
              child: Transform.translate(
                offset: Offset(0, 8 * (1 - reveal)),
                child: Transform.scale(scale: .92 + .08 * reveal, child: child),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Particles extends CustomPainter {
  _Particles(this.elapsed, this.duration, this.count, this.colors);
  final double elapsed;
  final int duration, count;
  final List<Color> colors;
  static const curve = Cubic(.16, .8, .3, 1);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect((Offset.zero & size).inflate(80));
    for (var i = 0; i < count; i++) {
      final p = ((elapsed - (i % 4) * 25) / math.max(1, duration)).clamp(
        0.0,
        1.0,
      );
      if (p == 0 || p == 1) continue;
      final opacity = p < .15
          ? .9 * curve.transform(p / .15)
          : p < .7
          ? .9 - .2 * curve.transform((p - .15) / .55)
          : .7 * (1 - curve.transform((p - .7) / .3));
      final travel = curve.transform(p);
      final angle = i * 2.39996;
      final radius = 76 + (i % 5) * 20;
      final height = (i + 1) % 3 == 0 ? 6.0 : 10.0;
      canvas.save();
      canvas.translate(
        size.width / 2 + 3 + math.cos(angle) * radius * travel,
        .45 * (size.height + 160) -
            80 +
            height / 2 +
            (math.sin(angle) * radius - 28) * travel,
      );
      canvas.rotate((i.isOdd ? 210 : -180) * math.pi / 180 * travel);
      canvas.scale(.4 + .3 * travel);
      final paint = Paint()
        ..color = (colors[i % colors.length]).withValues(alpha: opacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-3, -height / 2, 6, height),
          Radius.circular((i + 1) % 3 == 0 ? 3 : 2),
        ),
        paint,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Particles oldDelegate) =>
      elapsed != oldDelegate.elapsed ||
      duration != oldDelegate.duration ||
      count != oldDelegate.count ||
      colors != oldDelegate.colors;
}
