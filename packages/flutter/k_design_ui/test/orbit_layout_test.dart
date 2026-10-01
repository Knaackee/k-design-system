import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/src/data_display/orbit/orbit_models.dart';
import 'package:k_design_ui/src/data_display/orbit/orbit_layout.dart';
import 'package:k_design_ui/src/data_display/orbit/orbit_motion.dart';
import 'package:k_design_ui/src/data_display/orbit/orbit_projection.dart';

void main() {
  final source =
      jsonDecode(
            File(
              '../../../apps/storybook/src/orbit-layout.fixture.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final levels = (source['levels'] as List)
      .map(
        (row) => KOrbitLevel(
          id: row['id'] as String,
          radius: (row['radius'] as num).toDouble(),
          periodSeconds: (row['periodSeconds'] as num).toDouble(),
        ),
      )
      .toList();
  final nodes = (source['nodes'] as List)
      .map(
        (row) => KOrbitNode(
          id: row['id'] as String,
          label: row['label'] as String,
          radius: (row['radius'] as num).toDouble(),
          parentId: row['parentId'] as String?,
          levelId: row['levelId'] as String?,
        ),
      )
      .toList();
  void assertClear(KOrbitLayout layout) {
    final byId = {for (final node in layout.nodes) node.id: node};
    String? projectOf(KOrbitNode node) => node.id.startsWith('project-')
        ? node.id
        : node.parentId == null
        ? null
        : projectOf(byId[node.parentId]!);
    for (final time in [0.0, 7.0, 61.0, 300.0]) {
      final scene = projectKOrbitScene(
        size: const Size(1200, 900),
        levels: layout.levels,
        nodes: layout.nodes,
        connections: const [],
        view: const KOrbitViewState(),
        timeSeconds: time,
      );
      for (final a in layout.nodes) {
        for (final b in layout.nodes) {
          if (a.id.compareTo(b.id) >= 0 ||
              projectOf(a) == null ||
              projectOf(b) == null ||
              projectOf(a) == projectOf(b)) {
            continue;
          }
          final pa = scene.node(a.id)!.world, pb = scene.node(b.id)!.world;
          final distance = math.sqrt(
            math.pow(pa.x - pb.x, 2) + math.pow(pa.y - pb.y, 2),
          );
          expect(
            distance,
            greaterThanOrEqualTo(
              (a.radius ?? 12) + (b.radius ?? 12) + 12 - 1e-6,
            ),
            reason: '${a.id}/${b.id} at $time',
          );
        }
      }
    }
  }

  test(
    'unequal projects remain separated during motion and after filtering',
    () {
      assertClear(layoutKOrbit(levels, nodes));
      assertClear(
        layoutKOrbit(
          levels,
          nodes
              .where(
                (node) => !RegExp(
                  r'^(project|issue|agent)-1(?:-|$)',
                ).hasMatch(node.id),
              )
              .toList(),
        ),
      );
    },
  );
  test(
    'different periods use separate annuli and group angles stay synchronized',
    () {
      final layout = layoutKOrbit(
        levels,
        nodes
            .map(
              (node) => node.id == 'project-1'
                  ? node.copyWith(periodSeconds: 75.0)
                  : node,
            )
            .toList(),
      );
      assertClear(layout);
      final angles = advanceKOrbitAngles(
        angles: {'project-0': 1, 'project-2': 2},
        levels: layout.levels,
        nodes: layout.nodes,
        delta: 1,
        synchronizeLevels: true,
      );
      expect(angles['project-0'], angles['project-2']);
      expect(() => layoutKOrbit(levels, nodes, gap: -1), throwsArgumentError);
    },
  );
}
