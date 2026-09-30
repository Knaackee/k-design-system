import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'orbit_models.dart';
import 'orbit_projection.dart';

class KOrbitActiveSignal {
  const KOrbitActiveSignal({
    required this.signal,
    required this.startedAt,
    required this.duration,
  });

  final KOrbitSignal signal;
  final double startedAt;
  final Duration duration;
}

class KOrbitPainter extends CustomPainter {
  KOrbitPainter({
    required this.levels,
    required this.nodes,
    required this.connections,
    required this.view,
    required this.orbitTimeSeconds,
    required this.signalTimeSeconds,
    required this.signals,
    required this.tokens,
    required this.style,
    required this.reducedMotion,
    required this.centerShader,
    this.extentOverride,
    super.repaint,
  });

  final List<KOrbitLevel> levels;
  final List<KOrbitNode> nodes;
  final List<KOrbitConnection> connections;
  final KOrbitViewState Function() view;
  final double Function() orbitTimeSeconds;
  final double Function() signalTimeSeconds;
  final List<KOrbitActiveSignal> Function() signals;
  final KDesignTokens tokens;
  final KOrbitVisualStyle style;
  final bool reducedMotion;
  final ui.FragmentShader? centerShader;
  final double? extentOverride;

  @override
  void paint(Canvas canvas, Size size) {
    final time = orbitTimeSeconds();
    final currentView = view();
    final scene = projectKOrbitScene(
      size: size,
      levels: levels,
      nodes: nodes,
      connections: connections,
      view: currentView,
      timeSeconds: time,
      radiusRatio: tokens.componentOrbitCenterRadiusRatio,
      extentOverride: extentOverride,
    );
    _drawTracks(canvas, scene, currentView, time, back: true);
    _drawConnections(canvas, scene);
    _drawCenter(canvas, scene);
    _drawTracks(canvas, scene, currentView, time, back: false);
    _drawSignals(canvas, scene, signalTimeSeconds());
  }

  void _drawTracks(
    Canvas canvas,
    KOrbitSceneProjection scene,
    KOrbitViewState currentView,
    double time, {
    required bool back,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = tokens.componentOrbitTrackLineWidth
      ..color = (style.trackColor ?? tokens.componentOrbitTrackColor)
          .withValues(
            alpha: tokens.componentOrbitTrackOpacity * (back ? 0.45 : 1),
          );
    for (final ring in scene.rings) {
      final path = Path();
      var drawing = false;
      for (var i = 0; i <= 128; i++) {
        final angle = i / 128 * math.pi * 2;
        final point = kOrbitRingPointFor(
          ring: ring,
          angle: angle,
          view: currentView,
        );
        final projected = kOrbitProjectPoint(
          point: point,
          center: scene.center,
          scale: scene.scale,
          depthScale: scene.extent,
        );
        final belongs = back ? projected.depth < 0 : projected.depth >= 0;
        if (!belongs) {
          drawing = false;
        } else if (!drawing) {
          path.moveTo(projected.offset.dx, projected.offset.dy);
          drawing = true;
        } else {
          path.lineTo(projected.offset.dx, projected.offset.dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawConnections(Canvas canvas, KOrbitSceneProjection scene) {
    final activeConnectionIds = signals()
        .map((active) => active.signal.connectionId)
        .toSet();
    for (final item in scene.connections) {
      if (!item.connection.visible &&
          !activeConnectionIds.contains(item.connection.id)) {
        continue;
      }
      final path = Path()
        ..moveTo(item.start.dx, item.start.dy)
        ..quadraticBezierTo(
          item.control.dx,
          item.control.dy,
          item.end.dx,
          item.end.dy,
        );
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth =
            style.lineWidth ?? tokens.componentOrbitConnectionLineWidth
        ..color = _tone(
          item.connection.tone,
        ).withValues(alpha: tokens.componentOrbitConnectionOpacity);
      _drawStyledPath(canvas, path, paint, item.connection.lineStyle);
    }
  }

  void _drawStyledPath(
    Canvas canvas,
    Path path,
    Paint paint,
    KOrbitLineStyle lineStyle,
  ) {
    if (lineStyle == KOrbitLineStyle.solid) {
      canvas.drawPath(path, paint);
      return;
    }
    final dash = lineStyle == KOrbitLineStyle.dotted
        ? paint.strokeWidth
        : style.dashLength ?? tokens.componentOrbitConnectionDashLength;
    final gap = style.gapLength ?? tokens.componentOrbitConnectionGapLength;
    for (final metric in path.computeMetrics()) {
      for (
        var distance = 0.0;
        distance < metric.length;
        distance += dash + gap
      ) {
        if (lineStyle == KOrbitLineStyle.dotted) {
          final tangent = metric.getTangentForOffset(distance);
          if (tangent != null) {
            canvas.drawCircle(
              tangent.position,
              paint.strokeWidth / 2,
              paint..style = PaintingStyle.fill,
            );
            paint.style = PaintingStyle.stroke;
          }
        } else {
          canvas.drawPath(
            metric.extractPath(
              distance,
              math.min(metric.length, distance + dash),
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawCenter(Canvas canvas, KOrbitSceneProjection scene) {
    final center = scene.center;
    final radius = scene.centerRadius;
    final glow = Paint()
      ..color = tokens.componentOrbitGlowColor.withValues(
        alpha: tokens.componentOrbitGlowOpacity,
      )
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        tokens.componentOrbitGlowBlur,
      );
    canvas.drawCircle(center, radius * 1.08, glow);
    final shader = centerShader;
    if (shader != null) {
      var index = 0;
      shader
        ..setFloat(index++, radius * 2)
        ..setFloat(index++, radius * 2)
        ..setFloat(index++, orbitTimeSeconds());
      index = _setShaderColor(shader, index, tokens.componentOrbitCenterShadow);
      index = _setShaderColor(shader, index, tokens.componentOrbitCenterBase);
      index = _setShaderColor(
        shader,
        index,
        style.centerInnerColor ?? tokens.componentOrbitCenterHighlight,
      );
      _setShaderColor(
        shader,
        index,
        style.centerOuterColor ?? tokens.componentOrbitCenterRim,
      );
      canvas.save();
      canvas.translate(center.dx - radius, center.dy - radius);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, radius * 2, radius * 2),
        Paint()..shader = shader,
      );
      canvas.restore();
    } else {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.38, -0.42),
            radius: 0.95,
            colors: [
              style.centerInnerColor ?? tokens.componentOrbitCenterHighlight,
              tokens.componentOrbitCenterBase,
              style.centerOuterColor ?? tokens.componentOrbitCenterRim,
            ],
            stops: const [0, 0.58, 1],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tokens.componentOrbitTrackLineWidth
        ..color = tokens.componentOrbitCenterRim,
    );
  }

  void _drawSignals(Canvas canvas, KOrbitSceneProjection scene, double time) {
    final byId = {
      for (final connection in scene.connections)
        connection.connection.id: connection,
    };
    for (final active in signals()) {
      final connection = byId[active.signal.connectionId];
      if (connection == null) continue;
      final duration =
          active.duration.inMicroseconds / Duration.microsecondsPerSecond;
      final progress = ((time - active.startedAt) / duration).clamp(0.0, 1.0);
      final signalStyle =
          active.signal.style ?? connection.connection.signalStyle;
      final color = _tone(connection.connection.tone);
      final directions = switch (connection.connection.direction) {
        KOrbitDirection.forward => const [false],
        KOrbitDirection.reverse => const [true],
        KOrbitDirection.bidirectional => const [false, true],
      };
      for (final reverse in directions) {
        _drawSignal(
          canvas,
          connection,
          active.signal,
          progress,
          signalStyle,
          color,
          reverse,
        );
      }
    }
  }

  void _drawSignal(
    Canvas canvas,
    KOrbitProjectedConnection connection,
    KOrbitSignal signal,
    double progress,
    KOrbitSignalStyle signalStyle,
    Color color,
    bool reverse,
  ) {
    final start = reverse ? connection.end : connection.start;
    final end = reverse ? connection.start : connection.end;
    Offset pointAt(double value) =>
        connection.pointAt(reverse ? 1 - value : value);
    if (reducedMotion) {
      if (signal.destinationPing) _ping(canvas, end, color, 0);
      return;
    }
    if (signalStyle == KOrbitSignalStyle.endpointPingsOnly) {
      if (signal.destinationPing) _ping(canvas, end, color, progress);
      return;
    }
    if (signal.sourcePing && progress < 0.22) {
      _ping(canvas, start, color, progress / 0.22);
    }
    if (signal.destinationPing && progress > 0.78) {
      _ping(canvas, end, color, (progress - 0.78) / 0.22);
    }
    final point = pointAt(progress);
    final particleSize =
        style.signalSize ?? tokens.componentOrbitSignalParticleSize;
    if (signalStyle == KOrbitSignalStyle.trail) {
      final trail = math.min(
        .4,
        (style.trailLength ?? tokens.componentOrbitSignalTrailLength) / 160,
      );
      final path = Path();
      for (var i = 0; i <= 8; i++) {
        final t = math.max(0.0, progress - trail * (1 - i / 8));
        final p = pointAt(t);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = particleSize
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [color.withValues(alpha: 0), color],
          ).createShader(Rect.fromPoints(start, point)),
      );
    }
    canvas.drawCircle(point, particleSize / 2, Paint()..color = color);
  }

  void _ping(Canvas canvas, Offset center, Color color, double progress) {
    final radius =
        5 +
        (style.pingRadius ?? tokens.componentOrbitSignalPingRadius) * progress;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tokens.componentOrbitConnectionLineWidth
        ..color = color.withValues(alpha: 1 - progress),
    );
  }

  Color _tone(KOrbitTone tone) => switch (tone) {
    KOrbitTone.neutral => tokens.componentOrbitConnectionColor,
    KOrbitTone.brand => tokens.colorBrandPrimaryAccent,
    KOrbitTone.info => tokens.colorStatusInfoAccent,
    KOrbitTone.success => tokens.colorStatusSuccessAccent,
    KOrbitTone.warning => tokens.colorStatusWarningAccent,
    KOrbitTone.error => tokens.colorStatusErrorAccent,
  };

  int _setShaderColor(ui.FragmentShader shader, int index, Color color) {
    shader
      ..setFloat(index++, color.r)
      ..setFloat(index++, color.g)
      ..setFloat(index++, color.b)
      ..setFloat(index++, color.a);
    return index;
  }

  @override
  bool shouldRepaint(covariant KOrbitPainter oldDelegate) =>
      levels != oldDelegate.levels ||
      nodes != oldDelegate.nodes ||
      connections != oldDelegate.connections ||
      tokens != oldDelegate.tokens ||
      style != oldDelegate.style ||
      reducedMotion != oldDelegate.reducedMotion;
}
