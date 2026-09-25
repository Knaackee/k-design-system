import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/src/generated/k_icons.g.dart';
import 'package:k_design_ui/src/primitives/animated_icon_core/core.dart';

void main() {
  final fixture =
      jsonDecode(
            File(
              'test/fixtures/animated_icon_reference.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final icons = fixture['icons'] as Map<String, dynamic>;
  final tolerance = (fixture['coordinateTolerance'] as num).toDouble();

  List<IconNode> nodes(dynamic value) => (value as List)
      .map(
        (node) => IconNode(
          node[0] as String,
          Map<String, Object?>.from(node[1] as Map),
        ),
      )
      .toList();

  for (final transition in fixture['transitions'] as List) {
    final from = transition['from'] as String;
    final to = transition['to'] as String;
    test('$from → $to matches upstream sampled geometry at five frames', () {
      final plan = buildPlan(
        resampleIcon(nodes(icons[from])),
        resampleIcon(nodes(icons[to])),
      );
      final output = allocOutputs(plan);
      for (final frame in transition['frames'] as List) {
        final progress = (frame['t'] as num).toDouble();
        interpPolar(plan, progress, output);
        final expected = frame['points'] as List;
        expect(output.length, expected.length);
        for (var path = 0; path < output.length; path++) {
          final points = expected[path] as List;
          expect(output[path].length, points.length);
          for (var point = 0; point < points.length; point++) {
            expect(
              output[path][point],
              closeTo((points[point] as num).toDouble(), tolerance),
              reason: '$from → $to at $progress, path $path, coordinate $point',
            );
          }
        }
      }
    });
  }

  test('spring integration and interrupted velocity match upstream', () {
    final spring = MorphSpring()..config(300, 14);
    spring.start();
    for (final frame in fixture['springFrames'] as List) {
      if (frame['restart'] == true) spring.start();
      final settled = spring.step((frame['dt'] as num).toDouble());
      expect(spring.x, closeTo((frame['x'] as num).toDouble(), 1e-12));
      expect(spring.v, closeTo((frame['v'] as num).toDouble(), 1e-12));
      expect(settled, frame['settled']);
    }
  });

  test(
    'every Lucide icon samples and morphs finite geometry in both directions',
    () {
      final anchor = resampleIcon(nodes(icons['menu']));
      expect(kIconSvg.length, 1838);
      expect(kIconSvg.length, KIconName.values.length);
      for (final entry in kIconSvg.entries) {
        final shapes =
            RegExp(
                  r'<(path|line|circle|ellipse|rect|polyline|polygon)\b([^>]*)',
                )
                .allMatches(entry.value)
                .map(
                  (element) => IconNode(element.group(1)!, {
                    for (final attr in RegExp(
                      r'([\w-]+)="([^"]*)"',
                    ).allMatches(element.group(2)!))
                      attr.group(1)!: attr.group(2)!,
                  }),
                )
                .toList();
        final cubics = iconToCubics(shapes);
        final sampled = resampleIcon(shapes);
        expect(cubics, isNotEmpty, reason: entry.key.name);
        expect(sampled.length, cubics.length, reason: entry.key.name);
        for (final path in sampled) {
          expect(path.pts.length, 128, reason: entry.key.name);
          expect(
            path.pts.every((coordinate) => coordinate.isFinite),
            isTrue,
            reason: entry.key.name,
          );
        }
        for (final endpoints in [(anchor, sampled), (sampled, anchor)]) {
          final plan = buildPlan(endpoints.$1, endpoints.$2);
          final output = allocOutputs(plan);
          expect(output, isNotEmpty, reason: entry.key.name);
          for (final progress in [0.0, 0.5, 1.0]) {
            interpPolar(plan, progress, output);
            expect(
              output.every((path) => path.every((value) => value.isFinite)),
              isTrue,
              reason: '${entry.key.name} at $progress',
            );
          }
        }
      }
    },
  );
}
