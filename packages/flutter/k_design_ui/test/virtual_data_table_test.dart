import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/src/data/k_data_table.dart';
import 'package:k_design_ui/src/data/k_data_table_virtual_types.dart';
import 'package:k_design_ui/src/data/k_data_table_flatten.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:k_design_ui/src/data/k_data_table_semantics.dart';

Widget frame(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 500, child: child)),
);
KDataTable<int> table({
  List<int>? rows,
  List<KDataTableColumn<int>>? columns,
  List<KDataTableGroup<int>> groups = const [],
  Set<String> collapsed = const {},
  ValueChanged<Set<String>>? onCollapse,
  KDataTableCellIdentity? active,
  KDataTableCellIdentity? focus,
  bool Function()? onExit,
  KDataTableWindow<int>? window,
  String? revision,
  ValueChanged<KDataTableRange>? onRange,
  Widget Function(KDataTableSection<int>)? footer,
}) => KDataTable<int>(
  label: 'Items',
  columns:
      columns ??
      [
        KDataTableColumn(
          id: 'title',
          label: 'Title',
          cell: (n) => Text('Item $n'),
        ),
      ],
  rows: rows ?? List.generate(200, (i) => i),
  rowId: (n) => '$n',
  empty: const Text('Empty'),
  viewport: const KDataTableViewport(height: 240, rowHeight: 48, overscan: 1),
  groups: groups,
  collapsedGroups: collapsed,
  onCollapsedGroupsChanged: onCollapse,
  activeCell: active,
  focusCell: focus,
  onBeforeActiveCellExit: onExit,
  externalWindow: window,
  queryRevision: revision,
  onRangeRequest: onRange,
  footerBuilder: footer,
);

void main() {
  testWidgets('builds bounded cells and scrolls to later stable IDs', (
    tester,
  ) async {
    var built = 0;
    await tester.pumpWidget(
      frame(
        table(
          columns: [
            KDataTableColumn(
              id: 'title',
              label: 'Title',
              cell: (n) {
                built++;
                return Text('Item $n');
              },
            ),
          ],
        ),
      ),
    );
    expect(built, lessThan(15));
    expect(find.text('Item 0'), findsOneWidget);
    final view = tester
        .widget<KSemanticTableView>(find.byType(KSemanticTableView))
        .configuration;
    view.verticalDetails.controller!.jumpTo(48 * 100);
    await tester.pumpAndSettle();
    expect(find.text('Item 100'), findsOneWidget);
    expect(find.text('Item 0'), findsNothing);
    expect(built, lessThan(30));
  });
  testWidgets('nested groups and footers span columns and collapse', (
    tester,
  ) async {
    var collapsed = <String>{};
    await tester.pumpWidget(
      frame(
        StatefulBuilder(
          builder: (context, update) => table(
            rows: [0, 1],
            groups: [
              KDataTableGroup(id: 'team', value: (_) => 'A'),
              KDataTableGroup(id: 'status', value: (_) => 'Open'),
            ],
            columns: [
              KDataTableColumn(id: 'a', label: 'A', cell: (n) => Text('A$n')),
              KDataTableColumn(id: 'b', label: 'B', cell: (n) => Text('B$n')),
            ],
            collapsed: collapsed,
            onCollapse: (next) => update(() => collapsed = next),
            footer: (_) => const Text('Add item'),
          ),
        ),
      ),
    );
    expect(find.text('A (2)'), findsOneWidget);
    expect(find.text('Open (2)'), findsOneWidget);
    expect(find.text('Add item'), findsOneWidget);
    final merged = tester
        .widgetList<TableViewCell>(find.byType(TableViewCell))
        .where((cell) => cell.columnMergeSpan == 3);
    expect(merged.length, 3);
    await tester.tap(find.text('A (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Open (2)'), findsNothing);
    expect(find.text('Add item'), findsNothing);
    expect(collapsed, contains('[["team","A"]]'));
  });
  testWidgets(
    'stale external revision renders inert placeholders and requests current range',
    (tester) async {
      final requested = <KDataTableRange>[];
      final old = KDataTableWindow(
        queryRevision: 'old',
        totalCount: 200,
        startIndex: 0,
        entries: [KDataTableEntry.item(id: 'stale', row: 999)],
      );
      await tester.pumpWidget(
        frame(table(window: old, revision: 'new', onRange: requested.add)),
      );
      await tester.pump();
      expect(find.text('Item 999'), findsNothing);
      expect(requested.single.queryRevision, 'new');
      expect(requested.single.startIndex, 0);
      expect(requested.single.endIndex, lessThan(10));
      await tester.pumpWidget(
        frame(
          table(
            window: KDataTableWindow(
              queryRevision: 'new',
              totalCount: 200,
              startIndex: 0,
              entries: [KDataTableEntry.item(id: 'fresh', row: 123)],
            ),
            revision: 'new',
            onRange: requested.add,
          ),
        ),
      );
      expect(find.text('Item 123'), findsOneWidget);
    },
  );
  testWidgets('validation veto retains active editor on scroll and collapse', (
    tester,
  ) async {
    var requests = 0;
    var allow = false;
    final draft = TextEditingController(text: 'Draft');
    final focus = FocusNode();
    await tester.pumpWidget(
      frame(
        table(
          active: const KDataTableCellIdentity(rowId: '0', columnId: 'title'),
          onExit: () {
            requests++;
            return allow;
          },
          columns: [
            KDataTableColumn(
              id: 'title',
              label: 'Title',
              cell: (n) => n == 0
                  ? TextField(controller: draft, focusNode: focus)
                  : Text('Item $n'),
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Uncommitted');
    await tester.drag(find.byType(KSemanticTableView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(requests, greaterThan(0));
    expect(find.byType(TextField), findsOneWidget);
    expect(draft.text, 'Uncommitted');
    allow = true;
    await tester.drag(find.byType(KSemanticTableView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(draft.text, 'Uncommitted');
    await tester.pumpWidget(const SizedBox.shrink());
    draft.dispose();
    focus.dispose();
  });
  testWidgets(
    'semantics include logical count and global index after scrolling',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(frame(table()));
      final root = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .firstWhere((s) => s.properties.value == '200');
      expect(root.properties.value, '200');
      tester
          .widget<KSemanticTableView>(find.byType(KSemanticTableView))
          .configuration
          .verticalDetails
          .controller!
          .jumpTo(4800);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .any((s) => s.properties.identifier == 'k-data-row-101'),
        isTrue,
      );
      handle.dispose();
    },
  );
  test(
    'flatten preserves insertion order, sorted leaf rows, paths and stable footer identity',
    () {
      final entries = flattenKDataTable(
        table(
          rows: [3, 0, 1, 2],
          groups: [KDataTableGroup(id: 'parity', value: (n) => '${n % 2}')],
          footer: (_) => const SizedBox(),
        ),
      );
      expect(
        entries
            .where((e) => e.kind == KDataTableEntryKind.item)
            .map((e) => e.row),
        [3, 1, 0, 2],
      );
      expect(entries.last.path.single.value, '0');
      expect(entries.last.rows, [0, 2]);
    },
  );
}
