import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Haptic cues shared with Web (Decision 0013).
///
/// Use them sparingly and always together with visible feedback:
/// - [selection]: a value changed in a picker, segmented control, menu or
///   switcher (UIKit `UISelectionFeedbackGenerator`).
/// - [light], [medium], [heavy]: a physical-feeling event such as a toggle
///   snapping, a drag landing or a sheet reaching its detent.
/// - [success], [warning], [error]: the outcome of an action the person
///   started (UIKit `UINotificationFeedbackGenerator`).
///
/// Never for scrolling, hover, typing or anything that repeats quickly.
enum KHapticCue { selection, light, medium, heavy, success, warning, error }

/// Injectable transport for deterministic tests and custom engines.
abstract interface class KHapticBackend {
  Future<void> perform(KHapticCue cue);
}

/// Platform haptics. iOS and Android apply the person's system setting
/// (System Haptics / Touch feedback) themselves.
class _PlatformHapticBackend implements KHapticBackend {
  const _PlatformHapticBackend();
  @override
  Future<void> perform(KHapticCue cue) => switch (cue) {
    KHapticCue.selection => HapticFeedback.selectionClick(),
    KHapticCue.light => HapticFeedback.lightImpact(),
    KHapticCue.medium => HapticFeedback.mediumImpact(),
    KHapticCue.heavy => HapticFeedback.heavyImpact(),
    KHapticCue.success => HapticFeedback.successNotification(),
    KHapticCue.warning => HapticFeedback.warningNotification(),
    KHapticCue.error => HapticFeedback.errorNotification(),
  };
}

/// Off by default. The host app decides whether haptics are on (usually a
/// setting the person controls) and persists that choice.
class KHapticController extends ChangeNotifier with WidgetsBindingObserver {
  KHapticController({
    bool enabled = false,
    KHapticBackend? backend,
    this.minInterval = const Duration(milliseconds: 60),
    // ignore: prefer_initializing_formals
  }) : _enabled = enabled,
       _backend = backend ?? const _PlatformHapticBackend() {
    WidgetsBinding.instance.addObserver(this);
  }

  final KHapticBackend _backend;

  /// Cues closer together than this are dropped, so a burst of changes
  /// (dragging through a picker) never buzzes continuously.
  final Duration minInterval;

  bool _enabled, _disposed = false, _foreground = true;
  final Stopwatch _since = Stopwatch();
  bool get enabled => _enabled;

  void setEnabled(bool value) {
    if (_disposed || value == _enabled) return;
    _enabled = value;
    notifyListeners();
  }

  /// Plays [cue] when enabled, in the foreground and outside [minInterval].
  /// Failures are contained; haptics never break an interaction.
  Future<void> perform(KHapticCue cue) async {
    if (_disposed || !_enabled || !_foreground) return;
    if (_since.isRunning && _since.elapsed < minInterval) return;
    _since
      ..reset()
      ..start();
    try {
      await _backend.perform(cue);
    } catch (_) {
      /* Haptics are supplementary. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class KHapticsProvider extends InheritedNotifier<KHapticController> {
  const KHapticsProvider({
    super.key,
    required KHapticController controller,
    required super.child,
  }) : super(notifier: controller);

  static KHapticController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KHapticsProvider>()?.notifier;
  static KHapticController of(BuildContext context) => maybeOf(context)!;
}

/// Plays [cue] through the nearest [KHapticsProvider], if any. Safe to call
/// from event handlers (it does not register a dependency).
void kHaptic(BuildContext context, KHapticCue cue) {
  final haptics = context
      .getInheritedWidgetOfExactType<KHapticsProvider>()
      ?.notifier;
  if (haptics != null) unawaited(haptics.perform(cue));
}
