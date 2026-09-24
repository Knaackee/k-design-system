import 'dart:convert';
import 'k_data_table_draft.dart';
import 'k_data_table_single_column.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_layout.dart';
import 'k_table.dart';
import 'k_data_table_virtual.dart';
import 'k_data_table_virtual_types.dart';

enum KDataTableSortDirection { ascending, descending }

class KDataTableSort {
  const KDataTableSort({required this.columnId, required this.direction});
  final String columnId;
  final KDataTableSortDirection direction;
}

class KDataTableColumn<T> {
  const KDataTableColumn({
    required this.id,
    required this.label,
    required this.cell,
    this.compare,
    this.width,
    this.paddingInline,
    this.minWidth,
    this.flex = 1,
    this.align = KTableAlign.start,
  });
  final String id;
  final String label;
  final Widget Function(T) cell;
  final int Function(T, T)? compare;
  final double? width;

  /// Horizontal cell padding; defaults to the density control inset.
  final double? paddingInline;
  final double? minWidth;
  final double flex;
  final KTableAlign align;
}

class KDataTableGroup<T> {
  const KDataTableGroup({required this.id, required this.value, this.label});
  final String id;
  final String Function(T) value;
  final String Function(String)? label;
}

class KDataTableGroupValue {
  const KDataTableGroupValue({
    required this.id,
    required this.value,
    required this.label,
  });
  final String id;
  final String value;
  final String label;
}

class KDataTableSection<T> {
  KDataTableSection({
    required List<T> rows,
    required List<KDataTableGroupValue> path,
  }) : rows = List.unmodifiable(rows),
       path = List.unmodifiable(path);
  final List<T> rows;
  final List<KDataTableGroupValue> path;
}

/// Controlled sorting and grouping over KTable, with externally composed filters.
class KDataTable<T> extends StatelessWidget {
  const KDataTable({
    required this.label,
    required this.columns,
    this.displayMode = KDataTableDisplayMode.multiColumn,
    this.singleColumn,
    required this.rows,
    required this.rowId,
    required this.empty,
    this.sort,
    this.draftRows = const [],
    this.filter,
    this.groups = const [],
    this.groupIndent,
    this.showRowDividers = false,
    this.collapsedGroups = const {},
    this.onCollapsedGroupsChanged,
    this.toolbar,
    this.footerBuilder,
    this.viewport,
    this.loading,
    this.error,
    this.externalWindow,
    this.queryRevision,
    this.onRangeRequest,
    this.activeCell,
    this.focusCell,
    this.onBeforeActiveCellExit,
    super.key,
  });
  final String label;
  final List<KDataTableColumn<T>> columns;
  final KDataTableDisplayMode displayMode;
  final KDataTableSingleColumn<T>? singleColumn;

  List<KDataTableColumn<T>> get displayColumns =>
      displayMode == KDataTableDisplayMode.singleColumn
      ? [
          KDataTableColumn<T>(
            id: '__singleColumn',
            label: singleColumn!.columnLabel,
            minWidth: null,
            paddingInline: 0,
            cell: (row) =>
                KDataTableSingleRow<T>(content: singleColumn!, row: row),
          ),
        ]
      : columns;
  final List<T> rows;

  /// Local unsaved rows bypass filtering/sorting and retain their creation path.
  final List<KDataTableDraftRow<T>> draftRows;
  final String Function(T) rowId;

  KDataTableDraftRow<T>? draftFor(T row) {
    for (final draft in draftRows) {
      if (rowId(draft.row) == rowId(row)) return draft;
    }
    return null;
  }

  List<T> get displayRows => [
    ...rows,
    for (final d in draftRows)
      if (groups.isEmpty || d.originPath.isNotEmpty) d.row,
  ];
  String groupValue(KDataTableGroup<T> group, T row) {
    final draft = draftFor(row);
    if (draft != null) {
      for (final value in draft.originPath) {
        if (value.id == group.id) return value.value;
      }
    }
    return group.value(row);
  }

  int compareDrafts(T a, T b) =>
      (draftFor(a) != null ? 1 : 0) - (draftFor(b) != null ? 1 : 0);
  final Widget empty;
  final KDataTableSort? sort;
  final bool Function(T)? filter;
  final List<KDataTableGroup<T>> groups;

  /// Logical pixels per level; defaults to the control inline inset.
  final double? groupIndent;
  final bool showRowDividers;
  final Set<String> collapsedGroups;
  final ValueChanged<Set<String>>? onCollapsedGroupsChanged;
  final Widget? toolbar;
  final Widget Function(KDataTableSection<T>)? footerBuilder;

  final KDataTableViewport? viewport;
  final Widget? loading, error;
  final KDataTableWindow<T>? externalWindow;
  final String? queryRevision;
  final ValueChanged<KDataTableRange>? onRangeRequest;
  final KDataTableCellIdentity? activeCell, focusCell;
  KDataTableCellIdentity? get interactiveCell =>
      displayMode == KDataTableDisplayMode.multiColumn ? activeCell : null;
  KDataTableCellIdentity? get focusableCell =>
      displayMode == KDataTableDisplayMode.multiColumn ? focusCell : null;
  final bool Function()? onBeforeActiveCellExit;

  void _validate() {
    if (label.trim().isEmpty || columns.isEmpty) {
      throw ArgumentError('KDataTable requires a nonempty label and columns');
    }
    if (groupIndent != null && (!groupIndent!.isFinite || groupIndent! < 0)) {
      throw ArgumentError('groupIndent must be finite and nonnegative');
    }
    void unique(Iterable<String> ids, String kind) {
      final seen = <String>{};
      for (final id in ids) {
        if (id.trim().isEmpty || !seen.add(id)) {
          throw ArgumentError('$kind IDs must be nonempty and unique');
        }
      }
    }

    if (displayMode == KDataTableDisplayMode.singleColumn &&
        (singleColumn == null || singleColumn!.columnLabel.trim().isEmpty)) {
      throw ArgumentError('singleColumn requires content and a column label');
    }
    unique(columns.map((c) => c.id), 'Column');
    unique([...rows, for (final d in draftRows) d.row].map(rowId), 'Row');
    unique(groups.map((g) => g.id), 'Group');
    var base = 0.0;
    var flex = 0.0;
    for (final column in columns) {
      if (column.paddingInline != null &&
          (!column.paddingInline!.isFinite || column.paddingInline! < 0)) {
        throw ArgumentError(
          'Column paddingInline must be finite and nonnegative',
        );
      }
      if (column.label.trim().isEmpty) {
        throw ArgumentError('Column labels must be nonempty');
      }
      final width = column.width ?? column.minWidth;
      if ((width != null && (!width.isFinite || width <= 0)) ||
          (column.width == null &&
              (!column.flex.isFinite || column.flex <= 0))) {
        throw ArgumentError('Column dimensions must be positive and finite');
      }
      base += width ?? 0;
      if (column.width == null) flex += column.flex;
    }
    if (!base.isFinite || !flex.isFinite) {
      throw ArgumentError('Combined column dimensions must be finite');
    }
    if (sort != null &&
        !columns.any((c) => c.id == sort!.columnId && c.compare != null)) {
      throw ArgumentError('Sort must reference a comparable column');
    }
  }

  @override
  Widget build(BuildContext context) {
    _validate();
    if (viewport != null) return KVirtualDataTable<T>(table: this);
    if (externalWindow != null) {
      throw ArgumentError('externalWindow requires viewport');
    }
    final visibleColumns = displayColumns;
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final indent = groupIndent ?? tokens.spaceControlInsetInline;
    final sourceRows = displayRows;
    final filtered = [
      for (var i = 0; i < sourceRows.length; i++)
        if (draftFor(sourceRows[i]) != null ||
            filter == null ||
            filter!(sourceRows[i]))
          (index: i, value: sourceRows[i]),
    ];
    Widget render(
      List<({int index, T value})> items,
      int depth,
      List<List<String>> path,
      List<String> labels,
    ) {
      if (depth == groups.length) {
        final sorted = [...items];
        if (sort != null) {
          final compare = columns
              .firstWhere((c) => c.id == sort!.columnId)
              .compare!;
          sorted.sort((a, b) {
            final pin = compareDrafts(a.value, b.value);
            if (pin != 0) return pin;
            if (draftFor(a.value) != null) return a.index.compareTo(b.index);
            final result = sort!.direction == KDataTableSortDirection.ascending
                ? compare(a.value, b.value)
                : compare(b.value, a.value);
            return result == 0 ? a.index.compareTo(b.index) : result;
          });
        }
        return Padding(
          padding: EdgeInsetsDirectional.only(start: depth * indent),
          child: KStack(
            align: KLayoutAlign.stretch,
            gap: KLayoutGap.control,
            children: [
              KTable(
                label: [label, ...labels].join(' / '),
                showHeader: false,
                showRowDividers: showRowDividers,
                columns: [
                  for (final c in visibleColumns)
                    KTableColumn(
                      id: c.id,
                      header: Text(c.label),
                      headerLabel: c.label,
                      width: c.width,
                      paddingInline: c.paddingInline,
                      minWidth: c.minWidth,
                      flex: c.flex,
                      align: c.align,
                    ),
                ],
                rows: [
                  for (final item in sorted)
                    KTableRow(
                      id: rowId(item.value),
                      cells: [
                        for (final c in visibleColumns) c.cell(item.value),
                      ],
                    ),
                ],
              ),
              if (footerBuilder != null)
                footerBuilder!(
                  KDataTableSection<T>(
                    rows: [for (final item in sorted) item.value],
                    path: [
                      for (var i = 0; i < path.length; i++)
                        KDataTableGroupValue(
                          id: path[i][0],
                          value: path[i][1],
                          label: labels[i],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }
      final group = groups[depth];
      final buckets = <String, List<({int index, T value})>>{};
      for (final item in items) {
        (buckets[groupValue(group, item.value)] ??= []).add(item);
      }
      return KStack(
        align: KLayoutAlign.stretch,
        gap: KLayoutGap.section,
        children: [
          for (final entry in buckets.entries)
            _buildGroup(entry, depth, path, labels, group, indent, render),
        ],
      );
    }

    return KStack(
      align: KLayoutAlign.stretch,
      gap: KLayoutGap.section,
      children: [
        ?toolbar,
        if (filtered.isEmpty)
          KStack(
            align: KLayoutAlign.stretch,
            gap: KLayoutGap.control,
            children: [
              empty,
              if (footerBuilder != null)
                footerBuilder!(KDataTableSection<T>(rows: [], path: [])),
            ],
          )
        else
          render(filtered, 0, [], []),
        if (groups.isNotEmpty && draftRows.any((d) => d.originPath.isEmpty))
          KDataTable<T>(
            label: label,
            columns: columns,
            displayMode: displayMode,
            singleColumn: singleColumn,
            rows: const [],
            rowId: rowId,
            empty: empty,
            draftRows: draftRows.where((d) => d.originPath.isEmpty).toList(),
            showRowDividers: showRowDividers,
          ),
      ],
    );
  }

  Widget _buildGroup(
    MapEntry<String, List<({int index, T value})>> entry,
    int depth,
    List<List<String>> path,
    List<String> labels,
    KDataTableGroup<T> group,
    double indent,
    Widget Function(
      List<({int index, T value})>,
      int,
      List<List<String>>,
      List<String>,
    )
    render,
  ) {
    final nextPath = [
      ...path,
      [group.id, entry.key],
    ];
    final key = jsonEncode(nextPath);
    final title = group.label?.call(entry.key) ?? entry.key;
    final hasDraft = draftRows.any(
      (d) =>
          d.originPath.length >= nextPath.length &&
          List.generate(
            nextPath.length,
            (i) =>
                d.originPath[i].id == nextPath[i][0] &&
                d.originPath[i].value == nextPath[i][1],
          ).every((v) => v),
    );
    final collapsed = collapsedGroups.contains(key) && !hasDraft;
    final text = '$title (${entry.value.length})';
    final interactive = onCollapsedGroupsChanged != null;
    return KStack(
      key: ValueKey(key),
      align: KLayoutAlign.stretch,
      gap: KLayoutGap.control,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(start: depth * indent),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: interactive
                ? Semantics(
                    expanded: !collapsed,
                    child: KButton(
                      label: text,
                      variant: KButtonVariant.ghost,
                      leading: KIcon(
                        collapsed
                            ? KIconName.chevronRight
                            : KIconName.chevronDown,
                      ),
                      onPressed: () {
                        if (hasDraft) return;
                        final next = {...collapsedGroups};
                        if (collapsed) {
                          next.remove(key);
                        } else {
                          next.add(key);
                        }
                        onCollapsedGroupsChanged!(next);
                      },
                    ),
                  )
                : Text(text),
          ),
        ),
        if (!collapsed)
          render(entry.value, depth + 1, nextPath, [...labels, title]),
      ],
    );
  }
}
