import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

const nodes = <KSortableTreeNode<String>>[
  KSortableTreeNode(
    id: 'a',
    label: 'A',
    children: [KSortableTreeNode(id: 'one', label: 'One')],
  ),
  KSortableTreeNode(id: 'b', label: 'B', children: []),
  KSortableTreeNode(id: 'two', label: 'Two'),
];
void main() {
  testWidgets(
    'minimum row height accommodates interactive custom content uniformly',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
          home: Scaffold(
            body: KSortableTree<String>(
              nodes: const [
                KSortableTreeNode(id: 'a', label: 'A'),
                KSortableTreeNode(id: 'b', label: 'B'),
              ],
              minRowHeight: 140,
              onMove: (_) {},
              renderContent: (_, row) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KText(row.node.label),
                  KButton(label: 'Add price', onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final a = tester.getTopLeft(find.text('A'));
      final b = tester.getTopLeft(find.text('B'));
      expect(b.dy - a.dy, 140);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'movement submenu opens on click and selecting its child emits move',
    (tester) async {
      final moves = <KSortableTreeMove>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
          home: Scaffold(
            body: KSortableTree(
              nodes: nodes,
              onMove: moves.add,
              ungroupedLabel: 'Ohne Kategorie',
            ),
          ),
        ),
      );
      await tester.tap(find.byType(KMenuButton).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to'));
      await tester.pumpAndSettle();
      expect(find.byType(SubmenuButton), findsOneWidget);
      expect(find.widgetWithText(MenuItemButton, 'B'), findsOneWidget);
      await tester.tap(find.widgetWithText(MenuItemButton, 'B'));
      await tester.pumpAndSettle();
      expect(moves.single.id, 'one');
      expect(moves.single.parentId, 'b');
      expect(find.text('Move to'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('keyboard drag emits the same controlled move event', (
    tester,
  ) async {
    final moves = <KSortableTreeMove>[];
    const flat = <KSortableTreeNode<String>>[
      KSortableTreeNode(id: 'one', label: 'One'),
      KSortableTreeNode(id: 'two', label: 'Two'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
        home: Scaffold(
          body: KSortableTree(nodes: flat, onMove: moves.add),
        ),
      ),
    );
    Focus.of(tester.element(find.byType(KIconButton).last)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(moves.single.id, 'two');
    expect(moves.single.index, 0);
  });
  test('moves preserve data and validate cycles and root indices', () {
    final next = moveKSortableTree(
      nodes,
      const KSortableTreeMove(id: 'one', parentId: 'b', index: 0),
    );
    expect(next.first.children, isEmpty);
    expect(next[1].children!.single.id, 'one');
    expect(nodes.first.children!.single.id, 'one');
    expect(
      identical(
        moveKSortableTree(
          nodes,
          const KSortableTreeMove(id: 'a', parentId: 'a', index: 0),
        ),
        nodes,
      ),
      isTrue,
    );
    expect(
      identical(
        moveKSortableTree(
          nodes,
          const KSortableTreeMove(id: 'a', parentId: 'one', index: 0),
        ),
        nodes,
      ),
      isTrue,
    );
    expect(
      identical(
        moveKSortableTree(
          nodes,
          const KSortableTreeMove(id: 'one', parentId: null, index: 99),
        ),
        nodes,
      ),
      isTrue,
    );
    expect(
      moveKSortableTree(
        nodes,
        const KSortableTreeMove(id: 'one', parentId: null, index: 3),
      ).last.id,
      'one',
    );
  });
  test('depth limit and duplicate IDs are enforced', () {
    expect(
      identical(
        moveKSortableTree(
          nodes,
          const KSortableTreeMove(id: 'a', parentId: 'b', index: 0),
          maxDepth: 1,
        ),
        nodes,
      ),
      isTrue,
    );
    expect(
      () => flattenKSortableTree([...nodes, nodes.first]),
      throwsArgumentError,
    );
    expect(flattenKSortableTree(nodes, {}).map((e) => e.node.id), [
      'a',
      'b',
      'two',
    ]);
  });
  testWidgets('virtual group toggles without introducing a data node', (
    tester,
  ) async {
    final moves = <KSortableTreeMove>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
        home: Scaffold(
          body: KSortableTree(
            nodes: nodes,
            onMove: moves.add,
            ungroupedLabel: 'Ohne Kategorie',
          ),
        ),
      ),
    );
    expect(find.text('Ohne Kategorie'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    await tester.tap(find.text('Ohne Kategorie'));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsNothing);
    expect(moves, isEmpty);
    await tester.tap(find.text('Ohne Kategorie'));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsOneWidget);
  });
  testWidgets('short handle press toggles container and does not move it', (
    tester,
  ) async {
    final moves = <KSortableTreeMove>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
        home: Scaffold(
          body: KSortableTree(nodes: nodes, onMove: moves.add),
        ),
      ),
    );
    await tester.tap(find.byType(KIconButton).first);
    await tester.pumpAndSettle();
    expect(find.text('One'), findsNothing);
    expect(moves, isEmpty);
  });
  testWidgets(
    'mobile large text and tablet keep uniform rows and support held drag',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final width in [320.0, 900.0]) {
        tester.view.physicalSize = Size(width, 900);
        final moves = <KSortableTreeMove>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [KDesignTokens.orbitDark]),
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: KSortableTree<String>(
                    nodes: nodes,
                    onMove: moves.add,
                    ungroupedLabel: 'Ohne Kategorie',
                    renderContent: (_, c) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KText(
                          c.node.label,
                          variant: KTextVariant.bodySmall,
                          maxLines: 1,
                        ),
                        if (c.node.children == null)
                          const KText('45 Min.', variant: KTextVariant.caption),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final handles = find.byType(KIconButton);
        final gesture = await tester.startGesture(
          tester.getCenter(handles.at(1)),
        );
        await tester.pump(const Duration(milliseconds: 350));
        await gesture.moveTo(tester.getCenter(find.text('B')));
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(moves.single.id, 'one');
        expect(moves.single.parentId, 'b');
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('ungroup destination emits null and foreign drags are rejected', (
    tester,
  ) async {
    final moves = <KSortableTreeMove>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [KDesignTokens.orbitLight]),
        home: Scaffold(
          body: KSortableTree(
            nodes: nodes,
            onMove: moves.add,
            ungroupedLabel: 'Ohne Kategorie',
          ),
        ),
      ),
    );
    final menu = tester
        .widgetList<KMenuButton>(find.byType(KMenuButton))
        .firstWhere((m) => m.label.endsWith(': One'));
    final root = menu.actions
        .firstWhere((a) => a.id == 'move-to')
        .children
        .firstWhere((a) => a.id == 'to-root');
    root.onSelect!();
    expect(moves.single.parentId, isNull);
    expect(moves.single.index, nodes.length);
    for (final target in tester.widgetList<DragTarget<String>>(
      find.byType(DragTarget<String>),
    )) {
      expect(
        target.onWillAcceptWithDetails!(
          DragTargetDetails(data: 'foreign', offset: Offset.zero),
        ),
        isFalse,
      );
    }
  });
}
