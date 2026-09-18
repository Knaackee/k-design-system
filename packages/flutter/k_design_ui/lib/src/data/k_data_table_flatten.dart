import 'dart:convert';
import 'k_data_table.dart';
import 'k_data_table_virtual_types.dart';

/// Stable display entries. Processing is local; only rendering is virtualized.
List<KDataTableEntry<T>> flattenKDataTable<T>(KDataTable<T> table) {
  final output = <KDataTableEntry<T>>[];
  final sourceRows = table.displayRows;
  final filtered = [
    for (var i = 0; i < sourceRows.length; i++)
      if (table.draftFor(sourceRows[i]) != null ||
          (table.filter?.call(sourceRows[i]) ?? true))
        (index: i, value: sourceRows[i]),
  ];
  void visit(
    List<({int index, T value})> rows,
    List<KDataTableGroupValue> path,
  ) {
    final depth = path.length;
    final pathKey = jsonEncode([
      for (final p in path) [p.id, p.value],
    ]);
    if (depth == table.groups.length || rows.isEmpty) {
      final sorted = [...rows];
      if (table.sort case final sort?) {
        final compare = table.columns
            .firstWhere((c) => c.id == sort.columnId)
            .compare!;
        sorted.sort((a, b) {
          final pin = table.compareDrafts(a.value, b.value);
          if (pin != 0) return pin;
          if (table.draftFor(a.value) != null) {
            return a.index.compareTo(b.index);
          }
          final order = sort.direction == KDataTableSortDirection.ascending
              ? compare(a.value, b.value)
              : compare(b.value, a.value);
          return order == 0 ? a.index.compareTo(b.index) : order;
        });
      }
      for (final item in sorted) {
        output.add(
          KDataTableEntry.item(
            id: table.rowId(item.value),
            row: item.value,
            depth: depth,
            path: path,
          ),
        );
      }
      if (table.footerBuilder != null) {
        output.add(
          KDataTableEntry.footer(
            id: 'footer:$pathKey',
            depth: depth,
            path: path,
            rows: [for (final item in sorted) item.value],
          ),
        );
      }
      return;
    }
    final group = table.groups[depth];
    final buckets = <String, List<({int index, T value})>>{};
    for (final row in rows) {
      (buckets[table.groupValue(group, row.value)] ??= []).add(row);
    }
    for (final bucket in buckets.entries) {
      final label = group.label?.call(bucket.key) ?? bucket.key;
      final next = [
        ...path,
        KDataTableGroupValue(id: group.id, value: bucket.key, label: label),
      ];
      final key = jsonEncode([
        for (final p in next) [p.id, p.value],
      ]);
      output.add(
        KDataTableEntry.group(
          id: 'group:$key',
          label: label,
          count: bucket.value.length,
          groupKey: key,
          depth: depth,
          path: next,
        ),
      );
      final hasDraft = bucket.value.any(
        (item) => table.draftFor(item.value) != null,
      );
      if (!table.collapsedGroups.contains(key) || hasDraft) {
        visit(bucket.value, next);
      }
    }
  }

  visit(filtered, []);
  if (table.groups.isNotEmpty) {
    for (final draft in table.draftRows.where((d) => d.originPath.isEmpty)) {
      output.add(
        KDataTableEntry.item(id: table.rowId(draft.row), row: draft.row),
      );
    }
  }
  return output;
}
