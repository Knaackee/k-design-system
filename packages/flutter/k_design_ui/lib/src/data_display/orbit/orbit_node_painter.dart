import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'orbit_models.dart';

class KOrbitNodePainter {
  const KOrbitNodePainter({
    required this.tokens,
    required this.style,
    required this.reducedMotion,
    required this.shader,
  });

  final KDesignTokens tokens;
  final KOrbitVisualStyle style;
  final bool reducedMotion;
  final ui.FragmentShader? shader;

  void draw(
    Canvas canvas,
    Offset center,
    double radius,
    KOrbitNode node,
    double opacity,
    double time,
  ) {
    if (node.appearance == KOrbitNodeAppearance.sphere) {
      if (node.isCenter) _glow(canvas, center, radius, opacity);
      _sphere(canvas, center, radius, node, opacity, time);
    } else {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = (node.backgroundColor ?? _surface(node.tone)).withValues(
            alpha: (node.backgroundColor ?? _surface(node.tone)).a * opacity,
          ),
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tokens.componentOrbitConnectionLineWidth
        ..color = (node.borderColor ?? _border(node)).withValues(
          alpha: opacity,
        ),
    );
    _progress(canvas, center, radius, node, opacity);
    _pulse(canvas, center, radius, node, opacity, time);
  }

  Color tone(KOrbitTone tone) => switch (tone) {
    KOrbitTone.neutral => tokens.componentOrbitConnectionColor,
    KOrbitTone.brand => tokens.colorBrandPrimaryAccent,
    KOrbitTone.info => tokens.colorStatusInfoAccent,
    KOrbitTone.success => tokens.colorStatusSuccessAccent,
    KOrbitTone.warning => tokens.colorStatusWarningAccent,
    KOrbitTone.error => tokens.colorStatusErrorAccent,
  };

  KOrbitTone _statusTone(KOrbitNode node) =>
      node.status == KOrbitStatus.question
      ? KOrbitTone.warning
      : node.status == KOrbitStatus.error
      ? KOrbitTone.error
      : node.status == KOrbitStatus.completed
      ? KOrbitTone.success
      : node.status == KOrbitStatus.active && node.tone == KOrbitTone.neutral
      ? KOrbitTone.info
      : node.tone;

  Color _border(KOrbitNode node) {
    final value = _statusTone(node);
    return value == KOrbitTone.neutral
        ? tokens.colorBorderDefault
        : tone(value);
  }

  void _sphere(
    Canvas canvas,
    Offset center,
    double radius,
    KOrbitNode node,
    double opacity,
    double time,
  ) {
    final fragment = shader;
    if (fragment == null) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.38, -.42),
            colors: [
              tokens.componentOrbitCenterHighlight,
              tone(node.tone),
              tokens.componentOrbitCenterShadow,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
      return;
    }
    var i = 0;
    fragment
      ..setFloat(i++, radius * 2)
      ..setFloat(i++, radius * 2)
      ..setFloat(i++, time);
    i = _setColor(
      fragment,
      i,
      tokens.componentOrbitCenterShadow.withValues(alpha: opacity),
    );
    i = _setColor(fragment, i, tone(node.tone).withValues(alpha: opacity));
    i = _setColor(
      fragment,
      i,
      style.centerInnerColor ?? tokens.componentOrbitCenterHighlight,
    );
    _setColor(
      fragment,
      i,
      style.centerOuterColor ?? tokens.componentOrbitCenterRim,
    );
    canvas.save();
    canvas.translate(center.dx - radius, center.dy - radius);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, radius * 2, radius * 2),
      Paint()..shader = fragment,
    );
    canvas.restore();
  }

  void _progress(
    Canvas canvas,
    Offset center,
    double radius,
    KOrbitNode node,
    double opacity,
  ) {
    if (node.progress == null || node.progress! <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * node.progress! / 100,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            (style.progressLineWidth ?? tokens.borderWidthStrong) *
            radius *
            2 /
            tokens.componentOrbitNodeSize
        ..strokeCap = StrokeCap.round
        ..color = (node.borderColor ?? _border(node)).withValues(
          alpha: opacity,
        ),
    );
  }

  void _pulse(
    Canvas canvas,
    Offset center,
    double radius,
    KOrbitNode node,
    double opacity,
    double time,
  ) {
    if (!node.shouldPulse || reducedMotion) return;
    final seconds =
        (node.pulsePeriod ?? tokens.componentOrbitMotionPulseDuration)
            .inMicroseconds /
        Duration.microsecondsPerSecond;
    final phase = (time % seconds) / seconds;
    canvas.drawCircle(
      center,
      radius + 3 + phase * 10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tokens.componentOrbitConnectionLineWidth
        ..color = _border(
          node,
        ).withValues(alpha: opacity * (node.pulseIntensity ?? 1) * (1 - phase)),
    );
  }

  void _glow(Canvas canvas, Offset center, double radius, double opacity) =>
      canvas.drawCircle(
        center,
        radius * 1.08,
        Paint()
          ..color = tokens.componentOrbitGlowColor.withValues(
            alpha: tokens.componentOrbitGlowOpacity * opacity,
          )
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            tokens.componentOrbitGlowBlur,
          ),
      );

  Color _surface(KOrbitTone value) => switch (value) {
    KOrbitTone.neutral => tokens.colorSurfaceRaised,
    KOrbitTone.brand || KOrbitTone.info => tokens.colorStatusInfoBackground,
    KOrbitTone.success => tokens.colorStatusSuccessBackground,
    KOrbitTone.warning => tokens.colorStatusWarningBackground,
    KOrbitTone.error => tokens.colorStatusErrorBackground,
  };

  int _setColor(ui.FragmentShader shader, int index, Color color) {
    shader
      ..setFloat(index++, color.r)
      ..setFloat(index++, color.g)
      ..setFloat(index++, color.b)
      ..setFloat(index++, color.a);
    return index;
  }
}
