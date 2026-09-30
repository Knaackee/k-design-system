import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'orbit_models.dart';
import 'orbit_node_painter.dart';
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
    this.sceneFor,
    this.viewFor,
    this.opacityFor,
    this.scaleFor,
    this.isDeparting,
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
  final KOrbitSceneProjection Function(Size)? sceneFor;
  final KOrbitViewState Function(Size)? viewFor;
  final double Function(String id)? opacityFor;
  final double Function(String id)? scaleFor;
  final bool Function(String id)? isDeparting;

  @override
  void paint(Canvas canvas, Size size) {
    final time = orbitTimeSeconds();
    final camera = viewFor?.call(size) ?? view();
    final scene =
        sceneFor?.call(size) ??
        projectKOrbitScene(
          size: size,
          levels: levels,
          nodes: nodes,
          connections: connections,
          view: camera,
          timeSeconds: time,
          radiusRatio: tokens.componentOrbitCenterRadiusRatio,
          extentOverride: extentOverride,
        );
    final commands = <_DrawCommand>[];
    _addTracks(commands, scene, camera);
    _addConnections(commands, scene);
    _addNodes(commands, scene, time);
    _addSignals(commands, scene, signalTimeSeconds());
    commands.sort((a, b) => a.depth.compareTo(b.depth));
    for (final command in commands) {
      command.draw(canvas);
    }
  }

  void _addTracks(
    List<_DrawCommand> commands,
    KOrbitSceneProjection scene,
    KOrbitViewState camera,
  ) {
    for (final ring in scene.rings) {
      KOrbitProjectedPoint? previous;
      for (var i = 0; i <= 192; i++) {
        final world = kOrbitRingPointFor(
          ring: ring,
          angle: i / 192 * math.pi * 2,
          view: camera,
        );
        final point = kOrbitProjectPoint(
          point: world,
          center: scene.center,
          scale: scene.scale,
          depthScale: scene.extent,
        );
        if (previous != null) {
          _addSegment(
            commands,
            scene,
            previous,
            point,
            style.trackColor ?? tokens.componentOrbitTrackColor,
            tokens.componentOrbitTrackLineWidth,
            tokens.componentOrbitTrackOpacity,
          );
        }
        previous = point;
      }
    }
  }

  void _addConnections(
    List<_DrawCommand> commands,
    KOrbitSceneProjection scene,
  ) {
    final active = signals()
        .map((item) => item.signal.connectionId)
        .whereType<String>()
        .toSet();
    for (final item in scene.connections) {
      if (!item.connection.visible && !active.contains(item.connection.id)) {
        continue;
      }
      _addCurve(
        commands,
        scene,
        item,
        0,
        1,
        _tone(item.connection.tone),
        style.lineWidth ?? tokens.componentOrbitConnectionLineWidth,
        tokens.componentOrbitConnectionOpacity,
        item.connection.lineStyle,
      );
    }
  }

  void _addNodes(
    List<_DrawCommand> commands,
    KOrbitSceneProjection scene,
    double time,
  ) {
    final nodePainter = KOrbitNodePainter(
      tokens: tokens,
      style: style,
      reducedMotion: reducedMotion,
      shader: centerShader,
    );
    for (final item in scene.nodes) {
      final node = item.node;
      final radius = scene.radiusFor(node.id) * (scaleFor?.call(node.id) ?? 1);
      final opacity =
          (opacityFor?.call(node.id) ?? 1) * (_depthOpacity(item.point.depth));
      if (radius <= 0 || opacity <= 0) continue;
      commands.add(
        _DrawCommand(item.point.depth, (canvas) {
          canvas.save();
          canvas.translate(item.point.offset.dx, item.point.offset.dy);
          canvas.scale(scaleFor?.call(node.id) ?? 1);
          canvas.translate(-item.point.offset.dx, -item.point.offset.dy);
          final paintRadius = scene.radiusFor(node.id);
          nodePainter.draw(
            canvas,
            item.point.offset,
            paintRadius,
            node,
            opacity,
            time,
          );
          canvas.restore();
        }),
      );
    }
  }

  void _addSignals(
    List<_DrawCommand> commands,
    KOrbitSceneProjection scene,
    double time,
  ) {
    final byId = {
      for (final item in scene.connections) item.connection.id: item,
    };
    for (final active in signals()) {
      final duration =
          active.duration.inMicroseconds / Duration.microsecondsPerSecond;
      final progress = ((time - active.startedAt) / duration).clamp(0.0, 1.0);
      final nodeId = active.signal.nodeId;
      if (nodeId != null) {
        final node = scene.node(nodeId);
        if (node != null) {
          _addPing(
            commands,
            scene,
            node.point,
            scene.radiusFor(nodeId),
            progress,
            _tone(node.node.tone),
          );
        }
        continue;
      }
      final item = byId[active.signal.connectionId];
      if (item == null) continue;
      final directions =
          item.connection.direction == KOrbitDirection.bidirectional
          ? const [false, true]
          : [item.connection.direction == KOrbitDirection.reverse];
      for (final reverse in directions) {
        _addSignal(commands, scene, item, active.signal, progress, reverse);
      }
    }
  }

  void _addSignal(
    List<_DrawCommand> commands,
    KOrbitSceneProjection scene,
    KOrbitProjectedConnection item,
    KOrbitSignal signal,
    double progress,
    bool reverse,
  ) {
    final startT = reverse ? 1.0 : 0.0;
    final endT = reverse ? 0.0 : 1.0;
    KOrbitProjectedPoint endpoint(t) =>
        KOrbitProjectedPoint(item.pointAt(t), item.depthAt(t));
    final start = endpoint(startT);
    final end = endpoint(endT);
    final color = _tone(item.connection.tone);
    if (reducedMotion ||
        (signal.style ?? item.connection.signalStyle) ==
            KOrbitSignalStyle.endpointPingsOnly) {
      if (signal.destinationPing ?? item.connection.arrivalPing ?? true) {
        _addPing(
          commands,
          scene,
          end,
          _endpointRadius(scene, item.connection, reverse),
          progress,
          color,
        );
      }
      return;
    }
    if ((signal.sourcePing ?? item.connection.sourcePing ?? true) &&
        progress < .22) {
      _addPing(
        commands,
        scene,
        start,
        _endpointRadius(scene, item.connection, !reverse),
        progress / .22,
        color,
      );
    }
    if ((signal.destinationPing ?? item.connection.arrivalPing ?? true) &&
        progress > .78) {
      _addPing(
        commands,
        scene,
        end,
        _endpointRadius(scene, item.connection, reverse),
        (progress - .78) / .22,
        color,
      );
    }
    final t = startT + (endT - startT) * progress;
    final point = endpoint(t);
    final particle =
        style.signalSize ?? tokens.componentOrbitSignalParticleSize;
    if ((signal.style ?? item.connection.signalStyle) ==
        KOrbitSignalStyle.trail) {
      final span = math.min(
        .4,
        (style.trailLength ?? tokens.componentOrbitSignalTrailLength) / 160,
      );
      _addCurve(
        commands,
        scene,
        item,
        startT + (endT - startT) * math.max(0, progress - span),
        t,
        color,
        particle,
        .6,
        KOrbitLineStyle.solid,
      );
    }
    if (!_behindSphere(point, scene)) {
      commands.add(
        _DrawCommand(
          point.depth,
          (canvas) => canvas.drawCircle(
            point.offset,
            particle / 2,
            Paint()..color = color,
          ),
        ),
      );
    }
  }

  void _addCurve(
    List<_DrawCommand> commands,
    KOrbitSceneProjection scene,
    KOrbitProjectedConnection item,
    double from,
    double to,
    Color color,
    double width,
    double opacity,
    KOrbitLineStyle lineStyle,
  ) {
    var previous = KOrbitProjectedPoint(item.pointAt(from), item.depthAt(from));
    var distance = 0.0;
    for (var i = 1; i <= 40; i++) {
      final t = from + (to - from) * i / 40;
      final point = KOrbitProjectedPoint(item.pointAt(t), item.depthAt(t));
      final length = (point.offset - previous.offset).distance;
      final dash = lineStyle == KOrbitLineStyle.dotted
          ? width
          : style.dashLength ?? tokens.componentOrbitConnectionDashLength;
      final gap = style.gapLength ?? tokens.componentOrbitConnectionGapLength;
      if (lineStyle == KOrbitLineStyle.solid ||
          distance % (dash + gap) < dash) {
        _addSegment(commands, scene, previous, point, color, width, opacity);
      }
      distance += length;
      previous = point;
    }
  }

  void _addSegment(
    List<_DrawCommand> commands,
    KOrbitSceneProjection scene,
    KOrbitProjectedPoint a,
    KOrbitProjectedPoint b,
    Color color,
    double width,
    double opacity,
  ) {
    final middle = KOrbitProjectedPoint(
      (a.offset + b.offset) / 2,
      (a.depth + b.depth) / 2,
    );
    if (_behindSphere(middle, scene)) return;
    commands.add(
      _DrawCommand(
        middle.depth,
        (canvas) => canvas.drawLine(
          a.offset,
          b.offset,
          Paint()
            ..color = color.withValues(alpha: opacity)
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round,
        ),
      ),
    );
  }

  bool _behindSphere(KOrbitProjectedPoint point, KOrbitSceneProjection scene) {
    for (final item in scene.nodes) {
      final radius = scene.radiusFor(item.node.id);
      final distance = (point.offset - item.point.offset).distance;
      if (distance >= radius) continue;
      final surface =
          item.point.depth +
          math.sqrt(radius * radius - distance * distance) /
              (scene.scale * scene.extent);
      if (point.depth < surface) return true;
    }
    return false;
  }

  void _addPing(
    List<_DrawCommand> commands,
    KOrbitSceneProjection scene,
    KOrbitProjectedPoint point,
    double base,
    double progress,
    Color color,
  ) => commands.add(
    _DrawCommand(
      point.depth +
          (base + tokens.componentOrbitSignalPingRadius) /
              (scene.scale * scene.extent),
      (canvas) => canvas.drawCircle(
        point.offset,
        base +
            3 +
            (style.pingRadius ?? tokens.componentOrbitSignalPingRadius) *
                progress,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = tokens.componentOrbitConnectionLineWidth
          ..color = color.withValues(alpha: 1 - progress),
      ),
    ),
  );
  double _endpointRadius(
    KOrbitSceneProjection scene,
    KOrbitConnection item,
    bool target,
  ) => scene.radiusFor(target ? item.targetId : item.sourceId);
  double _depthOpacity(double depth) =>
      .55 + .45 * ((depth + 1) / 2).clamp(0, 1);
  Color _tone(KOrbitTone tone) => switch (tone) {
    KOrbitTone.neutral => tokens.componentOrbitConnectionColor,
    KOrbitTone.brand => tokens.colorBrandPrimaryAccent,
    KOrbitTone.info => tokens.colorStatusInfoAccent,
    KOrbitTone.success => tokens.colorStatusSuccessAccent,
    KOrbitTone.warning => tokens.colorStatusWarningAccent,
    KOrbitTone.error => tokens.colorStatusErrorAccent,
  };
  @override
  bool shouldRepaint(covariant KOrbitPainter old) =>
      levels != old.levels ||
      nodes != old.nodes ||
      connections != old.connections ||
      tokens != old.tokens ||
      style != old.style ||
      reducedMotion != old.reducedMotion;
}

class _DrawCommand {
  const _DrawCommand(this.depth, this.draw);
  final double depth;
  final void Function(Canvas) draw;
}
