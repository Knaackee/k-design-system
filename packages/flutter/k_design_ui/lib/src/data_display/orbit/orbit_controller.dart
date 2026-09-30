import 'package:flutter/foundation.dart';

import 'orbit_models.dart';

typedef KOrbitSignalTrigger =
    KOrbitSignalTriggerResult Function(KOrbitSignal signal);
typedef KOrbitSignalCancel = bool Function(String id);

class KOrbitController {
  KOrbitSignalTrigger? _trigger;
  KOrbitSignalCancel? _cancel;
  VoidCallback? _cancelAll;
  VoidCallback? _resetView;

  KOrbitSignalTriggerResult triggerSignal(KOrbitSignal signal) =>
      _trigger?.call(signal) ?? KOrbitSignalTriggerResult.inactive;

  bool cancelSignal(String id) => _cancel?.call(id) ?? false;

  void cancelAllSignals() => _cancelAll?.call();

  void resetView() => _resetView?.call();

  void attach({
    required KOrbitSignalTrigger trigger,
    required KOrbitSignalCancel cancel,
    required VoidCallback cancelAll,
    required VoidCallback resetView,
  }) {
    _trigger = trigger;
    _cancel = cancel;
    _cancelAll = cancelAll;
    _resetView = resetView;
  }

  void detach() {
    _trigger = null;
    _cancel = null;
    _cancelAll = null;
    _resetView = null;
  }
}
