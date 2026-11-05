import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  // Decision 0012 / HIG Sheets: swipe down dismisses; with unsaved changes
  // the app asks first through PopScope, for the swipe and for Cancel.
  Future<List<String>> open(WidgetTester tester, {bool dirty = true}) async {
    final attempts = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme().copyWith(platform: TargetPlatform.iOS),
        home: KLocalization(
          locale: 'en',
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => KBottomSheet.show<void>(
                    context: context,
                    title: const Text('Edit'),
                    closeLabel: 'Cancel',
                    child: PopScope(
                      canPop: !dirty,
                      onPopInvokedWithResult: (didPop, _) {
                        if (!didPop) attempts.add('blocked');
                      },
                      child: const SizedBox(height: 300, child: Text('Form')),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return attempts;
  }

  testWidgets('swipe down with unsaved changes is held back', (tester) async {
    final attempts = await open(tester);
    await tester.fling(find.text('Form'), const Offset(0, 500), 2000);
    await tester.pumpAndSettle();
    expect(find.text('Form'), findsOneWidget);
    expect(attempts, isNotEmpty);
  });

  testWidgets('Cancel with unsaved changes is held back', (tester) async {
    final attempts = await open(tester);
    await tester.tap(find.bySemanticsLabel('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Form'), findsOneWidget);
    expect(attempts, isNotEmpty);
  });

  testWidgets('swipe down without unsaved changes closes the sheet', (
    tester,
  ) async {
    await open(tester, dirty: false);
    await tester.fling(find.text('Form'), const Offset(0, 500), 2000);
    await tester.pumpAndSettle();
    expect(find.text('Form'), findsNothing);
  });
}
