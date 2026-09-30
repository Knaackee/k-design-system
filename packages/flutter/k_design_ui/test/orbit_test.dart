import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/data_display/orbit/orbit_projection.dart'
    show kOrbitHitTest;

const _levels = [
  KOrbitLevel(id: 'near', radius: 80, inclination: .3, periodSeconds: 10),
  KOrbitLevel(id: 'far', radius: 130, inclination: -.25, azimuth: .4),
];

const _nodes = [
  KOrbitNode(id: 'team', label: 'Team'),
  KOrbitNode(id: 'project', levelId: 'near', label: 'Project', phase: 0),
  KOrbitNode(id: 'agent', levelId: 'far', label: 'Agent', phase: math.pi),
];

const _connections = [
  KOrbitConnection(id: 'assignment', sourceId: 'project', targetId: 'agent'),
];

const _demoLevels = [
  KOrbitLevel(
    id: 'projects',
    radius: 153,
    inclination: 1.043,
    azimuth: .488692,
    periodSeconds: 44,
  ),
  KOrbitLevel(
    id: 'issues',
    radius: 62,
    inclination: .85,
    azimuth: -.418879,
    periodSeconds: 26,
    clockwise: false,
  ),
  KOrbitLevel(
    id: 'people',
    radius: 42,
    inclination: .9,
    azimuth: .331613,
    periodSeconds: 16,
  ),
];

const _demoNodes = [
  KOrbitNode(id: 'team', label: 'Platform team'),
  KOrbitNode(
    id: 'atlas',
    label: 'Atlas',
    levelId: 'projects',
    parentId: 'team',
    phase: .15,
  ),
  KOrbitNode(
    id: 'issue-a',
    label: 'Token parity',
    levelId: 'issues',
    parentId: 'atlas',
    phase: .8,
    status: KOrbitStatus.question,
  ),
  KOrbitNode(
    id: 'agent',
    label: 'Orbit agent',
    levelId: 'people',
    parentId: 'issue-a',
    phase: 1.5,
    status: KOrbitStatus.active,
  ),
];

void main() {
  test('validates hierarchy, endpoints and pulse periods', () {
    expect(
      () => validateKOrbit(
        levels: _levels,
        nodes: _nodes,
        connections: const [
          KOrbitConnection(id: 'bad', sourceId: 'project', targetId: 'missing'),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => validateKOrbit(
        levels: _levels,
        nodes: const [
          KOrbitNode(id: 'a', label: 'A', parentId: 'b', levelId: 'near'),
          KOrbitNode(id: 'b', label: 'B', parentId: 'a', levelId: 'near'),
        ],
        connections: const [],
      ),
      throwsArgumentError,
    );
    expect(
      () => validateKOrbit(
        levels: _levels,
        nodes: const [KOrbitNode(id: 'a', label: 'A', parentId: 'team')],
        connections: const [],
      ),
      throwsArgumentError,
    );
    expect(
      () => validateKOrbit(
        levels: _levels,
        nodes: const [
          KOrbitNode(id: 'a', label: 'A', pulsePeriod: Duration.zero),
        ],
        connections: const [],
      ),
      throwsArgumentError,
    );
  });

  test('matches the shared recursive projection fixture', () {
    final fixtureFile = [
      File('apps/storybook/src/orbit-parity.fixture.json'),
      File('../../../apps/storybook/src/orbit-parity.fixture.json'),
    ].firstWhere((file) => file.existsSync());
    final fixture =
        jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
    final levels = [
      for (final value in fixture['levels'] as List)
        KOrbitLevel(
          id: value['id'] as String,
          label: value['label'] as String,
          radius: (value['radius'] as num).toDouble(),
          periodSeconds: (value['periodSeconds'] as num).toDouble(),
        ),
    ];
    final nodes = [
      for (final value in fixture['nodes'] as List)
        KOrbitNode(
          id: value['id'] as String,
          label: value['label'] as String,
          levelId: value['levelId'] as String?,
          parentId: value['parentId'] as String?,
          phase: (value['phase'] as num?)?.toDouble() ?? 0,
        ),
    ];
    final sizeValue = fixture['size'] as Map<String, dynamic>;
    final size = Size(
      (sizeValue['width'] as num).toDouble(),
      (sizeValue['height'] as num).toDouble(),
    );
    for (final value in fixture['cases'] as List) {
      final scene = projectKOrbitScene(
        size: size,
        levels: levels,
        nodes: nodes,
        connections: const [],
        view: KOrbitViewState(
          yaw: (value['yaw'] as num).toDouble(),
          pitch: (value['pitch'] as num).toDouble(),
        ),
        timeSeconds: (value['time'] as num).toDouble(),
      );
      expect(scene.extent, fixture['extent']);
      expect(scene.scale, fixture['scale']);
      expect(scene.centerRadius, closeTo(fixture['centerRadius'] as num, 1e-9));
      expect(scene.rings, hasLength(fixture['ringCount'] as int));
      final expected = value['points'] as Map<String, dynamic>;
      for (final entry in expected.entries) {
        final point = scene.node(entry.key)!.point;
        final vector = entry.value as List;
        expect(point.offset.dx, closeTo(vector[0] as num, 1e-9));
        expect(point.offset.dy, closeTo(vector[1] as num, 1e-9));
        expect(point.depth, closeTo(vector[2] as num, 1e-9));
      }
    }
  });

  test('focal zoom preserves the pointer anchor', () {
    final zoomed = kOrbitZoomAt(
      view: const KOrbitViewState(),
      zoom: 2,
      focalPoint: const Offset(300, 200),
      viewportCenter: const Offset(200, 200),
      minZoom: .65,
      maxZoom: 2.2,
    );
    expect(zoomed.zoom, 2);
    expect(zoomed.offset, const Offset(-100, 0));
  });

  test('overlapping hit targets activate the nearest marker', () {
    const levels = [KOrbitLevel(id: 'ring', radius: 20, periodSeconds: 10)];
    const nodes = [
      KOrbitNode(id: 'a', label: 'A', levelId: 'ring', phase: 0),
      KOrbitNode(id: 'b', label: 'B', levelId: 'ring', phase: .08),
    ];
    final scene = projectKOrbitScene(
      size: const Size(400, 400),
      levels: levels,
      nodes: nodes,
      connections: const [],
      view: const KOrbitViewState(),
      timeSeconds: 0,
    );
    final b = scene.node('b')!;
    expect(
      kOrbitHitTest(
        scene: scene,
        labels: const {},
        point: b.point.offset,
        hitTargetSize: 44,
      )?.id,
      'b',
    );
  });

  testWidgets('controller enforces signal lifecycle and capacity', (
    tester,
  ) async {
    final controller = KOrbitController();
    final ended = <(String, KOrbitSignalEndReason)>[];
    await tester.pumpWidget(
      _app(
        KOrbit(
          levels: _levels,
          nodes: _nodes,
          connections: _connections,
          controller: controller,
          maxActiveSignals: 1,
          showControls: false,
          onSignalEnd: (id, reason) => ended.add((id, reason)),
        ),
      ),
    );
    expect(
      controller.triggerSignal(
        const KOrbitSignal(
          id: 'one',
          connectionId: 'assignment',
          duration: Duration(milliseconds: 100),
        ),
      ),
      KOrbitSignalTriggerResult.accepted,
    );
    expect(
      controller.triggerSignal(
        const KOrbitSignal(id: 'two', connectionId: 'assignment'),
      ),
      KOrbitSignalTriggerResult.capacity,
    );
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 151));
    expect(ended, [('one', KOrbitSignalEndReason.completed)]);
  });

  testWidgets('labels activate nodes and status pulses update', (tester) async {
    String? selected;
    late StateSetter update;
    var active = true;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return KOrbit(
              levels: _levels,
              nodes: [
                KOrbitNode(
                  id: 'team',
                  label: 'Team',
                  status: active ? KOrbitStatus.active : KOrbitStatus.idle,
                ),
                KOrbitNode(
                  id: 'project',
                  label: 'Project',
                  levelId: 'near',
                  status: active ? KOrbitStatus.question : KOrbitStatus.idle,
                  statusLabel: active ? 'Needs your answer' : null,
                ),
              ],
              connections: const [],
              elapsedSeconds: 0,
              showControls: false,
              onSelectionChange: (value) => selected = value,
            );
          },
        ),
      ),
    );
    expect(find.byKey(const ValueKey('k-orbit-pulse-team')), findsOneWidget);
    expect(find.byKey(const ValueKey('k-orbit-pulse-project')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('k-orbit-node-team')),
        matching: find.byType(KIcon),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('k-orbit-node-project')),
        matching: find.byType(KIcon),
      ),
      findsOneWidget,
    );
    await tester.tapAt(tester.getCenter(find.text('Project')));
    expect(selected, 'project');
    update(() => active = false);
    await tester.pump();
    expect(find.byKey(const ValueKey('k-orbit-pulse-team')), findsNothing);
    expect(find.byKey(const ValueKey('k-orbit-pulse-project')), findsNothing);
  });

  testWidgets('demo overlap activates Atlas at its projected center', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    String? activated;
    await tester.pumpWidget(
      _app(
        UnconstrainedBox(
          child: SizedBox.square(
            dimension: 375,
            child: KOrbit(
              levels: _demoLevels,
              nodes: _demoNodes,
              connections: const [],
              elapsedSeconds: 0,
              showControls: false,
              onNodeActivate: (node) => activated = node.id,
            ),
          ),
        ),
      ),
    );
    final scene = projectKOrbitScene(
      size: const Size.square(375),
      levels: _demoLevels,
      nodes: _demoNodes,
      connections: const [],
      view: const KOrbitViewState(),
      timeSeconds: 0,
    );
    final origin = tester.getTopLeft(find.byType(KOrbit));
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('k-orbit-node-atlas')))
          .rect
          .size,
      const Size.square(24),
    );
    await tester.tapAt(origin + scene.node('atlas')!.point.offset);
    expect(activated, 'atlas');
    semantics.dispose();
  });

  testWidgets('filtered nodes and levels leave after the token transition', (
    tester,
  ) async {
    late StateSetter update;
    var filtered = false;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return KOrbit(
              levels: filtered ? const [] : _levels,
              nodes: filtered
                  ? const [KOrbitNode(id: 'team', label: 'Team')]
                  : _nodes,
              connections: const [],
              elapsedSeconds: 0,
              showControls: false,
            );
          },
        ),
      ),
    );
    update(() => filtered = true);
    await tester.pump();
    expect(find.byKey(const ValueKey('k-orbit-node-project')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 90));
    expect(find.byKey(const ValueKey('k-orbit-node-project')), findsOneWidget);
    update(() {});
    await tester.pump();
    expect(find.byKey(const ValueKey('k-orbit-node-project')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('k-orbit-node-project')), findsNothing);
  });

  testWidgets('unbounded layout keeps a square stage above controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: KOrbit(
            levels: _levels,
            nodes: _nodes,
            connections: const [],
            elapsedSeconds: 0,
            onPausedChange: (_) {},
            onMotionSpeedChange: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Reset view'), findsOneWidget);
    expect(find.text('Pause motion'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: kDesignTheme(),
  home: Center(child: SizedBox(width: 500, height: 500, child: child)),
);
