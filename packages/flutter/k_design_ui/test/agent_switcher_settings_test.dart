import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

void main() {
  testWidgets(
    'settings controls and drag handles work in an unbounded column',
    (tester) async {
      List<String>? order;
      bool? pinned;
      await tester.pumpWidget(
        MaterialApp(
          theme: kDesignTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  KAgentSwitcher(
                    settings: true,
                    selectedId: null,
                    onSelect: (_) =>
                        fail('Settings control must not select an agent'),
                    onReorder: (ids) => order = ids,
                    items: [
                      KAgentSwitcherItem(
                        id: 'a',
                        name: 'Ada',
                        avatar: const Text('Configured avatar'),
                        controlContent: KSwitch(
                          label: 'Pin Ada',
                          value: true,
                          onChanged: (value) => pinned = value,
                        ),
                      ),
                      const KAgentSwitcherItem(id: 'b', name: 'Ben'),
                      const KAgentSwitcherItem(
                        id: 'c',
                        name: 'Unpinned',
                        reorderable: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Configured avatar'), findsOneWidget);
      await tester.tap(find.byType(KSwitch));
      expect(pinned, false);
      final handles = find.byType(IconButton);
      expect(handles, findsNWidgets(3));
      expect(tester.widget<IconButton>(handles.at(2)).onPressed, isNull);
      final handleIcon = find.descendant(
        of: handles.at(0),
        matching: find.byType(KIcon),
      );
      final handleFocus = Focus.of(tester.element(handleIcon));
      handleFocus.requestFocus();
      await tester.pump();
      expect(handleFocus.hasFocus, isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      expect(order, ['b', 'a', 'c']);
      order = null;
      final list = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      list.onReorderItem!(0, 2);
      expect(order, ['b', 'a', 'c']);
    },
  );
}
