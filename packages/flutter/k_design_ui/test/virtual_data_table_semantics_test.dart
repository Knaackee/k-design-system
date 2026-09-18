import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/src/data/k_data_table.dart';
import 'package:k_design_ui/src/data/k_data_table_virtual_types.dart';
import 'package:k_design_ui/src/data/k_data_table_semantics.dart';
import 'package:k_design_ui/src/data/k_editable_cell.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'virtual_data_table_test.dart' show frame, table;

void main() {
  testWidgets(
    'offscreen focus request scrolls and targets stable row and column',
    (tester) async {
      await tester.pumpWidget(
        frame(
          table(
            focus: const KDataTableCellIdentity(
              rowId: '120',
              columnId: 'title',
            ),
            columns: [
              KDataTableColumn(
                id: 'title',
                label: 'Title',
                cell: (n) => KEditableCell(
                  label: 'Edit $n',
                  display: Text('Item $n'),
                  editor: const SizedBox(),
                  onEdit: () {},
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Item 120'), findsOneWidget);
      final primary = FocusManager.instance.primaryFocus!;
      expect(
        primary.context!.findAncestorWidgetOfExactType<KEditableCell>()?.label,
        'Edit 120',
      );
    },
  );
  testWidgets(
    'semantic hierarchy has one row per logical index and cells as children',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        frame(
          table(
            columns: [
              KDataTableColumn(id: 'a', label: 'A', cell: (n) => Text('A$n')),
              KDataTableColumn(id: 'b', label: 'B', cell: (n) => Text('B$n')),
            ],
          ),
        ),
      );
      SemanticsNode? tableNode;
      void visit(SemanticsNode node) {
        if (node.role == SemanticsRole.table) tableNode = node;
        node.visitChildren((child) {
          visit(child);
          return true;
        });
      }

      tester.binding.rootPipelineOwner.visitChildren((owner) {
        visit(owner.semanticsOwner!.rootSemanticsNode!);
      });
      expect(tableNode, isNotNull);
      final rows = <SemanticsNode>[];
      tableNode!.visitChildren((row) {
        rows.add(row);
        return true;
      });
      expect(rows.length, lessThan(10));
      for (final row in rows) {
        expect(row.role, SemanticsRole.row);
        final cells = <SemanticsNode>[];
        row.visitChildren((cell) {
          cells.add(cell);
          return true;
        });
        expect(cells.length, 2);
        expect(cells.every((c) => c.role == SemanticsRole.cell), isTrue);
      }
      handle.dispose();
    },
  );
  testWidgets(
    'both axes build only the visible columns and merged rows persist horizontally',
    (tester) async {
      var built = 0;
      await tester.pumpWidget(
        frame(
          table(
            rows: List.generate(80, (i) => i),
            groups: [KDataTableGroup(id: 'all', value: (_) => 'All')],
            columns: List.generate(
              20,
              (i) => KDataTableColumn(
                id: '$i',
                label: 'Column $i',
                width: 180,
                cell: (n) {
                  built++;
                  return Text('$i/$n');
                },
              ),
            ),
          ),
        ),
      );
      expect(built, lessThan(50));
      final config = tester
          .widget<KSemanticTableView>(find.byType(KSemanticTableView))
          .configuration;
      config.horizontalDetails.controller!.jumpTo(1800);
      await tester.pumpAndSettle();
      expect(find.text('10/0'), findsOneWidget);
      expect(built, lessThan(100));
      expect(
        tester
            .widgetList<TableViewCell>(find.byType(TableViewCell))
            .any((c) => c.columnMergeSpan == 21),
        isTrue,
      );
    },
  );
  testWidgets('group collapse veto retains active row', (tester) async {
    var collapseCalls = 0;
    await tester.pumpWidget(
      frame(
        table(
          rows: [0, 1],
          groups: [KDataTableGroup(id: 'all', value: (_) => 'All')],
          active: const KDataTableCellIdentity(rowId: '0', columnId: 'title'),
          onExit: () => false,
          onCollapse: (_) => collapseCalls++,
        ),
      ),
    );
    await tester.tap(find.text('All (2)'));
    await tester.pumpAndSettle();
    expect(collapseCalls, 0);
    expect(find.text('Item 0'), findsOneWidget);
  });
}
