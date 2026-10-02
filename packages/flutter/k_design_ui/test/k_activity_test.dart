import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('Phone months retain six columns and reachable 44dp days', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [320.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 900);
      for (final month in [
        DateTime(2027, 2),
        DateTime(2026, 10),
        DateTime(2026, 11),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: kDesignTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: KActivityHeatmap(
                    key: ValueKey('$width-$month'),
                    phone: true,
                    today: month,
                    mode: KActivityMode.upcoming,
                    items: const [],
                    onOpenItem: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // Three months, each with six complete week columns, including blanks.
        expect(
          find.byWidgetPredicate(
            (w) => w is SizedBox && w.width == 44 && w.height == 44,
          ),
          findsNWidgets(126),
        );
        if (month.month == 11) {
          final lastDay = find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label == '30. November 2026: 0 Issues',
          );
          await tester.ensureVisible(lastDay);
          await tester.pumpAndSettle();
          final rect = tester.getRect(lastDay);
          expect(rect.width, 44);
          expect(rect.right, lessThanOrEqualTo(width - 16));
          expect(rect.left, greaterThanOrEqualTo(0));
        }
        expect(tester.takeException(), isNull);
      }
    }
  });
  testWidgets('Phone has 44dp days, month loading and consumer navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: KActivityHeatmap(
                phone: true,
                today: DateTime.utc(2026, 10, 2),
                mode: KActivityMode.upcoming,
                items: [
                  KActivityItem(
                    id: 'one',
                    title: 'Consumer item',
                    date: DateTime(2026, 10, 2, 16),
                  ),
                ],
                onOpenItem: (id) => opened = id,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Oktober 2026'), findsOneWidget);
    expect(find.text('Consumer item'), findsNothing);
    final day = find.byWidgetPredicate(
      (w) =>
          w is Semantics && w.properties.label == '2. Oktober 2026: 1 Issues',
    );
    expect(tester.getSize(day), const Size(44, 44));
    await tester.ensureVisible(day);
    await tester.tap(day);
    await tester.pumpAndSettle();
    expect(find.byType(KBottomSheet), findsOneWidget);
    await tester.tap(find.text('Consumer item'));
    await tester.pumpAndSettle();
    expect(opened, 'one');
    expect(find.byType(KBottomSheet), findsNothing);
    await tester.ensureVisible(find.text('Frühere Monate laden'));
    await tester.tap(find.text('Frühere Monate laden'));
    await tester.pumpAndSettle();
    expect(find.text('Juli 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Desktop shows only selected day and retains out-of-range counts',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: KActivityHeatmap(
                today: DateTime.utc(2026, 10, 2),
                mode: KActivityMode.upcoming,
                items: [
                  KActivityItem(
                    id: 'past',
                    title: 'Past item',
                    date: DateTime.utc(2026, 9, 30),
                  ),
                  KActivityItem(
                    id: 'future',
                    title: 'Future item',
                    date: DateTime.utc(2026, 10, 3),
                  ),
                ],
                onOpenItem: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final day = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label == '30. September 2026: 1 Issues',
      );
      await tester.tap(day);
      await tester.pumpAndSettle();
      expect(find.text('Past item'), findsOneWidget);
      expect(find.text('Future item'), findsNothing);
      expect(find.byType(KBottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
