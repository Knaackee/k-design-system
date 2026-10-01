import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/data/k_data_table_semantics.dart';

final columns = <KDataTableColumn<int>>[
  KDataTableColumn(
    id: 'number',
    label: 'Number',
    cell: (r) => Text('Row $r'),
    compare: (a, b) => a.compareTo(b),
    width: 240,
  ),
  KDataTableColumn(
    id: 'reverse',
    label: 'Reverse',
    cell: (r) => Text('Other $r'),
    compare: (a, b) => b.compareTo(a),
    width: 240,
  ),
  KDataTableColumn(
    id: 'plain',
    label: 'Plain',
    cell: (r) => Text('Plain $r'),
    width: 240,
  ),
];
Widget frame(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);
List<String> ids(WidgetTester tester) => tester
    .widgetList<KTable>(find.byType(KTable))
    .expand((table) => table.rows.map((row) => row.id))
    .toList();
KDataTable<int> table({
  bool showHeader = false,
  KDataTableSort? sort,
  ValueChanged<KDataTableSort?>? onSortChanged,
  KDataTableViewport? viewport,
  KDataTableWindow<int>? window,
  ValueChanged<KDataTableRange>? onRange,
  KDataTableCellIdentity? activeCell,
  bool Function()? beforeExit,
  bool single = false,
  bool grouped = false,
}) => KDataTable<int>(
  label: 'Numbers',
  rows: const [3, 1, 2],
  columns: columns,
  rowId: (r) => '$r',
  empty: const Text('Empty'),
  showHeader: showHeader,
  sort: sort,
  onSortChanged: onSortChanged,
  viewport: viewport,
  externalWindow: window,
  queryRevision: window?.queryRevision,
  onRangeRequest: onRange,
  activeCell: activeCell,
  onBeforeActiveCellExit: beforeExit,
  displayMode: single
      ? KDataTableDisplayMode.singleColumn
      : KDataTableDisplayMode.multiColumn,
  singleColumn: KDataTableSingleColumn(
    columnLabel: 'Number',
    title: (r) => Text('Row $r'),
    onActivate: (_) {},
    semanticsLabel: (r) => 'Open $r',
  ),
  groups: grouped
      ? [KDataTableGroup(id: 'group', value: (r) => '${r % 2}')]
      : [],
);

void main() {
  testWidgets('legacy and single-column tables hide headers', (tester) async {
    await tester.pumpWidget(frame(table()));
    expect(find.text('Number'), findsNothing);
    await tester.pumpWidget(frame(table(showHeader: true, single: true)));
    expect(find.text('Number'), findsNothing);
  });

  testWidgets(
    'click cycles controlled order; switching columns starts ascending',
    (tester) async {
      KDataTableSort? sort;
      await tester.pumpWidget(
        frame(
          StatefulBuilder(
            builder: (context, setState) => table(
              showHeader: true,
              sort: sort,
              onSortChanged: (value) => setState(() => sort = value),
            ),
          ),
        ),
      );
      expect(ids(tester), ['3', '1', '2']);
      await tester.tap(find.text('Number'));
      await tester.pumpAndSettle();
      expect(sort?.direction, KDataTableSortDirection.ascending);
      expect(ids(tester), ['1', '2', '3']);
      await tester.tap(find.text('Number'));
      await tester.pumpAndSettle();
      expect(sort?.direction, KDataTableSortDirection.descending);
      expect(ids(tester), ['3', '2', '1']);
      await tester.tap(find.text('Number'));
      await tester.pumpAndSettle();
      expect(sort, isNull);
      expect(ids(tester), ['3', '1', '2']);
      await tester.tap(find.text('Number'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reverse'));
      await tester.pumpAndSettle();
      expect(sort?.columnId, 'reverse');
      expect(sort?.direction, KDataTableSortDirection.ascending);
      expect(ids(tester), ['3', '2', '1']);
    },
  );

  testWidgets(
    'sort prop stays authoritative; plain and read-only headers do not sort',
    (tester) async {
      final changes = <KDataTableSort?>[];
      await tester.pumpWidget(
        frame(table(showHeader: true, onSortChanged: changes.add)),
      );
      await tester.tap(find.text('Number'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plain'));
      expect(changes, hasLength(1));
      expect(ids(tester), ['3', '1', '2']);
      await tester.pumpWidget(
        frame(
          table(
            showHeader: true,
            sort: const KDataTableSort(
              columnId: 'number',
              direction: KDataTableSortDirection.ascending,
            ),
          ),
        ),
      );
      expect(find.byType(KButton), findsNothing);
      expect(ids(tester), ['1', '2', '3']);
      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .any((s) => s.properties.value == 'ascending'),
        isTrue,
      );
    },
  );

  testWidgets('grouped leaves share controlled sort and preserve groups', (
    tester,
  ) async {
    KDataTableSort? sort;
    await tester.pumpWidget(
      frame(
        StatefulBuilder(
          builder: (context, setState) => table(
            grouped: true,
            showHeader: true,
            sort: sort,
            onSortChanged: (value) => setState(() => sort = value),
          ),
        ),
      ),
    );
    expect(find.text('Number'), findsNWidgets(2));
    await tester.tap(find.text('Number').first);
    await tester.pumpAndSettle();
    expect(ids(tester), ['1', '3', '2']);
  });

  for (final virtual in [false, true]) {
    testWidgets('active editor veto blocks sort (virtual=$virtual)', (
      tester,
    ) async {
      var exits = 0, changes = 0;
      await tester.pumpWidget(
        frame(
          table(
            showHeader: true,
            onSortChanged: (_) => changes++,
            viewport: virtual ? const KDataTableViewport(height: 200) : null,
            activeCell: const KDataTableCellIdentity(
              rowId: '3',
              columnId: 'number',
            ),
            beforeExit: () {
              exits++;
              return false;
            },
          ),
        ),
      );
      await tester.tap(find.text('Number'));
      await tester.pumpAndSettle();
      expect(exits, 1);
      expect(changes, 0);
    });
  }

  testWidgets('virtual header cycles the rendered row order', (tester) async {
    KDataTableSort? sort;
    await tester.pumpWidget(
      frame(
        StatefulBuilder(
          builder: (context, setState) => table(
            showHeader: true,
            sort: sort,
            onSortChanged: (value) => setState(() => sort = value),
            viewport: const KDataTableViewport(height: 240),
          ),
        ),
      ),
    );
    for (final expected in [
      [1, 2, 3],
      [3, 2, 1],
      [3, 1, 2],
    ]) {
      await tester.tap(find.text('Number'));
      await tester.pumpAndSettle();
      final order = [1, 2, 3]
        ..sort(
          (a, b) => tester
              .getTopLeft(find.text('Row $a'))
              .dy
              .compareTo(tester.getTopLeft(find.text('Row $b')).dy),
        );
      expect(order, expected);
    }
  });

  testWidgets(
    'virtual header preserves ranges and follows horizontal body scroll',
    (tester) async {
      final ranges = <KDataTableRange>[];
      final window = KDataTableWindow<int>(
        queryRevision: 'q',
        totalCount: 100,
        startIndex: 0,
        entries: [
          for (var i = 0; i < 20; i++) KDataTableEntry.item(id: '$i', row: i),
        ],
      );
      Widget make(bool show) => frame(
        SizedBox(
          width: 400,
          child: table(
            showHeader: show,
            viewport: const KDataTableViewport(height: 200, rowHeight: 48),
            window: window,
            onRange: ranges.add,
          ),
        ),
      );
      await tester.pumpWidget(make(false));
      await tester.pumpAndSettle();
      final start = ranges.last.startIndex, end = ranges.last.endIndex;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(make(true));
      await tester.pumpAndSettle();
      expect(ranges.last.startIndex, start);
      expect(ranges.last.endIndex, end);
      final before = tester.getTopLeft(find.text('Number')).dx;
      final config = tester
          .widget<KSemanticTableView>(find.byType(KSemanticTableView))
          .configuration;
      config.horizontalDetails.controller!.jumpTo(100);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Number')).dx, before - 100);
      expect(tester.getTopLeft(find.text('Row 0')).dx, before - 100);
      expect(tester.takeException(), isNull);
    },
  );
}
