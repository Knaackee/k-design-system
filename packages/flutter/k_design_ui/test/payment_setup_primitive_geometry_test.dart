import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('badge and normal disclosure retain Web content-box geometry', (
    tester,
  ) async {
    for (final density in KDensity.values) {
      for (final inputMode in KInputMode.values) {
        for (final scale in [1.0, 2.0]) {
          final theme = kDesignTheme(
            configuration: KDesignConfiguration(
              density: density,
              inputMode: inputMode,
            ),
          );
          final t = theme.extension<KDesignTokens>()!;
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const Scaffold(
                  body: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KBadge(
                        key: ValueKey('badge'),
                        variant: KBadgeVariant.outline,
                        child: Text('Test mode'),
                      ),
                      KDisclosure(
                        key: ValueKey('normal'),
                        title: 'Test help',
                        child: Text('Help'),
                      ),
                      KDisclosure(
                        key: ValueKey('compact'),
                        title: 'Compact help',
                        presentation: KDisclosurePresentation.compact,
                        child: Text('Help'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          // CSS .k-badge: min-height is the content box and line-height is 1.
          final badgeHeight =
              math.max(t.componentBadgeMinHeight, t.fontCaptionSize * scale) +
              2 * t.componentBadgePaddingBlock +
              2 * t.borderWidthDefault;
          expect(
            tester.getSize(find.byKey(const ValueKey('badge'))).height,
            closeTo(badgeHeight, .01),
            reason: '$density $inputMode $scale',
          );
          // CSS .k-disclosure: its border sits outside the hit-target header.
          final headerHeight = math.max(
            t.sizeHitTarget,
            t.fontBodyLineHeight * scale + 2 * t.spaceControlGap,
          );
          expect(
            tester.getSize(find.byKey(const ValueKey('normal'))).height,
            closeTo(headerHeight + 2 * t.borderWidthDefault, .01),
          );
          expect(
            tester.getSize(find.byKey(const ValueKey('compact'))).height,
            closeTo(headerHeight, .01),
          );
          expect(tester.takeException(), isNull);
        }
      }
    }
  });
}
