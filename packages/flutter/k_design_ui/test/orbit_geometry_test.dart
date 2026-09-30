import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/src/data_display/orbit/orbit_models.dart';
import 'package:k_design_ui/src/data_display/orbit/orbit_motion.dart';
import 'package:k_design_ui/src/data_display/orbit/orbit_presentation.dart';
import 'package:k_design_ui/src/data_display/orbit/orbit_projection.dart';
import 'package:k_design_ui/src/data_display/orbit/orbit_transition.dart';

void main() {
  test('nested projection follows parents and keeps independent radii', () {
    const levels = [
      KOrbitLevel(id: 'planet', radius: 100, periodSeconds: 40),
      KOrbitLevel(id: 'moon', radius: 35, periodSeconds: 10),
      KOrbitLevel(id: 'satellite', radius: 12, periodSeconds: 3),
    ];
    const nodes = [
      KOrbitNode(id: 'root', label: 'Root', radius: 10),
      KOrbitNode(
        id: 'planet',
        label: 'Planet',
        parentId: 'root',
        levelId: 'planet',
        radius: 20,
      ),
      KOrbitNode(
        id: 'moon',
        label: 'Moon',
        parentId: 'planet',
        levelId: 'moon',
        radius: 5,
      ),
      KOrbitNode(
        id: 'satellite',
        label: 'Satellite',
        parentId: 'moon',
        levelId: 'satellite',
        radius: 2,
      ),
    ];
    final scene = projectKOrbitScene(
      size: const Size.square(600),
      levels: levels,
      nodes: nodes,
      connections: const [],
      view: const KOrbitViewState(),
      timeSeconds: 0,
    );
    expect(scene.extent, 149);
    expect(scene.radiusFor('planet'), scene.radiusFor('root') * 2);
    expect(scene.node('satellite')!.world.x, 147);
  });

  test('motion is capped per node and preserves accumulated phase', () {
    const levels = [KOrbitLevel(id: 'a', radius: 100, periodSeconds: 60)];
    const nodes = [
      KOrbitNode(id: 'a', label: 'A', levelId: 'a'),
      KOrbitNode(
        id: 'b',
        label: 'B',
        levelId: 'a',
        periodSeconds: 1,
        direction: -1,
      ),
    ];
    final angles = advanceKOrbitAngles(
      angles: {},
      levels: levels,
      nodes: nodes,
      delta: 1,
      speed: 2,
      maxAngularSpeed: 10,
    );
    expect(angles['a'], closeTo(math.pi / 18, 1e-12));
    expect(angles['b'], closeTo(-math.pi / 18, 1e-12));
    advanceKOrbitAngles(
      angles: angles,
      levels: levels,
      nodes: nodes,
      delta: 0,
      speed: 100,
      maxAngularSpeed: 5,
    );
    expect(angles['a'], closeTo(math.pi / 18, 1e-12));
  });

  test('camera return, progress reversal, and presence stay continuous', () {
    final presentation = KOrbitPresentation();
    final pinned = presentation.resolveCamera(
      target: const KOrbitViewState(),
      pinnedId: 'node',
      followOffset: (_) => const Offset(12, 34),
      now: 0,
      duration: const Duration(milliseconds: 200),
    );
    expect(pinned.offset, const Offset(12, 34));
    expect(
      presentation.resolveCamera(
        target: const KOrbitViewState(),
        pinnedId: null,
        followOffset: (_) => Offset.zero,
        now: 10,
        duration: const Duration(milliseconds: 200),
      ),
      pinned,
    );
    expect(
      presentation.resolveCamera(
        target: const KOrbitViewState(),
        pinnedId: null,
        followOffset: (_) => Offset.zero,
        now: 210,
        duration: const Duration(milliseconds: 200),
      ),
      const KOrbitViewState(),
    );

    double sample(num value, double now) => presentation
        .animateProgress(
          nodes: [KOrbitNode(id: 'n', label: 'N', progress: value.toDouble())],
          now: now,
          duration: const Duration(milliseconds: 200),
        )
        .single
        .progress!;
    expect(sample(0, 0), 0);
    expect(sample(100, 10), 0);
    expect(sample(100, 110), 50);
    expect(sample(0, 110), 50);
    expect(sample(0, 210), 25);

    const enter = KOrbitPresenceMotion(
      from: 0,
      to: 1,
      startedAt: 0,
      durationMs: 400,
    );
    const exit = KOrbitPresenceMotion(
      from: 1,
      to: 0,
      startedAt: 0,
      durationMs: 400,
    );
    expect(kOrbitPresenceScale(enter, 250), greaterThan(1));
    final interrupted = kOrbitPresenceScale(exit, 200);
    expect(
      kOrbitPresenceScale(
        KOrbitPresenceMotion(
          from: interrupted,
          to: 1,
          startedAt: 200,
          durationMs: 400,
        ),
        200,
      ),
      closeTo(interrupted, 1e-12),
    );
  });

  test('copyWith accepts integer numerics and clears nullable fields', () {
    const node = KOrbitNode(id: 'n', label: 'N', progress: 1, radius: 2);
    expect(node.copyWith(progress: 50).progress, 50.0);
    expect(node.copyWith(radius: null).radius, isNull);
  });
}
