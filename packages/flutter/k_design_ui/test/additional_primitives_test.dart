import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    Widget child,
    KDensity density,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(
          configuration: KDesignConfiguration(density: density),
        ),
        home: Align(alignment: Alignment.topLeft, child: child),
      ),
    );
  }

  for (final density in KDensity.values) {
    final tokens = kDesignTokens(
      configuration: KDesignConfiguration(density: density),
    );
    final gap = tokens.spaceLayoutSectionGap;
    for (final width in [
      0.0,
      1.0,
      239.0,
      240.0,
      480 + gap - .01,
      480 + gap,
      480 + gap + .01,
      760.0,
      1024.0,
    ]) {
      testWidgets('grid $density at $width preserves track geometry', (
        tester,
      ) async {
        const heights = [20.0, 40.0, 30.0, 10.0];
        await mount(
          tester,
          SizedBox(
            width: width,
            child: KGrid(
              children: [
                for (var n = 0; n < 4; n++)
                  SizedBox(key: ValueKey(n), height: heights[n]),
              ],
            ),
          ),
          density,
        );
        final cols = math.max(1, ((width + gap) / (240 + gap)).floor());
        final item = (width - (cols - 1) * gap) / cols;
        var top = 0.0;
        for (var start = 0; start < 4; start += cols) {
          final end = math.min(start + cols, 4);
          for (var n = start; n < end; n++) {
            final rect = tester.getRect(find.byKey(ValueKey(n)));
            expect(rect.width, closeTo(item, .001));
            expect(rect.left, closeTo((n - start) * (item + gap), .001));
            expect(rect.top, closeTo(top, .001));
          }
          top += heights.sublist(start, end).reduce(math.max) + gap;
        }
        expect(tester.takeException(), isNull);
      });
    }
    for (final width in [0.0, 1.0, 375.0, 1024.0]) {
      testWidgets('container $density at $width clamps and centers', (
        tester,
      ) async {
        await mount(
          tester,
          SizedBox(
            width: width,
            child: const KContainer(
              child: SizedBox(key: ValueKey('content'), height: 40),
            ),
          ),
          density,
        );
        final rect = tester.getRect(find.byKey(const ValueKey('content')));
        final expected = math.min(
          760.0,
          math.max(0.0, width - 2 * tokens.spaceLayoutGutter),
        );
        expect(rect.width, closeTo(expected, .001));
        expect(rect.left, closeTo((width - expected) / 2, .001));
        expect(rect.height, 40);
      });
    }
  }
  testWidgets('empty grid and partial row retain tracks', (tester) async {
    await mount(
      tester,
      const SizedBox(width: 760, child: KGrid(children: [])),
      KDensity.standard,
    );
    expect(tester.getSize(find.byType(KGrid)), const Size(760, 0));
    await mount(
      tester,
      const SizedBox(
        width: 760,
        child: KGrid(
          gap: KLayoutGap.action,
          children: [SizedBox(key: ValueKey('one'), height: 20)],
        ),
      ),
      KDensity.standard,
    );
    final gap = kDesignTokens().spaceContentActionGap;
    expect(
      tester.getSize(find.byKey(const ValueKey('one'))).width,
      closeTo((760 - 2 * gap) / 3, .001),
    );
  });
  testWidgets('icons retain geometry and accessible labels at 200%', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await mount(
        tester,
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: KInline(
            children: [
              for (final size in [16.0, 24.0, 32.0])
                KIcon(
                  KIconName.check,
                  key: ValueKey(size),
                  size: size,
                  label: 'Check $size',
                ),
              const KIcon(KIconName.info),
            ],
          ),
        ),
        KDensity.standard,
      );
      await tester.pumpAndSettle();
      // Text-adjacent icons grow with the text (2x cap); display icons keep
      // their size (Decision 0015).
      for (final size in [16.0, 24.0, 32.0]) {
        expect(
          tester.getSize(find.byKey(ValueKey(size))),
          Size.square(size <= 24 ? size * 2 : size),
        );
        expect(find.bySemanticsLabel('Check $size'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
  testWidgets('separators use token thickness', (tester) async {
    await mount(
      tester,
      const SizedBox(
        width: 300,
        child: KStack(
          children: [
            KSeparator(key: ValueKey('h')),
            KSeparator(
              key: ValueKey('v'),
              orientation: KSeparatorOrientation.vertical,
              length: 48,
            ),
          ],
        ),
      ),
      KDensity.standard,
    );
    final stroke = kDesignTokens().borderWidthDefault;
    expect(tester.getSize(find.byKey(const ValueKey('h'))), Size(300, stroke));
    expect(tester.getSize(find.byKey(const ValueKey('v'))), Size(stroke, 48));
  });
  for (final columns in [1, 2, 3, 6]) {
    for (final gap in KLayoutGap.values) {
      testWidgets('explicit $columns columns with $gap', (tester) async {
        final tokens = kDesignTokens();
        final spacing = switch (gap) {
          KLayoutGap.control => tokens.spaceControlGap,
          KLayoutGap.action => tokens.spaceContentActionGap,
          KLayoutGap.section => tokens.spaceLayoutSectionGap,
        };
        await mount(
          tester,
          SizedBox(
            width: 760,
            child: KGrid(
              columns: columns,
              gap: gap,
              children: [
                for (var n = 0; n < 7; n++)
                  SizedBox(key: ValueKey(n), height: 20),
              ],
            ),
          ),
          KDensity.standard,
        );
        final item = (760 - (columns - 1) * spacing) / columns;
        for (var n = 0; n < 7; n++) {
          final rect = tester.getRect(find.byKey(ValueKey(n)));
          expect(rect.width, closeTo(item, .001));
          expect(rect.left, closeTo((n % columns) * (item + spacing), .001));
          expect(rect.top, closeTo((n ~/ columns) * (20 + spacing), .001));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('invalid dimensions are rejected', (tester) async {
    for (final child in [
      const KContainer(maxWidth: 0, child: SizedBox()),
      const KGrid(minColumnWidth: 0, children: []),
      const KGrid(columns: 0, children: []),
      const KIcon(KIconName.check, size: double.infinity),
      const KSeparator(length: -1),
    ]) {
      await mount(tester, child, KDensity.standard);
      expect(tester.takeException(), isArgumentError);
    }
  });
}
