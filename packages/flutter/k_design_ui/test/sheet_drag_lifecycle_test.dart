import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  Widget surface({required bool enabled}) => MaterialApp(
    theme: ThemeData(extensions: const [KDesignTokens.orbitLight]),
    home: Scaffold(
      body: KSheetDrag(
        enabled: enabled,
        child: const SizedBox(width: 240, height: 240, child: Text('Sheet')),
      ),
    ),
  );

  for (final enabled in [false, true]) {
    testWidgets('disposes an untouched sheet when enabled=$enabled', (
      tester,
    ) async {
      await tester.pumpWidget(surface(enabled: enabled));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('enabling and disabling dragging keeps one owned controller', (
    tester,
  ) async {
    await tester.pumpWidget(surface(enabled: false));
    await tester.pumpWidget(surface(enabled: true));
    await tester.drag(find.text('Sheet'), const Offset(0, 24));
    await tester.pumpAndSettle();
    await tester.pumpWidget(surface(enabled: false));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
