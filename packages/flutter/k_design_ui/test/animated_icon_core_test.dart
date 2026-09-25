import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/src/primitives/animated_icon_core/core.dart';

void main() {
  final menu = resampleIcon('M4 6H20 M4 12H20 M4 18H20');
  final close = resampleIcon('M6 6L18 18 M18 6L6 18');
  final check = resampleIcon('M20 6 9 17 4 12');
  final plus = resampleIcon('M5 12H19 M12 5V19');

  test('resampling retains endpoints and sharp check-mark corner', () {
    final points = check.single.pts;
    expect(points.length, 128);
    expect(points.take(2), [20, 6]);
    expect(points.skip(126), [4, 12]);
    expect([
      for (var i = 0; i < points.length; i += 2)
        if (points[i] == 9 && points[i + 1] == 17) true,
    ], isNotEmpty);
  });

  test('differing path counts cover targets without disappearing strokes', () {
    final plan = buildPlan(menu, close);
    expect(plan.items.length, 3);
    final targets = plan.items.map((item) {
      final start = '${item.bO[0].round()},${item.bO[1].round()}';
      final end = '${item.bO[126].round()},${item.bO[127].round()}';
      return ([start, end]..sort()).join('|');
    }).toSet();
    expect(targets.length, 2);
  });

  test(
    'interruptions preserve rendered geometry and converge to final target',
    () {
      var plan = buildPlan(menu, close);
      var output = allocOutputs(plan);
      final spring = MorphSpring()..config(420, 30);
      spring.start();
      for (final next in [check, plus, menu, close]) {
        for (var i = 0; i < 7; i++) {
          spring.step(1 / 60);
        }
        interpPolar(plan, spring.x, output);
        final current = [
          for (var i = 0; i < output.length; i++)
            Sampled(Float64List.fromList(output[i]), plan.items[i].closed),
        ];
        final velocity = spring.v;
        plan = buildPlan(current, next);
        output = allocOutputs(plan);
        spring.start();
        expect(spring.v, velocity.clamp(-14, 14));
        interpPolar(plan, 0, output);
        for (var p = 0; p < output.length; p++) {
          for (var i = 0; i < output[p].length; i++) {
            expect(output[p][i], closeTo(plan.items[p].a[i], 1e-9));
          }
        }
      }
      var settled = false;
      for (var i = 0; i < 300 && !settled; i++) {
        settled = spring.step(1 / 60);
        interpPolar(plan, spring.x, output);
        expect(output.every((path) => path.every((x) => x.isFinite)), isTrue);
      }
      expect(settled, isTrue);
      interpPolar(plan, 1, output);
      for (var p = 0; p < output.length; p++) {
        for (var i = 0; i < output[p].length; i++) {
          expect(output[p][i], closeTo(plan.items[p].bO[i], 1e-9));
        }
      }
    },
  );
}
