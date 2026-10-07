import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

const _baseItems = [
  KAgentSwitcherItem(
    id: 'ada',
    name: 'Ada',
    connection: KAgentConnection.online,
    activity: KAgentActivityState.working,
    unread: 3,
  ),
  KAgentSwitcherItem(
    id: 'linus',
    name: 'Linus',
    connection: KAgentConnection.sleeping,
    activity: KAgentActivityState.idle,
  ),
  KAgentSwitcherItem(
    id: 'mira',
    name: 'Mira',
    connection: KAgentConnection.unknown,
    activity: KAgentActivityState.needsInput,
  ),
];

const _overflowItems = [
  KAgentSwitcherItem(id: 'nova', name: 'Nova'),
  KAgentSwitcherItem(id: 'atlas', name: 'Atlas'),
  KAgentSwitcherItem(id: 'echo', name: 'Echo'),
  KAgentSwitcherItem(id: 'sage', name: 'Sage'),
  KAgentSwitcherItem(id: 'pixel', name: 'Pixel'),
  KAgentSwitcherItem(id: 'lumen', name: 'Lumen'),
  KAgentSwitcherItem(id: 'orbit', name: 'Orbit'),
  KAgentSwitcherItem(id: 'quill', name: 'Quill'),
  KAgentSwitcherItem(id: 'wren', name: 'Wren'),
  KAgentSwitcherItem(id: 'iris', name: 'Iris'),
  KAgentSwitcherItem(id: 'sol', name: 'Sol'),
  KAgentSwitcherItem(id: 'moss', name: 'Moss'),
  KAgentSwitcherItem(id: 'coda', name: 'Coda'),
  KAgentSwitcherItem(id: 'finn', name: 'Finn'),
];

Widget _frame({
  List<KAgentSwitcherItem> items = _baseItems,
  String? selectedId = 'ada',
  ValueChanged<String>? onSelect,
  VoidCallback? onManage,
  ValueChanged<List<String>>? onReorder,
  ValueChanged<String>? onLongPress,
}) => MaterialApp(
  theme: kDesignTheme(),
  home: Scaffold(
    body: KAgentSwitcher(
      items: items,
      selectedId: selectedId,
      onSelect: onSelect ?? (_) {},
      onManage: onManage,
      onReorder: onReorder,
      onLongPress: onLongPress,
    ),
  ),
);

void main() {
  testWidgets('reports selection without changing controlled state', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(_frame(onSelect: (id) => selected = id));

    await tester.tap(find.text('Mira'));

    expect(selected, 'mira');
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('k-agent-switcher-ada')))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('supports optional and custom item content', (tester) async {
    await tester.pumpWidget(
      _frame(
        selectedId: null,
        items: const [
          KAgentSwitcherItem(
            id: 'custom',
            name: 'Custom agent',
            avatar: SizedBox(key: ValueKey('custom-avatar')),
            nameContent: Text('Custom name'),
            statusContent: Text('Custom status'),
            badgeContent: Icon(Icons.star, key: ValueKey('custom-badge')),
            semanticLabel: 'Custom agent status',
            showName: false,
          ),
        ],
      ),
    );

    expect(find.byKey(const ValueKey('custom-avatar')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-badge')), findsOneWidget);
    expect(find.text('Custom name'), findsNothing);
    expect(find.text('Custom status'), findsOneWidget);
    expect(find.bySemanticsLabel('Custom agent status'), findsOneWidget);
  });

  testWidgets('handles empty items and standalone long press', (tester) async {
    await tester.pumpWidget(_frame(items: const [], selectedId: null));
    expect(tester.takeException(), isNull);

    String? longPressed;
    await tester.pumpWidget(
      _frame(
        items: const [KAgentSwitcherItem(id: 'solo', name: 'Solo')],
        selectedId: null,
        onLongPress: (id) => longPressed = id,
      ),
    );
    await tester.longPress(find.text('Solo'));
    expect(longPressed, 'solo');
  });

  testWidgets('exposes status, unread, manage, and reorder semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var managed = false;
    await tester.pumpWidget(
      _frame(onManage: () => managed = true, onReorder: (_) {}),
    );

    expect(find.bySemanticsLabel(RegExp('Connection: Online')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Activity: Working')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('3 unread messages')), findsOneWidget);
    final ada = tester.getSemantics(
      find.byKey(const ValueKey('k-agent-switcher-ada')),
    );
    expect(ada.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
    expect(ada.getSemanticsData().hint, contains('Alt'));

    await tester.tap(find.bySemanticsLabel('Agenten auswählen'));
    expect(managed, isTrue);
    semantics.dispose();
  });

  testWidgets('long-press drag reports controlled order without selection', (
    tester,
  ) async {
    List<String>? reordered;
    String? selected;
    String? longPressed;
    await tester.pumpWidget(
      _frame(
        selectedId: null,
        onSelect: (id) => selected = id,
        onLongPress: (id) => longPressed = id,
        onReorder: (ids) => reordered = ids,
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Ada')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(180, 0));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(longPressed, 'ada');
    expect(selected, isNull);
    expect(reordered, isNotNull);
    expect(reordered, isNot(equals(['ada', 'linus', 'mira'])));
  });

  testWidgets('cancelled reorder does not select or report a move', (
    tester,
  ) async {
    List<String>? reordered;
    String? selected;
    await tester.pumpWidget(
      _frame(
        selectedId: null,
        onSelect: (id) => selected = id,
        onReorder: (ids) => reordered = ids,
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Ada')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selected, isNull);
    expect(reordered, isNull);
  });

  testWidgets('keyboard reorder respects boundaries and updates parent order', (
    tester,
  ) async {
    await tester.pumpWidget(const _ControlledReorderFixture());
    final adaText = find.text('Ada');
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    expect(
      tester.getTopLeft(adaText).dx,
      lessThan(tester.getTopLeft(find.text('Linus')).dx),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pump();
    expect(
      tester.getTopLeft(adaText).dx,
      greaterThan(tester.getTopLeft(find.text('Linus')).dx),
    );
  });

  testWidgets('mouse drag pans and vertical wheel scrolls without sorting', (
    tester,
  ) async {
    List<String>? reordered;
    await tester.pumpWidget(
      _frame(
        items: _overflowItems,
        selectedId: null,
        onReorder: (ids) => reordered = ids,
      ),
    );
    final switcher = find.byType(KAgentSwitcher);
    final list = find.byType(ReorderableListView);
    final controller = tester
        .widget<ReorderableListView>(list)
        .scrollController!;
    expect(controller.offset, 0);

    await tester.dragFrom(
      tester.getCenter(switcher),
      const Offset(-120, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(0));
    expect(reordered, isNull);

    final afterDrag = controller.offset;
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(switcher),
        scrollDelta: const Offset(0, 120),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();
    expect(controller.offset, greaterThan(afterDrag));
    expect(reordered, isNull);
  });
}

class _ControlledReorderFixture extends StatefulWidget {
  const _ControlledReorderFixture();

  @override
  State<_ControlledReorderFixture> createState() =>
      _ControlledReorderFixtureState();
}

class _ControlledReorderFixtureState extends State<_ControlledReorderFixture> {
  var _orderedItems = [..._baseItems];

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: kDesignTheme(),
    home: Scaffold(
      body: KAgentSwitcher(
        items: _orderedItems,
        selectedId: null,
        onSelect: (_) {},
        onReorder: (ids) => setState(() {
          final byId = {for (final item in _orderedItems) item.id: item};
          _orderedItems = [for (final id in ids) byId[id]!];
        }),
      ),
    ),
  );
}
