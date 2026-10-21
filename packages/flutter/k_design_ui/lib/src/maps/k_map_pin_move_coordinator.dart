import 'dart:async';
import 'package:flutter/foundation.dart';
import 'k_map_overlays.dart';

@visibleForTesting
class KMapPinMoveCoordinator {
  int _revision = 0;

  void invalidate() => _revision += 1;

  Future<void> commit({
    required KMapPinMoveCallback? callback,
    required KMapPinMove event,
    required FutureOr<void> Function() rollback,
  }) async {
    final request = ++_revision;
    try {
      final accepted = await callback?.call(event);
      if (accepted == false && request == _revision) {
        await rollback();
      }
    } on Object {
      if (request == _revision) await rollback();
    }
  }
}
