import 'dart:math' as math;
import 'k_data_table_external_drafts.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import '../primitives/k_layout.dart';
import '../primitives/k_overflow_text.dart';
import 'k_table.dart';
import 'k_data_table_spanning.dart';
import 'k_data_table_scroll.dart';
import 'k_data_table_semantics.dart';
import 'k_data_table_virtual_header.dart';
import 'k_data_table_virtual_cell.dart';
import 'k_data_table.dart';
import 'k_data_table_flatten.dart';
import 'k_data_table_virtual_types.dart';

/// Internal adapter; upstream types are never exposed through KDataTable.
class KVirtualDataTable<T> extends StatefulWidget {
  const KVirtualDataTable({required this.table, super.key});
  final KDataTable<T> table;
  @override
  State<KVirtualDataTable<T>> createState() => _KVirtualDataTableState<T>();
}

class _KVirtualDataTableState<T> extends State<KVirtualDataTable<T>> {
  final _vertical = ScrollController(), _horizontal = ScrollController();
  List<KDataTableEntry<T>> _entries = [];
  int _start = 0, _count = 0;
  KDataTableExternalDraftProjection<T>? _projection;
  final _positions = <int>[];
  double _rowHeight = 0, _viewportWidth = 0;
  List<double> _columnOffsets = [], _offsets = [0];
  final _cellKeys = <String, GlobalKey>{};
  String? _lastRange;
  KDataTableWindow<T>? _acceptedWindow;
  KDataTableCellIdentity? _focusedRequest;
  bool _exitAccepted = false;
  KDataTable<T> get table => widget.table;
  KDataTableViewport get viewport => table.viewport!;
  @override
  void initState() {
    super.initState();
    _vertical.addListener(_requestRange);
    void prune() => WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cellKeys.removeWhere((_, key) => key.currentContext == null);
      }
    });
    _vertical.addListener(prune);
    _horizontal.addListener(prune);
  }

  @override
  void didUpdateWidget(covariant KVirtualDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.table.interactiveCell != table.interactiveCell) {
      _exitAccepted = false;
    }
    if (oldWidget.table.queryRevision != table.queryRevision) _lastRange = null;
  }

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  KDataTableEntry<T>? _entry(int index) {
    if (_projection != null) return _projection!.entries[index];
    final relative = index - _start;
    return relative >= 0 && relative < _entries.length
        ? _entries[relative]
        : null;
  }

  double _height(int index) => switch (_entry(index)?.kind) {
    KDataTableEntryKind.group => viewport.groupHeight ?? _rowHeight,
    KDataTableEntryKind.footer => viewport.footerHeight ?? _rowHeight,
    _ => _rowHeight,
  };
  double _offset(int index) {
    if (table.externalWindow == null) return _offsets[index];
    var offset = index * _rowHeight;
    for (var i = 0; i < _entries.length; i++) {
      if (_positions[i] >= index) continue;
      offset += _height(_positions[i]) - _rowHeight;
    }
    return offset;
  }

  int _indexAt(double offset) {
    var low = 0, high = _count;
    while (low < high) {
      final middle = (low + high) ~/ 2;
      if (_offset(middle + 1) <= offset) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  void _requestRange() {
    if (!mounted ||
        table.externalWindow == null ||
        table.onRangeRequest == null) {
      return;
    }
    final offset = _vertical.hasClients ? _vertical.offset : 0.0;
    final start = math.max(0, _indexAt(offset) - viewport.overscan);
    final end = _count == 0
        ? (viewport.height / _rowHeight).ceil() + viewport.overscan
        : math.min(
            _count,
            _indexAt(offset + viewport.height) + 1 + viewport.overscan,
          );
    final signature = '${table.queryRevision}:$start:$end';
    if (_lastRange == signature) return;
    _lastRange = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _lastRange == signature) {
        table.onRangeRequest!(
          KDataTableRange(
            queryRevision: table.queryRevision!,
            startIndex: _projection?.toServer(start) ?? start,
            endIndex: _projection?.toServer(end) ?? end,
          ),
        );
      }
    });
  }

  bool _allowExit() {
    if (table.interactiveCell == null || _exitAccepted) return true;
    final accepted = table.onBeforeActiveCellExit?.call() ?? false;
    if (accepted) {
      _exitAccepted = true;
      FocusManager.instance.primaryFocus?.unfocus();
    }
    return accepted;
  }

  bool _allowScroll(double offset) {
    final active = table.interactiveCell;
    if (active == null || _exitAccepted) return true;
    final local = _entries.indexWhere(
      (e) =>
          e.kind == KDataTableEntryKind.item &&
          table.rowId(e.row as T) == active.rowId,
    );
    if (local < 0) return _allowExit();
    final index = _projection == null ? local + _start : _positions[local];
    if (_offset(index) < offset ||
        _offset(index + 1) > offset + viewport.height) {
      return _allowExit();
    }
    return true;
  }

  void _focusRequested() {
    final request = table.focusableCell;
    if (request == null || identical(request, _focusedRequest)) return;
    final local = _entries.indexWhere(
      (e) =>
          e.kind == KDataTableEntryKind.item &&
          table.rowId(e.row as T) == request.rowId,
    );
    if (local < 0) return;
    _focusedRequest = request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_vertical.hasClients) return;
      final offset = _offset(
        _projection == null ? local + _start : _positions[local],
      ).clamp(0.0, _vertical.position.maxScrollExtent);
      if (!_allowScroll(offset)) return;
      _vertical.jumpTo(offset);
      final column = table.displayColumns.indexWhere(
        (c) => c.id == request.columnId,
      );
      if (column >= 0 && _horizontal.hasClients) {
        _horizontal.jumpTo(
          _columnOffsets[column].clamp(
            0.0,
            _horizontal.position.maxScrollExtent,
          ),
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context =
            _cellKeys['${request.rowId}/${request.columnId}']?.currentContext;
        if (context == null) return;
        focusKDataTableCell(context);
      });
    });
  }

  void _prepare(double defaultHeight) {
    viewport.validate();
    _rowHeight = viewport.rowHeight ?? defaultHeight;
    final window = table.externalWindow;
    if (window == null) {
      _projection = null;
      _entries = flattenKDataTable(table);
      _start = 0;
      _count = _entries.length;
    } else {
      if (table.queryRevision == null ||
          table.onRangeRequest == null ||
          window.totalCount < 0 ||
          window.startIndex < 0 ||
          window.startIndex + window.entries.length > window.totalCount) {
        throw ArgumentError(
          'External windows require valid bounds, queryRevision and onRangeRequest',
        );
      }
      if (window.queryRevision == table.queryRevision) _acceptedWindow = window;
      final current = _acceptedWindow?.queryRevision == table.queryRevision
          ? _acceptedWindow
          : null;
      _projection = KDataTableExternalDraftProjection(table, current);
      _count = _projection!.count;
      _positions
        ..clear()
        ..addAll(_projection!.entries.keys.toList()..sort());
      _entries = [for (final p in _positions) _projection!.entries[p]!];
    }
    final ids = <String>{};
    for (final entry in _entries) {
      if (entry.id.isEmpty ||
          !ids.add('${entry.kind}/${entry.id}') ||
          entry.depth < 0 ||
          (entry.count ?? 0) < 0) {
        throw ArgumentError(
          'Display entries require unique nonempty IDs, nonnegative depth/count',
        );
      }
    }
    _offsets = [0];
    for (var i = 0; table.externalWindow == null && i < _count; i++) {
      _offsets.add(_offsets.last + _height(i));
    }
    _requestRange();
    _focusRequested();
  }

  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final visibleColumns = table.displayColumns;
    final scaler = MediaQuery.textScalerOf(context);
    final control = [
      t.sizeControl,
      t.sizeHitTarget,
      scaler.scale(t.fontControlSize) + 2,
      scaler.scale(t.fontBodyLineHeight) + 4,
    ].reduce(math.max);
    _prepare(control + 2 * t.spaceControlGap + t.borderWidthDefault);
    final indent = table.groupIndent ?? t.spaceControlInsetInline;
    final maxDepth =
        viewport.maxGroupDepth ??
        (table.externalWindow == null ? table.groups.length : 0);
    if (maxDepth < 0 || _entries.any((e) => e.depth > maxDepth)) {
      throw ArgumentError('maxGroupDepth must cover all entry depths');
    }
    final gutter = maxDepth * indent;
    final leading = gutter > 0 ? 1 : 0;
    Widget status(Widget child) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?table.error,
        if (table.externalWindow == null && _count == 0) table.empty,
        child,
      ],
    );
    final waiting =
        table.externalWindow != null &&
        _acceptedWindow?.queryRevision != table.queryRevision;
    return KStack(
      align: KLayoutAlign.stretch,
      gap: KLayoutGap.section,
      children: [
        ?table.toolbar,
        if (_count == 0)
          status(
            SizedBox(
              height: viewport.height,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: waiting
                    ? table.loading
                    : table.externalWindow != null
                    ? table.empty
                    : null,
              ),
            ),
          )
        else
          status(
            LayoutBuilder(
              builder: (context, constraints) {
                if (!constraints.hasBoundedWidth) {
                  throw ArgumentError('Virtual table requires bounded width');
                }
                final base = visibleColumns.fold(
                  0.0,
                  (s, c) =>
                      s +
                      (c.width ??
                          c.minWidth ??
                          t.componentDataTableDefaultColumnMinWidth),
                );
                final flex = visibleColumns
                    .where((c) => c.width == null)
                    .fold(0.0, (s, c) => s + c.flex);
                final extra = math.max(
                  0.0,
                  constraints.maxWidth - base - gutter,
                );
                final widths = [
                  for (final c in visibleColumns)
                    c.width ??
                        (c.minWidth ??
                                t.componentDataTableDefaultColumnMinWidth) +
                            (flex == 0 ? 0 : extra * c.flex / flex),
                ];
                _viewportWidth = constraints.maxWidth;
                _columnOffsets = [gutter];
                for (final width in widths) {
                  _columnOffsets.add(_columnOffsets.last + width);
                }
                return KDataTableVirtualHeader(
                  table: table,
                  widths: widths,
                  gutter: gutter,
                  horizontal: _horizontal,
                  child: SizedBox(
                    height: viewport.height,
                    child: Semantics(
                      label: table.label,

                      explicitChildNodes: true,
                      value: '$_count',
                      child: KSemanticTableView(
                        configuration: TableView.builder(
                          // TableView 0.5.4 exposes cacheExtent, despite its SDK deprecation.
                          // ignore: deprecated_member_use
                          cacheExtent: viewport.overscan * _rowHeight,
                          verticalDetails: ScrollableDetails.vertical(
                            controller: _vertical,
                            physics: KDataTableScrollPhysics(
                              allow: _allowScroll,
                            ),
                          ),
                          horizontalDetails: ScrollableDetails.horizontal(
                            controller: _horizontal,
                            physics: KDataTableScrollPhysics(
                              allow: (offset) {
                                final active = table.interactiveCell;
                                if (active == null) return true;
                                final i = visibleColumns.indexWhere(
                                  (c) => c.id == active.columnId,
                                );
                                return i < 0 ||
                                    (_columnOffsets[i] >= offset &&
                                        _columnOffsets[i + 1] <=
                                            offset + _viewportWidth) ||
                                    _allowExit();
                              },
                            ),
                          ),
                          columnCount: visibleColumns.length + leading,
                          rowCount: _count,
                          columnBuilder: (i) => TableSpan(
                            extent: FixedTableSpanExtent(
                              i < leading ? gutter : widths[i - leading],
                            ),
                          ),
                          rowBuilder: (i) => TableSpan(
                            extent: FixedTableSpanExtent(_height(i)),
                          ),
                          cellBuilder: (context, vicinity) {
                            final entry = _entry(vicinity.row);
                            if (entry == null) {
                              return TableViewCell(
                                child: ExcludeSemantics(
                                  child: ColoredBox(
                                    color: t.colorSurfaceSubtle,
                                  ),
                                ),
                              );
                            }
                            final spanning =
                                entry.kind != KDataTableEntryKind.item;
                            if (!spanning && vicinity.column < leading) {
                              return const TableViewCell(
                                child: SizedBox.shrink(),
                              );
                            }
                            final column =
                                visibleColumns[math.max(
                                  0,
                                  vicinity.column - leading,
                                )];
                            final identity = spanning
                                ? '${entry.kind}/${entry.id}'
                                : '${table.rowId(entry.row as T)}/${column.id}';
                            Widget child;
                            if (spanning) {
                              child = buildKDataTableSpanning(
                                table,
                                entry,
                                indent,
                                _allowExit,
                              );
                            } else {
                              final cell = column.cell(entry.row as T);
                              final padding =
                                  column.paddingInline ??
                                  t.spaceControlInsetInline;
                              child = Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                  padding,
                                  t.spaceControlGap,
                                  padding,
                                  t.spaceControlGap + t.borderWidthDefault,
                                ),
                                child: Align(
                                  alignment: switch (column.align) {
                                    KTableAlign.start =>
                                      AlignmentDirectional.centerStart,
                                    KTableAlign.center =>
                                      AlignmentDirectional.center,
                                    KTableAlign.end =>
                                      AlignmentDirectional.centerEnd,
                                  },
                                  child: Focus(
                                    key: _cellKeys.putIfAbsent(
                                      identity,
                                      GlobalKey.new,
                                    ),
                                    canRequestFocus: false,
                                    skipTraversal: true,
                                    child: DefaultTextStyle.merge(
                                      softWrap: false,
                                      maxLines: 1,
                                      overflow:
                                          column.overflow ==
                                              KTableTextOverflow.visible
                                          ? TextOverflow.visible
                                          : TextOverflow.ellipsis,
                                      child:
                                          cell is Text &&
                                              column.overflow !=
                                                  KTableTextOverflow.visible
                                          ? KOverflowText(
                                              text: cell,
                                              focusable: false,
                                            )
                                          : cell,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return TableViewCell(
                              key: ValueKey(identity),
                              columnMergeStart: spanning ? 0 : null,
                              columnMergeSpan: spanning
                                  ? visibleColumns.length + leading
                                  : null,
                              child: KDataTableVirtualCell(
                                textAlign: switch (column.align) {
                                  KTableAlign.center => TextAlign.center,
                                  KTableAlign.end => TextAlign.end,
                                  _ => TextAlign.start,
                                },
                                rowIndex: vicinity.row,
                                label: spanning ? null : column.label,
                                showRowDividers: table.showRowDividers,
                                child: child,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
