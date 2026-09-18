import 'k_data_table.dart';
import 'k_data_table_virtual_types.dart';

/// Maps local insertion slots without changing the consumer's server indices.
class KDataTableExternalDraftProjection<T> {
  KDataTableExternalDraftProjection(
    KDataTable<T> table,
    KDataTableWindow<T>? window,
  ) {
    final drafts = [...table.draftRows]
      ..sort((a, b) => (a.originIndex ?? 0).compareTo(b.originIndex ?? 0));
    final ids = <String>{};
    for (final draft in drafts) {
      final anchor = draft.originIndex;
      if (anchor == null ||
          anchor < 0 ||
          anchor > (window?.totalCount ?? 0) ||
          draft.originQueryRevision != table.queryRevision) {
        throw ArgumentError(
          'External drafts require an originIndex within the current query and matching originQueryRevision',
        );
      }
      final id = table.rowId(draft.row);
      if (!ids.add(id) ||
          (window?.entries.any(
                (e) =>
                    e.kind == KDataTableEntryKind.item &&
                    table.rowId(e.row as T) == id,
              ) ??
              false)) {
        throw ArgumentError(
          'Draft IDs must be unique and separate from server rows',
        );
      }
      positions.add(anchor + positions.length);
    }
    for (var i = 0; i < (window?.entries.length ?? 0); i++) {
      final server = window!.startIndex + i;
      final display =
          server + drafts.where((d) => d.originIndex! <= server).length;
      entries[display] = window.entries[i];
    }
    for (var i = 0; i < drafts.length; i++) {
      final d = drafts[i];
      entries[positions[i]] = KDataTableEntry.item(
        id: table.rowId(d.row),
        row: d.row,
        depth: d.originPath.length,
        path: d.originPath,
      );
    }
    count = (window?.totalCount ?? 0) + drafts.length;
  }
  final entries = <int, KDataTableEntry<T>>{};
  final positions = <int>[];
  late final int count;
  int toServer(int display) =>
      display - positions.where((p) => p < display).length;
}
