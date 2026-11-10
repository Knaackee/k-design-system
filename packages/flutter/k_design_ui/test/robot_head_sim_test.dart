import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/src/data_display/robot_head/faces.dart';
import 'package:k_design_ui/src/data_display/robot_head/geometry.dart';
import 'package:k_design_ui/src/data_display/robot_head/light.dart';
import 'package:k_design_ui/src/data_display/robot_head/sim.dart';
import 'package:k_design_ui/src/data_display/robot_head/types.dart';

Matcher closeList(List<double> expected, double delta) =>
    orderedEquals(expected.map((value) => closeTo(value, delta)));

void main() {
  const states = KRobotHeadState.values;

  test('seeded simulation matches the JavaScript engine fixtures', () {
    const expected = <KRobotHeadState, List<double>>{
      KRobotHeadState.idle: [
        -1,
        0,
        0,
        -0.1571476642738965,
        -0.03000306256492296,
        0.02514362628382344,
        0.0015775344465523715,
        1,
        1,
        -0.00033411803223542733,
        0.00039869206263529086,
      ],
      KRobotHeadState.thinking: [
        0,
        0,
        0,
        0.28575852304834115,
        0.19911072520448717,
        -0.12938831276816343,
        0.0015775344465523715,
        1,
        1,
        0.0005082243619126766,
        -0.0006076973391270867,
      ],
      KRobotHeadState.searching: [
        0.7804937546064401,
        0,
        0,
        0.40573253207124343,
        -0.07898488689322868,
        -0.044261730771408374,
        0.0015775344465523715,
        1,
        1,
        -0.000010144399872196761,
        -0.0012908243217254864,
      ],
      KRobotHeadState.listening: [
        0,
        0,
        0,
        -0.1400487371904661,
        0.020006962455780868,
        0.17005918087413738,
        0.0015775344465523715,
        1,
        1,
        -0.0007940274229999889,
        -0.00009341499094117471,
      ],
      KRobotHeadState.speaking: [
        0,
        0,
        0,
        0.10189412150749674,
        0.035892736209892445,
        0.04826525518480246,
        0.004855043864475269,
        1,
        1,
        -0.00002646274051944014,
        -0.00017259277108272177,
      ],
      KRobotHeadState.working: [
        0,
        0,
        0,
        0.07226981967541568,
        -0.16005569964624694,
        0.025866860870474417,
        0.013438131710935306,
        1,
        1,
        -0.000009063885535346312,
        0.0007473199275293977,
      ],
      KRobotHeadState.happy: [
        0,
        0,
        0,
        0.010912918466392507,
        0.08002784982312347,
        -0.0215340326594,
        0.0015775344465523715,
        1,
        1,
        -0.0013794034092448658,
        -0.00037365996376469883,
      ],
      KRobotHeadState.error: [
        0,
        0,
        0,
        0,
        -0.05999820162674596,
        -0.04999850135562162,
        0.0015775344465523715,
        1,
        1,
        0.00007917875616559103,
        0.0000950145073987072,
      ],
      KRobotHeadState.sleeping: [
        0,
        0,
        0,
        0.059519704931144425,
        -0.3372783279431519,
        0.1289593606841462,
        0.01564664553855221,
        1,
        1,
        -0.00015660154093127793,
        0.00040957326089718563,
      ],
    };

    for (final state in states) {
      final sim = RobotSim(0.314159, state);
      for (final dt in [0.016, 0.033, 0.25, 1.25]) {
        sim.update(dt);
      }
      final actual = [
        sim.face.lookX,
        sim.face.lookY,
        sim.face.blink,
        sim.pose.yaw,
        sim.pose.pitch,
        sim.pose.roll,
        sim.pose.lift,
        sim.pose.sx,
        sim.pose.sy,
        sim.pose.antennaX,
        sim.pose.antennaZ,
      ];
      expect(actual, closeList(expected[state]!, 1e-12), reason: state.name);
    }
  });

  test('all face and light functions match JavaScript fixtures', () {
    const expected = <KRobotHeadState, List<double>>{
      KRobotHeadState.idle: [18, 18, 3069, 0.8487731472559311],
      KRobotHeadState.thinking: [
        24,
        12.660000085830688,
        2386.1100132465363,
        0.4798699313703219,
      ],
      KRobotHeadState.searching: [
        98,
        33.360000252723694,
        6422.600055575371,
        0.25,
      ],
      KRobotHeadState.listening: [
        34,
        29.399999976158142,
        6533.63999247551,
        0.95,
      ],
      KRobotHeadState.speaking: [26, 26, 5205, 0.664276678630859],
      KRobotHeadState.working: [26, 19.459999918937683, 4928.00997376442, 1],
      KRobotHeadState.happy: [
        18,
        17.199999809265137,
        3856.599944114685,
        0.7135075095449102,
      ],
      KRobotHeadState.error: [26, 24.40000009536743, 5685.400032281876, 0.15],
      KRobotHeadState.sleeping: [24, 10.146934807300568, 1818.2217001616955, 0],
    };

    for (final state in states) {
      final grid = makeGrid(25, 15);
      faces[state]!(
        grid,
        FaceParams(
          lookX: 1.2,
          lookY: -0.7,
          blink: 0.35,
          time: 1.234,
          side: -1,
          seed: 0.314159,
        ),
      );
      var nonzero = 0;
      var sum = 0.0;
      var weighted = 0.0;
      for (var i = 0; i < grid.v.length; i++) {
        final value = grid.v[i];
        if (value != 0) nonzero++;
        sum += value;
        weighted += value * (i + 1);
      }
      expect([grid.cols, grid.rows, grid.ox, grid.oy], [26, 16, 2, 1]);
      expect(
        [nonzero.toDouble(), sum, weighted, lights[state]!.pulse(1.234)],
        closeList(expected[state]!, 1e-6),
        reason: state.name,
      );
    }
  });

  test('supplied silence remains silence instead of using synthetic audio', () {
    const expected = {
      KRobotHeadState.listening: (nonzero: 36, sum: 33.0),
      KRobotHeadState.speaking: (nonzero: 32, sum: 32.0),
    };
    for (final state in [KRobotHeadState.listening, KRobotHeadState.speaking]) {
      final grid = makeGrid(cols, rows);
      faces[state]!(
        grid,
        FaceParams(
          lookX: 0,
          lookY: 0,
          blink: 0,
          time: 0.75,
          side: 1,
          seed: 0.5,
          audioLevel: 0,
          audioBands: const [0, 0, 0],
        ),
      );
      final nonzero = grid.v.where((value) => value != 0).length;
      final sum = grid.v.fold(0.0, (total, value) => total + value);
      expect(nonzero, expected[state]!.nonzero);
      expect(sum, expected[state]!.sum);
    }
  });

  test('thinking face preserves JavaScript negative remainder timing', () {
    final grid = makeGrid(cols, rows);
    faces[KRobotHeadState.thinking]!(
      grid,
      FaceParams(lookX: 0, lookY: 0, blink: 0, time: 0, side: 1, seed: 0.5),
    );
    final sum = grid.v.fold(0.0, (total, value) => total + value);
    final weighted = grid.v.indexed.fold(
      0.0,
      (total, entry) => total + entry.$2 * (entry.$1 + 1),
    );
    expect([
      sum,
      weighted,
    ], closeList(const [19.621649265289307, 3014.6165335178375], 1e-6));
  });

  test('rest poses retain the JavaScript defaults', () {
    expect(restPose(KRobotHeadState.thinking).yaw, 0.24);
    expect(restPose(KRobotHeadState.searching).roll, -0.04);
    expect(restPose(KRobotHeadState.listening).roll, 0.17);
    expect(restPose(KRobotHeadState.working).pitch, -0.16);
    expect(restPose(KRobotHeadState.happy).roll, 0.06);
    expect(restPose(KRobotHeadState.error).pitch, -0.06);
    expect(restPose(KRobotHeadState.sleeping).pitch, -0.34);
    expect(restPose(KRobotHeadState.speaking).yaw, -0.18);
  });

  test('shape geometry and mesh data match JavaScript fixtures', () {
    const expected = <KRobotHeadShape, List<double>>{
      KRobotHeadShape.rectangle: [
        0.21,
        0.6,
        0.5,
        0.38,
        0.030685714285714285,
        0.491999999999818,
        -0.272,
        3960,
        5040,
        3780,
        11.480844780802727,
        3.0954597778618336,
      ],
      KRobotHeadShape.square: [
        0.2,
        0.6,
        0.42000000000000004,
        0.42000000000000004,
        0.023828571428571428,
        0.41199999999956344,
        -0.266,
        3960,
        5040,
        3780,
        12.345386296510696,
        3.0954597778618336,
      ],
      KRobotHeadShape.circle: [
        0.46,
        0.56,
        0.46,
        0.46,
        0.02725714285714286,
        0.4510206967011183,
        -0.2838862515128219,
        3696,
        4704,
        3528,
        4.983095780014992,
        2.9039928978309035,
      ],
      KRobotHeadShape.hexagon: [
        0.16,
        0.58,
        0.51,
        0.4631088913245536,
        0.03154285714285714,
        0.49916233645480323,
        -0.28708776665906754,
        4356,
        5544,
        4158,
        9.884605472907424,
        0,
      ],
    };

    for (final name in KRobotHeadShape.values) {
      final shape = getShape(name);
      final body = headMeshes(shape).body;
      final positionChecksum = body.pos.indexed.fold(
        0.0,
        (sum, entry) => sum + entry.$2 * (entry.$1 % 17 + 1),
      );
      final normalChecksum = body.normals.indexed.fold(
        0.0,
        (sum, entry) => sum + entry.$2 * (entry.$1 % 11 + 1),
      );
      expect(
        [
          shape.r,
          shape.depth,
          shape.hx,
          shape.hy,
          shape.pitch,
          shape.earX,
          shape.sd(0.123, -0.077, 0.031),
          body.pos.length.toDouble(),
          body.quads.length.toDouble(),
          body.normals.length.toDouble(),
          positionChecksum,
          normalChecksum,
        ],
        closeList(expected[name]!, 1e-9),
        reason: name.name,
      );
    }

    final matrix = rotation(0.31, -0.27, 0.19);
    expect(
      matrix,
      closeList(const [
        0.9351955988721194,
        -0.2619211423664637,
        0.23834115681447976,
        0.1798566656576418,
        0.9310598937879242,
        0.31745716876160557,
        -0.3050586364434435,
        -0.25401730130261974,
        0.9178313782880825,
      ], 1e-12),
    );
    final rotated = rotate(matrix, 0.2, -0.4, 0.7);
    expect(
      [rotated.x, rotated.y, rotated.z],
      closeList(const [
        0.4586463864911452,
        -0.11423260625051748,
        0.6830771580340168,
      ], 1e-12),
    );
  });

  test('linear lighting matches JavaScript fixtures', () {
    final albedo = linear(const [43, 73, 163]);
    expect(
      [keyLight.x, keyLight.y, keyLight.z, albedo.x, albedo.y, albedo.z],
      closeList(const [
        -0.44850716155042747,
        -0.6996711720186669,
        0.5561488803225301,
        0.01991783843878572,
        0.06381487094867724,
        0.373615024646202,
      ], 1e-12),
    );
    final material = Material(
      albedo: albedo,
      f0: 0.07,
      metal: 0.15,
      spec: 0.4,
      shininess: 24,
      rim: 0.3,
    );
    const fixtures = [
      [
        0.0,
        0.0,
        1.0,
        0.04081272810245634,
        0.08051406155135483,
        0.3607033705141859,
        0.09230322616723541,
      ],
      [
        -0.4,
        -0.7,
        0.591607978,
        0.09858245341360053,
        0.15758065067550897,
        0.5739561898534143,
        0.17509994786627198,
      ],
      [
        0.8,
        0.1,
        0.591607978,
        0.009894282518599638,
        0.021527017513060645,
        0.10361801126847903,
        0.02498086780237944,
      ],
      [
        -0.9,
        0.3,
        0.316227766,
        0.02066877909692249,
        0.04507524469223693,
        0.21732212244958826,
        0.052322654680753845,
      ],
    ];
    for (final fixture in fixtures) {
      final value = radiance(material, fixture[0], fixture[1], fixture[2]);
      expect([
        value.x,
        value.y,
        value.z,
        luma(value),
      ], closeList(fixture.sublist(3), 1e-12));
    }
  });
}
