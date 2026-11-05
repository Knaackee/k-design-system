import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

void main() {
  for (final width in [350.0, 200.0]) {
    testWidgets('menu respects shifted overlay width $width', (tester) async {
      final entry = OverlayEntry(
        builder: (_) => Positioned(
          left: 30,
          top: 40,
          child: KMenuButton(
            label: 'Sort',
            actions: [
              KMenuAction(id: 'a', label: 'Name ascending', onSelect: () {}),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 130,
                  top: 90,
                  width: width,
                  height: 300,
                  child: Overlay(initialEntries: [entry]),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Sort'));
      await tester.pumpAndSettle();
      final popup = tester.getRect(find.byType(KSurface));
      expect(popup.width, greaterThanOrEqualTo(width < 256 ? width - 16 : 240));
      expect(popup.width, lessThanOrEqualTo(width - 16));
      expect(popup.left, greaterThanOrEqualTo(138));
      expect(popup.right, lessThanOrEqualTo(130 + width - 8));
      expect(tester.takeException(), isNull);
      entry.remove();
      await tester.pumpWidget(const SizedBox());
      entry.dispose();
    });
  }
}
