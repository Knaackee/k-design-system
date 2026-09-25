import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('avatar menu exposes identity and invokes consumer action once', (
    tester,
  ) async {
    var calls = 0;
    final changes = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: kDesignTheme(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: KUserMenu(
              userName: 'Alex Morgan',
              description: const Text('alex@example.test'),
              onOpenChange: changes.add,
              actions: [
                KMenuAction(
                  id: 'settings',
                  label: 'Settings',
                  onSelect: () => calls++,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('alex@example.test'), findsOneWidget);
    Color? focusBorder() => tester
        .widget<MenuItemButton>(find.byType(MenuItemButton))
        .style!
        .side!
        .resolve({WidgetState.focused})!
        .color;
    expect(focusBorder(), Colors.transparent);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusBorder(), isNot(Colors.transparent));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(0, 500));
    await mouse.moveTo(tester.getCenter(find.text('Settings')));
    await tester.pumpAndSettle();
    expect(focusBorder(), Colors.transparent);
    await mouse.removePointer();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(changes, [true, false]);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets(
    'long identity stays inside narrow viewport and outside dismisses',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: KUserMenu(
                userName: 'Alexandra Morgan-Hernández',
                description: const Text(
                  'alexandra@international-workspace.example',
                ),
                actions: [
                  KMenuAction(
                    id: 'settings',
                    label: 'Settings',
                    onSelect: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final bounds = tester.getRect(find.text('Settings'));
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(320));
      await tester.tapAt(const Offset(10, 600));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsNothing);
    },
  );
}
