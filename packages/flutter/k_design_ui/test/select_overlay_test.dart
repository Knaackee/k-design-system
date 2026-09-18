import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/forms/selection_popup.dart';

void main() {
  for (final top in [40.0, 240.0]) {
    testWidgets('select popup uses shifted nested overlay bounds at $top', (
      tester,
    ) async {
      final entry = OverlayEntry(
        builder: (_) => Positioned(
          left: 30,
          top: top,
          width: 180,
          child: KSelect(
            label: 'Status',
            value: 'active',
            onChanged: (_) {},
            options: const [
              KSelectOption(value: 'active', label: 'Active'),
              KSelectOption(value: 'done', label: 'Done'),
              KSelectOption(value: 'blocked', label: 'Blocked', disabled: true),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 130,
                  top: 90,
                  width: 350,
                  height: 300,
                  child: Overlay(initialEntries: [entry]),
                ),
              ],
            ),
          ),
        ),
      );
      final trigger = tester.getRect(find.byType(KSelect));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      final optionRegions = tester.widgetList<MouseRegion>(
        find.descendant(
          of: find.byType(KSelectionPopup),
          matching: find.byType(MouseRegion),
        ),
      );
      expect(
        optionRegions.where((r) => r.cursor == SystemMouseCursors.click).length,
        2,
      );
      expect(
        optionRegions.where((r) => r.cursor == SystemMouseCursors.basic).length,
        1,
      );
      final popup = tester.getRect(find.byType(KSelectionPopup));
      expect(popup.left, trigger.left);
      expect(popup.width, trigger.width);
      final gap = KDesignTokens.orbitLight.spaceControlGap;
      if (top == 40) {
        expect(popup.top, trigger.bottom + gap);
      } else {
        expect(popup.bottom, trigger.top - gap);
      }
      expect(popup.right, lessThanOrEqualTo(480));
      expect(popup.bottom, lessThanOrEqualTo(390));
      entry.remove();
      await tester.pumpWidget(const SizedBox());
      entry.dispose();
    });
  }
}
