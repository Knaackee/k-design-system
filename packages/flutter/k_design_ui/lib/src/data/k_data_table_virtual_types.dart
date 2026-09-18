import 'k_data_table.dart';

class KDataTableViewport {
  const KDataTableViewport({
    required this.height,
    this.rowHeight,
    this.groupHeight,
    this.footerHeight,
    this.overscan = 2,
    this.maxGroupDepth,
  });
  final double height;
  final double? rowHeight, groupHeight, footerHeight;
  final int overscan;
  final int? maxGroupDepth;

  void validate() {
    if (!height.isFinite || height <= 0 || overscan < 0) {
      throw ArgumentError(
        'Viewport requires positive finite height and nonnegative overscan',
      );
    }
    for (final extent in [rowHeight, groupHeight, footerHeight]) {
      if (extent != null && (!extent.isFinite || extent <= 0)) {
        throw ArgumentError('Row extents must be positive and finite');
      }
    }
  }
}

class KDataTableCellIdentity {
  const KDataTableCellIdentity({required this.rowId, required this.columnId});
  final String rowId, columnId;
}

enum KDataTableEntryKind { item, group, footer }

class KDataTableEntry<T> {
  KDataTableEntry.item({
    required this.id,
    required T this.row,
    this.depth = 0,
    List<KDataTableGroupValue> path = const [],
  }) : kind = KDataTableEntryKind.item,
       path = List.unmodifiable(path),
       label = null,
       count = null,
       groupKey = null,
       rows = const [];
  KDataTableEntry.group({
    required this.id,
    required this.label,
    required this.count,
    required this.groupKey,
    this.depth = 0,
    List<KDataTableGroupValue> path = const [],
  }) : kind = KDataTableEntryKind.group,
       row = null,
       path = List.unmodifiable(path),
       rows = const [];
  KDataTableEntry.footer({
    required this.id,
    required List<T> rows,
    this.depth = 0,
    List<KDataTableGroupValue> path = const [],
  }) : kind = KDataTableEntryKind.footer,
       row = null,
       path = List.unmodifiable(path),
       rows = List.unmodifiable(rows),
       label = null,
       count = null,
       groupKey = null;
  final String id;
  final KDataTableEntryKind kind;
  final int depth;
  final List<KDataTableGroupValue> path;
  final T? row;
  final String? label, groupKey;
  final int? count;
  final List<T> rows;
}

class KDataTableWindow<T> {
  KDataTableWindow({
    required this.queryRevision,
    required this.totalCount,
    required this.startIndex,
    required List<KDataTableEntry<T>> entries,
  }) : entries = List.unmodifiable(entries);
  final String queryRevision;
  final int totalCount, startIndex;
  final List<KDataTableEntry<T>> entries;
}

class KDataTableRange {
  const KDataTableRange({
    required this.queryRevision,
    required this.startIndex,
    required this.endIndex,
  });
  final String queryRevision;
  final int startIndex, endIndex;
}
