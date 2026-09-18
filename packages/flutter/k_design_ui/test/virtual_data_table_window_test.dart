import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/src/data/k_data_table.dart';
import 'package:k_design_ui/src/data/k_data_table_virtual_types.dart';
import 'virtual_data_table_test.dart' show frame;

void main() {
  testWidgets(
    'obsolete response cannot replace accepted items or logical count',
    (tester) async {
      final requested = <KDataTableRange>[];
      final valid = KDataTableWindow<int>(
        queryRevision: 'current',
        totalCount: 240,
        startIndex: 0,
        entries: [KDataTableEntry.item(id: 'valid', row: 42)],
      );
      final stale = KDataTableWindow<int>(
        queryRevision: 'obsolete',
        totalCount: 1,
        startIndex: 0,
        entries: [KDataTableEntry.item(id: 'stale', row: 99)],
      );
      Widget make(
        KDataTableWindow<int> window,
        String revision, {
        Widget? error,
      }) => frame(
        KDataTable<int>(
          label: 'Items',
          rows: const [],
          rowId: (r) => '$r',
          columns: [
            KDataTableColumn(
              id: 'title',
              label: 'Title',
              cell: (r) => Text('Item $r'),
            ),
          ],
          viewport: const KDataTableViewport(height: 240, rowHeight: 48),
          empty: const Text('Empty'),
          loading: const Text('Loading'),
          error: error,
          externalWindow: window,
          queryRevision: revision,
          onRangeRequest: requested.add,
        ),
      );
      await tester.pumpWidget(make(valid, 'current'));
      await tester.pump();
      expect(find.text('Item 42'), findsOneWidget);
      await tester.pumpWidget(make(stale, 'current'));
      await tester.pump();
      expect(find.text('Item 42'), findsOneWidget);
      expect(find.text('Item 99'), findsNothing);
      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .any((s) => s.properties.value == '240'),
        isTrue,
      );
      await tester.pumpWidget(make(stale, 'next'));
      await tester.pump();
      expect(find.text('Item 42'), findsNothing);
      expect(find.text('Loading'), findsOneWidget);
      expect(find.text('Empty'), findsNothing);
      expect(requested.last.queryRevision, 'next');
      expect(requested.last.startIndex, 0);
      expect(requested.last.endIndex, 7);
      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .any((s) => s.properties.value == '1'),
        isFalse,
      );
      await tester.pumpWidget(make(stale, 'next', error: const Text('Failed')));
      expect(
        tester.getTopLeft(find.text('Loading')).dy,
        tester.getBottomLeft(find.text('Failed')).dy,
      );
    },
  );
}
