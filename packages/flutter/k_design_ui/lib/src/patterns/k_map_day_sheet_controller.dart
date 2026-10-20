import 'package:flutter/foundation.dart';

import 'k_map_day_types.dart';

/// Controls the persistent mobile sheet rendered by [KMapDayView].
///
/// [fraction] always reports the actual visible extent. [state] is non-null
/// only while that extent exactly matches one of the configured named snaps.
class KMapDaySheetController extends ChangeNotifier {
  double _fraction = 0;
  KMapDayPanelState? _state;
  KMapDaySheetBinding? _binding;

  double get fraction => _fraction;
  KMapDayPanelState? get state => _state;
  bool get isAttached => _binding != null;
  bool get isSheet => _binding?.isSheet ?? false;

  Future<void> animateTo(double fraction) {
    if (!fraction.isFinite || fraction < 0 || fraction > 1) {
      throw RangeError.range(fraction, 0, 1, 'fraction');
    }
    return _binding?.animateTo(fraction) ?? Future<void>.value();
  }

  Future<void> snapTo(KMapDayPanelState state) =>
      _binding?.snapTo(state) ?? Future<void>.value();

  void attach(KMapDaySheetBinding binding) {
    assert(_binding == null || identical(_binding, binding));
    _binding = binding;
    _setPosition(binding.fraction, binding.state, notify: false);
  }

  void detach(KMapDaySheetBinding binding) {
    if (identical(_binding, binding)) _binding = null;
  }

  void updatePosition(double fraction, KMapDayPanelState? state) =>
      _setPosition(fraction, state, notify: true);

  void _setPosition(
    double fraction,
    KMapDayPanelState? state, {
    required bool notify,
  }) {
    if ((_fraction - fraction).abs() <= 1e-6 && _state == state) return;
    _fraction = fraction;
    _state = state;
    if (notify) notifyListeners();
  }
}

class KMapDaySheetBinding {
  KMapDaySheetBinding({
    required this.fraction,
    required this.state,
    required this.isSheet,
    required this.animateTo,
    required this.snapTo,
  });

  double fraction;
  KMapDayPanelState? state;
  bool isSheet;
  final Future<void> Function(double fraction) animateTo;
  final Future<void> Function(KMapDayPanelState state) snapTo;
}
