import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

void main() {
  KDesignTokens tokensFor(KMotionStyle motion) =>
      kDesignTokens(configuration: KDesignConfiguration(motion: motion));

  test('apple is the default motion style', () {
    expect(const KDesignConfiguration().motion, KMotionStyle.apple);
    final enter = KDesignTokens.orbitLight.motion(KMotionRole.enter);
    expect(enter.duration, const Duration(milliseconds: 500));
    expect(enter.bounce, 0);
  });

  test('expressive bounces on spatial roles, never on exit', () {
    final tokens = tokensFor(KMotionStyle.expressive);
    expect(tokens.motion(KMotionRole.control).bounce, greaterThan(0));
    expect(tokens.motion(KMotionRole.exit).bounce, 0);
  });

  test('reduced has no movement and no bounce', () {
    final tokens = tokensFor(KMotionStyle.reduced);
    for (final role in KMotionRole.values) {
      expect(tokens.motion(role).distance, 0, reason: role.name);
      expect(tokens.motion(role).bounce, 0, reason: role.name);
    }
  });

  test('the platform reduce-motion setting wins over the app style', () {
    final configuration = resolveKAdaptiveConfiguration(
      width: 393,
      platform: TargetPlatform.iOS,
      overrides: const KAdaptiveOverrides(motion: KMotionStyle.expressive),
      reduceMotion: true,
    );
    expect(configuration.motion, KMotionStyle.reduced);
  });

  test('settle time matches the Web linear() easing (generate-tokens)', () {
    // Same values as tooling/generate-tokens.test.mjs.
    const enter = KMotionSpec(
      duration: Duration(milliseconds: 500),
      bounce: 0,
      distance: 1,
    );
    const control = KMotionSpec(
      duration: Duration(milliseconds: 220),
      bounce: 0.4,
      distance: 1,
    );
    expect(enter.settle.inMilliseconds, closeTo(736, 2));
    expect(control.settle.inMilliseconds, closeTo(356, 2));
    expect(enter.curve.transform(0), 0);
    expect(enter.curve.transform(1), closeTo(1, 0.002));
    expect(control.curve.transform(0.4), greaterThan(1));
  });

  testWidgets('an app-chosen reduced style disables animations below', (
    tester,
  ) async {
    late bool disabled;
    await tester.pumpWidget(
      MaterialApp(
        home: KAdaptiveTheme(
          overrides: const KAdaptiveOverrides(motion: KMotionStyle.reduced),
          child: Builder(
            builder: (context) {
              disabled = MediaQuery.disableAnimationsOf(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    expect(disabled, isTrue);
  });
}
