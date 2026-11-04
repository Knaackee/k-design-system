import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_liquid_glass/k_design_liquid_glass.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

void main() {
  testWidgets('liquid-glass adapter builds a supplied child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => kLiquidGlassSurfaceBuilder(
            context,
            const SizedBox(key: Key('content'), width: 120, height: 48),
            BorderRadius.circular(24),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('content')), findsOneWidget);
  });

  testWidgets('Skia fallback keeps content interactive after resizing', (
    tester,
  ) async {
    // The host widget-test engine has no Impeller shader-filter support. This
    // exercises the actual renderer fallback rather than mocking its widgets.
    expect(ui.ImageFilter.isShaderFilterSupported, isFalse);
    var taps = 0;

    Widget app(double width) => MaterialApp(
      home: Center(
        child: SizedBox(
          width: width,
          height: 80,
          child: Builder(
            builder: (context) => kLiquidGlassSurfaceBuilder(
              context,
              GestureDetector(
                key: const Key('interactive-content'),
                onTap: () => taps++,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
              BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(320));
    await tester.pump();
    expect(find.byType(FakeGlass), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('interactive-content')));

    await tester.pumpWidget(app(200));
    await tester.pump();
    expect(find.byType(FakeGlass), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('interactive-content'))).width,
      200,
    );
    await tester.tap(find.byKey(const Key('interactive-content')));
    expect(taps, 2);
    expect(tester.takeException(), isNull);
  });
}
