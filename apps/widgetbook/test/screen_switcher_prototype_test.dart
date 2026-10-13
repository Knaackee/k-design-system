import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_widgetbook/screen_switcher_prototype.dart';

void main() {
  testWidgets('full screen opens stack, rear selection centers then opens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: const Scaffold(body: ScreenSwitcherPrototypeDemo()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Geöffnete Screens').last);
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.text('Entwurf 2').first));
    await tester.pumpAndSettle();
    expect(find.text('Entwurf 2'), findsWidgets);
    await tester.tap(find.text('Geöffnete Screens').last);
    await tester.pumpAndSettle();
    expect(find.text('Entwürfe · 2 / 8'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('event-only mode centers rear card before requesting open', (
    tester,
  ) async {
    final events = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: ScreenSwitcherPrototype(
            items: List.generate(
              8,
              (i) => ScreenSwitcherItem(
                id: '$i',
                title: 'Card $i',
                preview: const Text('Preview'),
              ),
            ),
            maximizeOnOpen: false,
            onScreenSelected: (id) => events.add('select:$id'),
            onOpenRequested: (id) => events.add('open:$id'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.text('Card 1')));
    expect(events.where((event) => event.startsWith('open:')), isEmpty);
    await tester.pumpAndSettle();
    expect(events, ['select:1', 'open:1']);
    expect(find.byType(PageView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
