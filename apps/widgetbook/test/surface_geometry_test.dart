import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_widgetbook/foundation_fixtures.dart';

void main() {
  for (final width in [375.0, 1024.0]) {
    for (final density in KDensity.values) {
      testWidgets('surface frame $width / ${density.name}', (tester) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final config = KDesignConfiguration(
          density: density,
          windowClass: kWindowClassForWidth(width),
        );
        final tokens = kDesignTokens(configuration: config);
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(configuration: config),
            home: const Builder(builder: buildSurfaceTones),
          ),
        );
        final surfaces = find.byType(KSurface);
        final a = tester.getRect(surfaces.at(0));
        final b = tester.getRect(surfaces.at(1));
        final c = tester.getRect(surfaces.at(2));
        final columns = width < 600 ? 1 : 2;
        final expected =
            (math.min(760, width - 2 * tokens.spaceLayoutGutter) -
                (columns - 1) * tokens.spaceLayoutSectionGap) /
            columns;
        expect(a.width, closeTo(expected, .5));
        expect(b.width, a.width);
        expect(c.width, a.width);
        expect(
          columns == 1 ? b.top - a.bottom : b.left - a.right,
          closeTo(tokens.spaceLayoutSectionGap, .5),
        );
        final heading = tester.getRect(find.text('Canvas'));
        final body = tester.getRect(find.text('Application background'));
        expect(body.top - heading.bottom, closeTo(tokens.spaceControlGap, .5));
        expect(
          heading.left - a.left,
          closeTo(tokens.spaceCardPadding + tokens.borderWidthDefault, .5),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
