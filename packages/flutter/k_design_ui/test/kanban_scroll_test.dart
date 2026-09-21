import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

void main() {
  testWidgets('board scrolls horizontally with a touch drag', (tester) async {
    final controller = ScrollController();
    await tester.pumpWidget(_fixture(controller));

    await tester.drag(
      find.bySemanticsLabel('Kanban board'),
      const Offset(-180, 0),
      kind: PointerDeviceKind.touch,
    );
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(100));
  });

  testWidgets('card drag auto-scrolls near the right edge', (tester) async {
    final controller = ScrollController();
    await tester.pumpWidget(_fixture(controller));

    final card = find.byKey(const ValueKey('card-item-1'));
    final gesture = await tester.startGesture(
      tester.getCenter(card),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(const Offset(372, 180));
    await tester.pump(const Duration(milliseconds: 320));

    expect(controller.offset, greaterThan(0));

    await gesture.up();
    await tester.pump();
  });
}

Widget _fixture(ScrollController controller) {
  final columns = List.generate(
    4,
    (columnIndex) => KKanbanColumn<String>(
      id: 'column-$columnIndex',
      title: Text('Column $columnIndex'),
      items: ['item-${columnIndex + 1}'],
    ),
  );
  return MaterialApp(
    theme: kDesignTheme(),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 375,
          child: KKanban<String>(
            columns: columns,
            itemId: (item) => item,
            scrollController: controller,
            height: 420,
            onCardMove: (_) {},
            cardBuilder: (context, card) => SizedBox(
              key: ValueKey('card-${card.itemId}'),
              height: 80,
              child: Text(card.item),
            ),
          ),
        ),
      ),
    ),
  );
}
