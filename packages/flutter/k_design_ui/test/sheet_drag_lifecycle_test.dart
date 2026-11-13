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

  testWidgets('a confirmation above the sheet lets its drag settle back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('Open'),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                enableDrag: false,
                builder: (sheetContext) => KSheetDrag(
                  onDismiss: () => showDialog<void>(
                    context: sheetContext,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Discard draft?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Keep editing'),
                        ),
                      ],
                    ),
                  ),
                  child: const SizedBox(
                    height: 600,
                    child: SingleChildScrollView(
                      child: SizedBox(height: 900, child: Text('Draft body')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.text('Draft body'));
    for (var attempt = 0; attempt < 2; attempt++) {
      await tester.fling(find.text('Draft body'), const Offset(0, 400), 1500);
      await tester.pumpAndSettle();
      expect(find.text('Discard draft?'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Draft body')), before);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
    }
  });
}
