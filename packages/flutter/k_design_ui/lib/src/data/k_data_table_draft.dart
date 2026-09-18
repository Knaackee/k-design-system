import 'dart:async';
import 'package:flutter/foundation.dart';
import 'k_data_table.dart';

enum KDataTableDraftStatus { pristine, dirty, saving, error }

enum KDataTableDraftSavePolicy { explicit, rowExit }

enum KDataTableDraftEventType {
  started,
  changed,
  commitRequested,
  committed,
  cancelled,
  error,
}

class KDataTableDraftRow<T> {
  KDataTableDraftRow({
    required this.row,
    this.originIndex,
    this.originQueryRevision,
    List<KDataTableGroupValue> originPath = const [],
  }) : originPath = List.unmodifiable(originPath);
  final T row;
  final int? originIndex;
  final String? originQueryRevision;
  final List<KDataTableGroupValue> originPath;
}

class KDataTableDraftSnapshot<T> {
  KDataTableDraftSnapshot({
    required this.id,
    required this.baseline,
    required this.current,
    required this.status,
    required this.originPath,
    this.initialColumnId,
    this.originIndex,
    this.originQueryRevision,
    this.error,
  });
  final String id;
  final T baseline, current;
  final KDataTableDraftStatus status;
  final List<KDataTableGroupValue> originPath;
  final String? initialColumnId;
  final int? originIndex;
  final String? originQueryRevision;
  final Object? error;
}

class KDataTableDraftEvent<T> {
  const KDataTableDraftEvent({
    required this.type,
    required this.snapshot,
    required this.reason,
    this.acceptedRow,
    this.error,
  });
  final KDataTableDraftEventType type;
  final KDataTableDraftSnapshot<T> snapshot;
  final String reason;
  final T? acceptedRow;
  final Object? error;
}

/// Consumer-owned draft state. Keep this controller outside recycled cells.
/// Persistence and domain equality are supplied by the consuming application.
class KDataTableDraftController<T> extends ChangeNotifier {
  KDataTableDraftController({
    required this.rowId,
    required this.cloneRow,
    required this.isEqual,
    required this.onCommit,
    this.onEvent,
    this.savePolicy = KDataTableDraftSavePolicy.explicit,
  });
  final String Function(T) rowId;
  final T Function(T) cloneRow;
  final bool Function(T, T) isEqual;
  final FutureOr<T> Function(T, KDataTableDraftSnapshot<T>) onCommit;
  final void Function(KDataTableDraftEvent<T>)? onEvent;
  final KDataTableDraftSavePolicy savePolicy;
  final _items = <String, KDataTableDraftSnapshot<T>>{};
  final _pending = <String, Future<bool>>{};
  final _leases = <String, int>{};
  bool _disposed = false;

  KDataTableDraftSnapshot<T> _copy(KDataTableDraftSnapshot<T> d) =>
      KDataTableDraftSnapshot(
        id: d.id,
        baseline: cloneRow(d.baseline),
        current: cloneRow(d.current),
        status: d.status,
        originPath: d.originPath,
        initialColumnId: d.initialColumnId,
        originIndex: d.originIndex,
        originQueryRevision: d.originQueryRevision,
        error: d.error,
      );
  KDataTableDraftSnapshot<T>? get(String id) =>
      _items[id] == null ? null : _copy(_items[id]!);
  List<KDataTableDraftSnapshot<T>> get drafts =>
      List.unmodifiable(_items.values.map(_copy));
  List<KDataTableDraftRow<T>> get draftRows => [
    for (final d in drafts)
      KDataTableDraftRow(
        row: d.current,
        originPath: d.originPath,
        originIndex: d.originIndex,
        originQueryRevision: d.originQueryRevision,
      ),
  ];

  void _emit(
    KDataTableDraftEventType type,
    KDataTableDraftSnapshot<T> d,
    String reason, {
    T? acceptedRow,
    Object? error,
  }) {
    if (_disposed) return;
    notifyListeners();
    try {
      onEvent?.call(
        KDataTableDraftEvent(
          type: type,
          snapshot: _copy(d),
          reason: reason,
          acceptedRow: acceptedRow == null ? null : cloneRow(acceptedRow),
          error: error,
        ),
      );
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'KDataTableDraftController',
          context: ErrorDescription('while notifying onEvent'),
        ),
      );
    }
  }

  void begin(
    T defaults, {
    List<KDataTableGroupValue> originPath = const [],
    required String initialColumnId,
    int? originIndex,
    String? originQueryRevision,
  }) {
    if (_disposed) throw StateError('Controller is disposed');
    final id = rowId(defaults);
    if (initialColumnId.trim().isEmpty) {
      throw ArgumentError('initialColumnId must be nonempty');
    }
    if (rowId(cloneRow(defaults)) != id) {
      throw ArgumentError('cloneRow must preserve identity');
    }
    if (id.trim().isEmpty || _items.containsKey(id)) {
      throw ArgumentError('Draft ID must be nonempty and unique');
    }
    final d = KDataTableDraftSnapshot(
      id: id,
      baseline: cloneRow(defaults),
      current: cloneRow(defaults),
      status: KDataTableDraftStatus.pristine,
      originPath: List<KDataTableGroupValue>.unmodifiable(originPath),
      initialColumnId: initialColumnId,
      originIndex: originIndex,
      originQueryRevision: originQueryRevision,
    );
    _items[id] = d;
    _emit(KDataTableDraftEventType.started, d, 'programmatic');
  }

  bool update(String id, T row, {String reason = 'programmatic'}) {
    final d = _items[id];
    if (_disposed || d == null || d.status == KDataTableDraftStatus.saving) {
      return false;
    }
    if (rowId(row) != id) throw ArgumentError('Draft identity cannot change');
    final next = KDataTableDraftSnapshot(
      id: id,
      baseline: d.baseline,
      current: cloneRow(row),
      status: isEqual(d.baseline, row)
          ? KDataTableDraftStatus.pristine
          : KDataTableDraftStatus.dirty,
      originPath: d.originPath,
      initialColumnId: d.initialColumnId,
      originIndex: d.originIndex,
      originQueryRevision: d.originQueryRevision,
    );
    _items[id] = next;
    _emit(KDataTableDraftEventType.changed, next, reason);
    return true;
  }

  Future<bool> commit(String id, {String reason = 'programmatic'}) {
    if (_pending[id] case final future?) return future;
    final d = _items[id];
    if (_disposed || d == null) return Future.value(false);
    final completer = Completer<bool>();
    _pending[id] = completer.future;
    final saving = KDataTableDraftSnapshot(
      id: id,
      baseline: d.baseline,
      current: d.current,
      status: KDataTableDraftStatus.saving,
      originPath: d.originPath,
      initialColumnId: d.initialColumnId,
      originIndex: d.originIndex,
      originQueryRevision: d.originQueryRevision,
    );
    _items[id] = saving;
    _emit(KDataTableDraftEventType.commitRequested, saving, reason);
    Future<T>.sync(() => onCommit(cloneRow(saving.current), _copy(saving)))
        .then((accepted) {
          if (_disposed || !identical(_items[id], saving)) {
            completer.complete(false);
            return;
          }
          if (rowId(accepted) != id) {
            throw StateError('Saved row identity must remain stable');
          }
          _items.remove(id);
          _leases.remove(id);
          _pending.remove(id);
          _emit(
            KDataTableDraftEventType.committed,
            saving,
            reason,
            acceptedRow: accepted,
          );
          completer.complete(true);
        })
        .catchError((Object error, StackTrace stack) {
          if (!_disposed && identical(_items[id], saving)) {
            final failed = KDataTableDraftSnapshot(
              id: id,
              baseline: d.baseline,
              current: d.current,
              status: KDataTableDraftStatus.error,
              originPath: d.originPath,
              initialColumnId: d.initialColumnId,
              originIndex: d.originIndex,
              originQueryRevision: d.originQueryRevision,
              error: error,
            );
            _items[id] = failed;
            _pending.remove(id);
            _emit(KDataTableDraftEventType.error, failed, reason, error: error);
          }
          if (!completer.isCompleted) completer.complete(false);
        })
        .whenComplete(() {
          if (identical(_pending[id], completer.future)) _pending.remove(id);
        });
    return completer.future;
  }

  bool cancel(String id, {String reason = 'programmatic'}) {
    final d = _items[id];
    if (_disposed || d == null || d.status == KDataTableDraftStatus.saving) {
      return false;
    }
    _items.remove(id);
    _leases.remove(id);
    _emit(KDataTableDraftEventType.cancelled, d, reason);
    return true;
  }

  Future<bool> leave(String id) {
    final d = _items[id];
    if (_disposed ||
        d == null ||
        (_leases[id] ?? 0) > 0 ||
        d.status == KDataTableDraftStatus.saving) {
      return Future.value(false);
    }
    if (isEqual(d.baseline, d.current)) {
      return Future.value(cancel(id, reason: 'rowExit'));
    }
    if (savePolicy == KDataTableDraftSavePolicy.rowExit) {
      return commit(id, reason: 'rowExit');
    }
    return Future.value(false);
  }

  /// Own a portal/modal interaction. Release after focus has returned to its row.
  VoidCallback retainInteraction(String id) {
    if (_disposed || !_items.containsKey(id)) return () {};
    _leases[id] = (_leases[id] ?? 0) + 1;
    var released = false;
    return () {
      if (released) return;
      released = true;
      final remaining = (_leases[id] ?? 1) - 1;
      if (remaining <= 0) {
        _leases.remove(id);
      } else {
        _leases[id] = remaining;
      }
    };
  }

  @override
  void dispose() {
    _disposed = true;
    _items.clear();
    _leases.clear();
    super.dispose();
  }
}
