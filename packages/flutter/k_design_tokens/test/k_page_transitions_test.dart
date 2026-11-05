import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, {Widget? second}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme().copyWith(platform: TargetPlatform.iOS),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        second ??
                        const Scaffold(body: Center(child: Text('Detail'))),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a swipe from the middle of the content goes back (iOS 26)', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Detail'), findsOneWidget);
    await tester.timedDragFrom(
      const Offset(400, 300),
      const Offset(300, 0),
      const Duration(milliseconds: 200),
    );
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('the leading edge still goes back', (tester) async {
    await pumpApp(tester);
    await tester.timedDragFrom(
      const Offset(5, 300),
      const Offset(400, 0),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsNothing);
  });

  testWidgets('a short slow drag springs back and stays', (tester) async {
    await pumpApp(tester);
    await tester.timedDragFrom(
      const Offset(400, 300),
      const Offset(60, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);
  });

  testWidgets('horizontal content keeps its own gesture', (tester) async {
    await pumpApp(
      tester,
      second: Scaffold(
        body: PageView(children: const [Text('Page A'), Text('Page B')]),
      ),
    );
    await tester.timedDragFrom(
      const Offset(400, 300),
      const Offset(-300, 0),
      const Duration(milliseconds: 200),
    );
    await tester.pumpAndSettle();
    expect(find.text('Page B'), findsOneWidget);
    // Swiping right on content that scrolls back pages back, not away.
    await tester.timedDragFrom(
      const Offset(400, 300),
      const Offset(300, 0),
      const Duration(milliseconds: 200),
    );
    await tester.pumpAndSettle();
    expect(find.text('Page A'), findsOneWidget);
  });

  testWidgets('PopScope(canPop: false) blocks the swipe', (tester) async {
    await pumpApp(
      tester,
      second: const PopScope(
        canPop: false,
        child: Scaffold(body: Center(child: Text('Dirty form'))),
      ),
    );
    await tester.timedDragFrom(
      const Offset(400, 300),
      const Offset(300, 0),
      const Duration(milliseconds: 200),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dirty form'), findsOneWidget);
  });
}
