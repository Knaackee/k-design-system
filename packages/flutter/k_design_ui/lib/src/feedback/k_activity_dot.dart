import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

enum KActivityDotState { idle, working, question, error }

enum KActivityDotAnimation { auto, none, spin, pulse }

/// Compact state marker with consumer-controlled color and motion.
class KActivityDot extends StatefulWidget {
  const KActivityDot({
    super.key,
    this.state = KActivityDotState.idle,
    this.label,
    this.size,
    this.coreSize,
    this.ringWidth,
    this.dotColor,
    this.ringColor,
    this.ringTrackColor,
    this.animation = KActivityDotAnimation.auto,
    this.animationDuration,
    this.animationCurve,
    this.animationRepeatCount,
    this.reducedMotion = false,
  }) : assert(animationRepeatCount == null || animationRepeatCount > 0);

  final KActivityDotState state;
  final String? label;
  final double? size;
  final double? coreSize;
  final double? ringWidth;
  final Color? dotColor;
  final Color? ringColor;
  final Color? ringTrackColor;
  final KActivityDotAnimation animation;
  final Duration? animationDuration;
  final Curve? animationCurve;

  /// Number of animation cycles. `null` repeats indefinitely.
  final int? animationRepeatCount;

  /// Stops motion independently of the operating-system preference.
  final bool reducedMotion;

  @override
  State<KActivityDot> createState() => _KActivityDotState();
}

class _KActivityDotState extends State<KActivityDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  KActivityDotAnimation _resolvedAnimation = KActivityDotAnimation.none;
  int? _configuredRepeatCount;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configureAnimation();
  }

  @override
  void didUpdateWidget(covariant KActivityDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configureAnimation();
  }

  void _configureAnimation() {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final resolved = widget.reducedMotion || disableAnimations
        ? KActivityDotAnimation.none
        : switch (widget.animation) {
            KActivityDotAnimation.auto => switch (widget.state) {
              KActivityDotState.working => KActivityDotAnimation.spin,
              KActivityDotState.question => KActivityDotAnimation.pulse,
              _ => KActivityDotAnimation.none,
            },
            final animation => animation,
          };
    final duration =
        widget.animationDuration ??
        (resolved == KActivityDotAnimation.pulse
            ? tokens.motionProgress
            : tokens.motionSpinner);
    final changed =
        resolved != _resolvedAnimation ||
        _controller.duration != duration ||
        _configuredRepeatCount != widget.animationRepeatCount;
    _resolvedAnimation = resolved;
    _configuredRepeatCount = widget.animationRepeatCount;
    _controller.duration = duration;

    if (resolved == KActivityDotAnimation.none) {
      _controller.stop();
      _controller.value = 0;
    } else if (changed) {
      _controller.repeat(count: widget.animationRepeatCount);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final size = widget.size ?? tokens.sizeIndicatorSmall;
    final coreSize =
        widget.coreSize ??
        tokens.sizeIndicatorTiny - tokens.borderWidthStrong * 2;
    final ringWidth = widget.ringWidth ?? tokens.borderWidthStrong;
    final stateColor = switch (widget.state) {
      KActivityDotState.idle => tokens.colorBorderStrong,
      KActivityDotState.working => tokens.colorStatusInfoAccent,
      KActivityDotState.question => tokens.colorStatusWarningAccent,
      KActivityDotState.error => tokens.colorStatusErrorAccent,
    };
    final curve =
        widget.animationCurve ??
        (_resolvedAnimation == KActivityDotAnimation.pulse
            ? Curves.easeInOut
            : Curves.linear);

    final dot = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final rawProgress = _controller.value;
        final progress = curve.transform(rawProgress);
        final pulseProgress = rawProgress <= .5
            ? curve.transform(rawProgress * 2)
            : curve.transform((1 - rawProgress) * 2);
        final opacity = _resolvedAnimation == KActivityDotAnimation.pulse
            ? 1 - .65 * pulseProgress
            : 1.0;
        return CustomPaint(
          size: Size.square(size),
          painter: _ActivityDotPainter(
            state: widget.state,
            rotation: _resolvedAnimation == KActivityDotAnimation.spin
                ? progress * math.pi * 2
                : 0,
            ringOpacity: opacity,
            coreSize: coreSize,
            ringWidth: ringWidth,
            dotColor: widget.dotColor ?? stateColor,
            ringColor: widget.ringColor ?? stateColor,
            ringTrackColor: widget.ringTrackColor ?? tokens.colorBorderDefault,
          ),
        );
      },
    );

    if (widget.label == null) return ExcludeSemantics(child: dot);
    return Semantics(
      label: widget.label,
      image: true,
      child: ExcludeSemantics(child: dot),
    );
  }
}

class _ActivityDotPainter extends CustomPainter {
  const _ActivityDotPainter({
    required this.state,
    required this.rotation,
    required this.ringOpacity,
    required this.coreSize,
    required this.ringWidth,
    required this.dotColor,
    required this.ringColor,
    required this.ringTrackColor,
  });

  final KActivityDotState state;
  final double rotation;
  final double ringOpacity;
  final double coreSize;
  final double ringWidth;
  final Color dotColor;
  final Color ringColor;
  final Color ringTrackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (state != KActivityDotState.idle && ringWidth > 0) {
      final ringRect = Offset.zero & size;
      final arcRect = ringRect.deflate(ringWidth / 2);
      final trackPaint = Paint()
        ..color = ringTrackColor.withValues(
          alpha: ringTrackColor.a * ringOpacity,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth;
      final ringPaint = Paint()
        ..color = ringColor.withValues(alpha: ringColor.a * ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth;

      if (state == KActivityDotState.error) {
        for (var index = 0; index < 12; index++) {
          canvas.drawArc(
            arcRect,
            -math.pi / 2 + rotation + index * math.pi / 6,
            math.pi / 12,
            false,
            ringPaint,
          );
        }
      } else {
        canvas.drawOval(arcRect, trackPaint);
        canvas.drawArc(
          arcRect,
          (state == KActivityDotState.working ? math.pi / 4 : -math.pi / 2) +
              rotation,
          state == KActivityDotState.working ? math.pi * 1.5 : math.pi * 2,
          false,
          ringPaint,
        );
      }
    }

    canvas.drawCircle(center, coreSize / 2, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(covariant _ActivityDotPainter oldDelegate) =>
      state != oldDelegate.state ||
      rotation != oldDelegate.rotation ||
      ringOpacity != oldDelegate.ringOpacity ||
      coreSize != oldDelegate.coreSize ||
      ringWidth != oldDelegate.ringWidth ||
      dotColor != oldDelegate.dotColor ||
      ringColor != oldDelegate.ringColor ||
      ringTrackColor != oldDelegate.ringTrackColor;
}
