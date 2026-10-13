import 'dart:convert';
import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/data_display/k_dicebear_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('widget renders and updates individual options', (tester) async {
    Object? failure;
    Future<void> show(Map<String, Object?> options) async {
      await tester.runAsync(() async {
        await renderKDiceBearAvatarSvg(
          styleId: 'adventurer',
          seed: 'widget-test',
          options: options,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Center(
              child: KDiceBearAvatar(
                styleId: 'adventurer',
                seed: 'widget-test',
                alt: 'Test avatar',
                options: options,
                errorBuilder: (_, error, _) {
                  failure = error;
                  return const Text('Error');
                },
              ),
            ),
          ),
        );
      });
      await tester.pumpAndSettle();
      expect(failure, isNull);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await show({
      'mouthVariant': ['variant01'],
    });
    final first = tester
        .widget<SvgPicture>(find.byType(SvgPicture))
        .bytesLoader;
    await show({
      'mouthVariant': ['variant02'],
    });
    final second = tester
        .widget<SvgPicture>(find.byType(SvgPicture))
        .bytesLoader;
    expect(second, isNot(first));
  });

  final parity =
      (jsonDecode(
                File(
                  'test/fixtures/dicebear-svg-parity.json',
                ).readAsStringSync(),
              )
              as Map)
          .cast<String, Object?>();
  final defaultSvgs = (parity['defaults'] as Map).cast<String, Object?>();

  test('approved catalogue matches all JS 10.7 default SVG fixtures', () async {
    expect(kDiceBearStyleIds, hasLength(57));
    expect(kDiceBearStyleIds.toSet(), hasLength(57));
    expect(defaultSvgs.keys, orderedEquals(kDiceBearStyleIds));

    final licenses = <String, int>{};
    final stylesUsingUnsupportedFilters = <String>[];
    for (final styleId in kDiceBearStyleIds) {
      expect(styleId, isNot(matches(RegExp(r'^(avataaars|bottts)'))));
      final style = await loadKDiceBearStyle(styleId);
      final license = style.meta.license().name();
      expect(license, isNotNull, reason: styleId);
      licenses.update(license!, (count) => count + 1, ifAbsent: () => 1);
      expect(style.meta.creator().name(), isNotEmpty, reason: styleId);
      expect(style.meta.source().url(), isNotEmpty, reason: styleId);
      expect(style.meta.license().url(), isNotEmpty, reason: styleId);
      if (license == 'CC BY 4.0' || license == 'MIT') {
        expect(style.meta.license().text(), isNotEmpty, reason: styleId);
      }

      final rendered = await renderKDiceBearAvatarSvg(
        styleId: styleId,
        seed: parity['seed']! as String,
      );
      expect(rendered, defaultSvgs[styleId], reason: styleId);
      if (rendered.contains('<filter')) {
        stylesUsingUnsupportedFilters.add(styleId);
      }
      expect(
        (await SvgStringLoader(rendered).loadBytes(null)).lengthInBytes,
        greaterThan(0),
        reason: '$styleId must decode through flutter_svg',
      );
      expect(identical(await loadKDiceBearStyle(styleId), style), isTrue);
    }

    expect(licenses, {'CC BY 4.0': 14, 'CC0 1.0': 42, 'MIT': 1});
    expect(stylesUsingUnsupportedFilters, ['glass', 'marbles']);
  });

  test('mouth, hair and eye choices match independent JS fixtures', () async {
    final variants = (parity['adventurerVariants'] as Map)
        .cast<String, Object?>();
    for (final part in ['mouth', 'hair', 'eyes']) {
      final fixture = (variants[part] as Map).cast<String, Object?>();
      final choices = (fixture['choices'] as List).cast<String>();
      final expected = (fixture['svgs'] as List).cast<String>();
      final actual = <String>[];
      for (final choice in choices) {
        actual.add(
          await renderKDiceBearAvatarSvg(
            styleId: 'adventurer',
            seed: 'same-person',
            options: {
              '${part}Variant': [choice],
              '${part}Probability': 100,
            },
          ),
        );
      }
      expect(actual, expected, reason: part);
      expect(actual.first, isNot(actual.last), reason: part);
    }
  });

  test('option schema is complete and unsupported styles fail', () async {
    final descriptor = await getKDiceBearOptions('adventurer');
    expect(descriptor['seed'], {'type': 'string'});
    expect(descriptor['mouthVariant'], isA<Map<String, Object?>>());
    await expectLater(
      loadKDiceBearStyle('avataaars'),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      loadKDiceBearStyle('toString'),
      throwsA(isA<ArgumentError>()),
    );
  });

  const animatedStyles = [
    'blobs',
    'clay',
    'constellation',
    'critters',
    'gaze',
    'glass',
    'initial-face',
    'landscape',
    'loops',
    'moods',
    'pixelbot',
    'planets',
    'shapes',
    'sprouts',
    'squircles',
    'thumbs',
    'voxel-art',
    'voxel-bot',
    'waves',
  ];

  test('native motion scene compiles every animated style', () async {
    for (final styleId in animatedStyles) {
      final svg = await renderKDiceBearAvatarSvg(
        styleId: styleId,
        seed: 'motion-test',
        options: const {
          'animationVariant': ['medium'],
        },
      );
      final scene = KDiceBearMotionScene.parse(svg);
      expect(scene.isAnimated, isTrue, reason: styleId);
      expect(scene.animations, isNotEmpty, reason: styleId);
    }
  });

  testWidgets('every animated style builds native SVG layers', (tester) async {
    for (final styleId in animatedStyles) {
      late KDiceBearMotionScene scene;
      await tester.runAsync(() async {
        scene = KDiceBearMotionScene.parse(
          await renderKDiceBearAvatarSvg(
            styleId: styleId,
            seed: 'motion-test',
            options: const {
              'animationVariant': ['medium'],
            },
          ),
        );
      });
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.square(
            dimension: 100,
            child: KDiceBearMotion(scene: scene, paused: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: styleId);
      expect(find.byType(SvgPicture), findsWidgets, reason: styleId);
      expect(find.byType(Transform), findsWidgets, reason: styleId);
      if (styleId == 'waves') {
        for (final picture in tester.widgetList<SvgPicture>(
          find.byType(SvgPicture),
        )) {
          expect(picture.allowDrawingOutsideViewBox, isTrue);
          final source = (picture.bytesLoader as SvgStringLoader).provideSvg(
            null,
          );
          expect(
            source,
            isNot(matches(RegExp(r'<g[^>]*clip-path="url\(#clip-'))),
            reason:
                'The viewport must clip after motion, not inside each layer',
          );
        }
      }
    }
  });

  test('opacity animation overrides an invisible SVG base value', () async {
    final scene = KDiceBearMotionScene.parse(
      await renderKDiceBearAvatarSvg(
        styleId: 'voxel-art',
        seed: 'opacity-coverage',
        options: const {
          'animationVariant': ['medium'],
        },
      ),
    );
    final blink = scene.animations.singleWhere(
      (animation) => animation.name == 'va-blink',
    );

    expect(blink.evaluate(0, baseOpacity: 0).opacity, 0);
    expect(
      blink.evaluate(blink.durationSeconds * .96, baseOpacity: 0).opacity,
      1,
    );
  });

  test(
    'positive animation delay keeps the underlying value until it elapses',
    () async {
      final scene = KDiceBearMotionScene.parse(
        await renderKDiceBearAvatarSvg(
          styleId: 'planets',
          seed: 'delay-coverage',
          options: const {
            'animationVariant': ['medium'],
          },
        ),
      );
      final delayedTwinkle = scene.animations.firstWhere(
        (animation) => animation.name == 'dbpaTw' && animation.delaySeconds > 0,
      );

      expect(
        delayedTwinkle
            .evaluate(delayedTwinkle.delaySeconds / 2, baseOpacity: 1)
            .opacity,
        1,
      );
      expect(
        delayedTwinkle
            .evaluate(
              delayedTwinkle.delaySeconds + delayedTwinkle.durationSeconds / 2,
              baseOpacity: 1,
            )
            .opacity,
        closeTo(.3, .0001),
      );
    },
  );

  testWidgets('native motion advances and motionPaused freezes it', (
    tester,
  ) async {
    Future<List<Matrix4>> show({
      required bool paused,
      bool disableAnimations = false,
      bool tickerEnabled = true,
    }) async {
      await tester.runAsync(() async {
        await renderKDiceBearAvatarSvg(
          styleId: 'shapes',
          seed: 'motion-widget',
          options: const {
            'animationVariant': ['medium'],
          },
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Center(
            child: MediaQuery(
              data: MediaQueryData(disableAnimations: disableAnimations),
              child: TickerMode(
                enabled: tickerEnabled,
                child: KDiceBearAvatar(
                  styleId: 'shapes',
                  seed: 'motion-widget',
                  alt: 'Animated avatar',
                  motionPaused: paused,
                  options: const {
                    'animationVariant': ['medium'],
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      final motion = find.byType(KDiceBearMotion);
      expect(motion, findsOneWidget);
      return tester
          .widgetList<Transform>(
            find.descendant(of: motion, matching: find.byType(Transform)),
          )
          .map((widget) => widget.transform.clone())
          .toList();
    }

    final runningStart = await show(paused: false);
    await tester.pump(const Duration(seconds: 4));
    final runningEnd = tester
        .widgetList<Transform>(find.byType(Transform))
        .map((widget) => widget.transform)
        .toList();
    expect(
      runningEnd.map((matrix) => matrix.storage).toList(),
      isNot(runningStart.map((matrix) => matrix.storage).toList()),
    );

    final pausedStart = await show(paused: true);
    await tester.pump(const Duration(seconds: 4));
    final pausedEnd = tester
        .widgetList<Transform>(find.byType(Transform))
        .map((widget) => widget.transform.storage.toList())
        .toList();
    expect(
      pausedEnd,
      pausedStart.map((matrix) => matrix.storage.toList()).toList(),
    );

    final reducedStart = await show(paused: false, disableAnimations: true);
    await tester.pump(const Duration(seconds: 4));
    final reducedEnd = tester
        .widgetList<Transform>(find.byType(Transform))
        .map((widget) => widget.transform.storage.toList())
        .toList();
    expect(
      reducedEnd,
      reducedStart.map((matrix) => matrix.storage.toList()).toList(),
    );

    final tickerMutedStart = await show(paused: false, tickerEnabled: false);
    await tester.pump(const Duration(seconds: 4));
    final tickerMutedEnd = tester
        .widgetList<Transform>(find.byType(Transform))
        .map((widget) => widget.transform.storage.toList())
        .toList();
    expect(
      tickerMutedEnd,
      tickerMutedStart.map((matrix) => matrix.storage.toList()).toList(),
    );
  });
}
