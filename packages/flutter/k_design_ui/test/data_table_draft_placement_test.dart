import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/src/data/k_data_table_flatten.dart';
import 'package:k_design_ui/src/data/k_data_table_external_drafts.dart';

typedef Row = ({String id, String title, String status});
const path = [
  KDataTableGroupValue(id: 'status', value: 'planned', label: 'Planned'),
];
KDataTable<Row> table({
  List<KDataTableDraftRow<Row>> drafts = const [],
  bool Function(Row)? filter,
  Set<String> collapsed = const {},
  KDataTableWindow<Row>? window,
}) => KDataTable<Row>(
  label: 'Rows',
  columns: [
    KDataTableColumn(
      id: 'title',
      label: 'Title',
      cell: (r) => Text(r.title),
      compare: (a, b) => a.title.compareTo(b.title),
    ),
  ],
  rows: const [(id: 'a', title: 'Z last', status: 'planned')],
  rowId: (r) => r.id,
  empty: const Text('Empty'),
  draftRows: drafts,
  groups: [KDataTableGroup(id: 'status', value: (r) => r.status)],
  filter: filter,
  collapsedGroups: collapsed,
  sort: const KDataTableSort(
    columnId: 'title',
    direction: KDataTableSortDirection.ascending,
  ),
  footerBuilder: (_) => const Text('Add'),
  queryRevision: window?.queryRevision,
  externalWindow: window,
);
void main() {
  final changed = (id: 'draft', title: 'A first', status: 'done');
  test(
    'draft remains at creation group end despite changed group and sorting',
    () {
      final entries = flattenKDataTable(
        table(
          drafts: [KDataTableDraftRow(row: changed, originPath: path)],
        ),
      );
      expect(
        entries
            .where((e) => e.kind == KDataTableEntryKind.group)
            .single
            .path
            .single
            .value,
        'planned',
      );
      expect(
        entries
            .where((e) => e.kind == KDataTableEntryKind.item)
            .map((e) => e.id),
        ['a', 'draft'],
      );
      expect(entries.last.kind, KDataTableEntryKind.footer);
    },
  );
  test('filtered and collapsed creation group keeps draft', () {
    final entries = flattenKDataTable(
      table(
        drafts: [KDataTableDraftRow(row: changed, originPath: path)],
        filter: (_) => false,
        collapsed: {'[["status","planned"]]'},
      ),
    );
    expect(
      entries.where((e) => e.kind == KDataTableEntryKind.item).single.id,
      'draft',
    );
  });
  test('root draft does not acquire a group from its current values', () {
    final entries = flattenKDataTable(
      table(drafts: [KDataTableDraftRow(row: changed)]),
    );
    final draft = entries.last;
    expect(draft.id, 'draft');
    expect(draft.depth, 0);
    expect(draft.path, isEmpty);
  });
  test('external insertion preserves server indices and separate drafts', () {
    final window = KDataTableWindow<Row>(
      queryRevision: 'v1',
      totalCount: 10,
      startIndex: 4,
      entries: [
        KDataTableEntry.item(
          id: 'server4',
          row: (id: 'server4', title: 'Four', status: 'planned'),
        ),
        KDataTableEntry.item(
          id: 'server5',
          row: (id: 'server5', title: 'Five', status: 'planned'),
        ),
      ],
    );
    final projection = KDataTableExternalDraftProjection(
      table(
        window: window,
        drafts: [
          KDataTableDraftRow(
            row: changed,
            originPath: path,
            originIndex: 5,
            originQueryRevision: 'v1',
          ),
        ],
      ),
      window,
    );
    expect(projection.count, 11);
    expect(projection.entries[5]!.id, 'draft');
    expect(projection.entries[6]!.id, 'server5');
    expect(projection.toServer(5), 5);
    expect(projection.toServer(6), 5);
    expect(projection.toServer(7), 6);
    expect(window.totalCount, 10);
    expect(window.entries, hasLength(2));
  });
  test('external stale anchor revision is rejected', () {
    final window = KDataTableWindow<Row>(
      queryRevision: 'v2',
      totalCount: 10,
      startIndex: 0,
      entries: [],
    );
    expect(
      () => KDataTableExternalDraftProjection(
        table(
          window: window,
          drafts: [
            KDataTableDraftRow(
              row: changed,
              originIndex: 0,
              originQueryRevision: 'v1',
            ),
          ],
        ),
        window,
      ),
      throwsArgumentError,
    );
  });
}
