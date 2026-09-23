import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  Widget fixture(VoidCallback selected) => MaterialApp(
    theme: kDesignTheme(),
    home: Scaffold(
      body: KContextMenu(
        label: 'Document actions',
        actions: [
          KMenuAction(
            id: 'copy',
            label: 'Copy link',
            icon: KIconName.copy,
            onSelect: selected,
          ),
          KMenuAction(
            id: 'move',
            label: 'Move to',
            children: [
              KMenuAction(id: 'orbit', label: 'Orbit', onSelect: selected),
            ],
          ),
          KMenuAction(
            id: 'delete',
            label: 'Delete',
            destructive: true,
            onSelect: selected,
          ),
        ],
        child: const SizedBox(
          key: ValueKey('target'),
          width: 220,
          height: 100,
          child: Text('Project brief'),
        ),
      ),
    ),
  );

  testWidgets('secondary click opens menu and submenu invokes action', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(fixture(() => selected++));
    final point = tester.getCenter(find.byKey(const ValueKey('target')));
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.addPointer(location: point);
    await gesture.down(point);
    await gesture.up();
    await gesture.removePointer();
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsOneWidget);
    await tester.tap(find.text('Move to'));
    await tester.pumpAndSettle();
    expect(find.text('Orbit'), findsOneWidget);
    await tester.tap(find.text('Orbit'));
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  testWidgets('long press opens the same context menu', (tester) async {
    await tester.pumpWidget(fixture(() {}));
    await tester.longPress(find.byKey(const ValueKey('target')));
    await tester.pumpAndSettle();
    expect(find.text('Copy link'), findsOneWidget);
  });

  testWidgets('hovering another root action closes an open submenu', (
    tester,
  ) async {
    await tester.pumpWidget(fixture(() {}));
    final point = tester.getCenter(find.byKey(const ValueKey('target')));
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.addPointer(location: point);
    await gesture.down(point);
    await gesture.up();
    await gesture.removePointer();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to'));
    await tester.pumpAndSettle();
    expect(find.text('Orbit'), findsOneWidget);

    final hover = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await hover.addPointer(location: point);
    await hover.moveTo(tester.getCenter(find.text('Delete')));
    await tester.pumpAndSettle();

    expect(find.text('Orbit'), findsNothing);
  });
}
