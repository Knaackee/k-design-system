import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';

/// Stable cue IDs shared with Web. Hosts own event mapping and persistence.
enum KSoundCue {
  tick,
  hover,
  glide,
  pop,
  press,
  release,
  tap,
  thock,
  on,
  off,
  switchCue,
  latch,
  success,
  error,
  warning,
  denied,
  chime,
  ping,
  bell,
  bubble,
  swoosh,
  whoosh,
  drop,
  rise,
  loading,
  ready,
  complete,
  sparkle;

  String get id => this == switchCue ? 'switch' : name;
}

/// Injectable transport for deterministic tests and platform-specific playback.
abstract interface class KSoundBackend {
  /// Recheck [isCurrent] after asynchronous preparation, before starting audio.
  Future<void> play(
    KSoundCue cue,
    double volume, {
    required bool Function() isCurrent,
  });
  Future<void> stop();
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

class _AssetSoundBackend implements KSoundBackend {
  AudioPlayer? _instance;
  AudioPlayer get _player =>
      _instance ??= (AudioPlayer()..audioCache = AudioCache(prefix: ''));
  @override
  Future<void> play(
    KSoundCue cue,
    double volume, {
    required bool Function() isCurrent,
  }) async {
    await _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ),
    );
    if (!isCurrent()) return;
    await _player.setSource(
      AssetSource('packages/k_design_ui/assets/foley/${cue.id}.wav'),
    );
    if (!isCurrent()) return;
    await _player.setVolume(volume);
    if (!isCurrent()) return;
    await _player.resume();
    if (!isCurrent()) await _player.stop();
  }

  @override
  Future<void> stop() async {
    await _instance?.stop();
  }

  @override
  Future<void> setVolume(double volume) async {
    await _instance?.setVolume(volume);
  }

  @override
  Future<void> dispose() async {
    await _instance?.dispose();
  }
}

/// One non-blocking player: newer cues replace older ones, never overlap.
/// Audio failures are intentionally contained; visual feedback remains primary.
class KSoundController extends ChangeNotifier with WidgetsBindingObserver {
  // Keep the public constructor parameter independent of private state.
  KSoundController({
    bool enabled = false,
    double volume = .25,
    KSoundBackend? backend,
    // ignore: prefer_initializing_formals
  }) : _enabled = enabled,
       _volume = _clamp(volume),
       _backend = backend ?? _AssetSoundBackend() {
    WidgetsBinding.instance.addObserver(this);
  }
  final KSoundBackend _backend;
  bool _enabled, _disposed = false, _foreground = true;
  double _volume;
  int _request = 0;
  Future<void> _pending = Future.value();
  final _events = <String>{};
  bool get enabled => _enabled;
  double get volume => _volume;
  static double _clamp(double value) =>
      value.isFinite ? value.clamp(0, 1).toDouble() : 0;

  void setEnabled(bool value) {
    if (_disposed || value == _enabled) return;
    _enabled = value;
    if (!value) unawaited(stop());
    notifyListeners();
  }

  void setVolume(double value) {
    if (_disposed) return;
    _volume = _clamp(value);
    if (_volume == 0) {
      unawaited(stop());
    } else {
      unawaited(_backend.setVolume(_volume).catchError((Object _) {}));
    }
    notifyListeners();
  }

  Future<void> play(KSoundCue cue, {String? eventId}) {
    if (_disposed || !_enabled || !_foreground || _volume == 0) {
      return Future.value();
    }
    if (eventId != null) {
      if (!_events.add(eventId)) return Future.value();
      if (_events.length > 128) _events.remove(_events.first);
    }
    final request = ++_request;
    return _pending = _pending.then((_) async {
      if (_disposed || request != _request) return;
      try {
        await _backend.stop();
        if (_disposed || request != _request || !_enabled || !_foreground) {
          return;
        }
        await _backend.play(
          cue,
          _volume,
          isCurrent: () =>
              !_disposed &&
              request == _request &&
              _enabled &&
              _foreground &&
              _volume > 0,
        );
      } catch (_) {
        /* Sound must never break an interaction. */
      }
    });
  }

  Future<void> stop() {
    _request++;
    if (_disposed) return Future.value();
    unawaited(_backend.setVolume(0).catchError((Object _) {}));
    return _pending = _pending.then((_) async {
      try {
        await _backend.stop();
      } catch (_) {}
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) unawaited(stop());
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _request++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(
      _pending.then((_) => _backend.dispose()).catchError((Object _) {}),
    );
    super.dispose();
  }
}

class KSoundProvider extends InheritedNotifier<KSoundController> {
  const KSoundProvider({
    super.key,
    required KSoundController controller,
    required super.child,
  }) : super(notifier: controller);
  static KSoundController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KSoundProvider>()?.notifier;
  static KSoundController of(BuildContext context) => maybeOf(context)!;
}

class KSoundToggle extends StatelessWidget {
  const KSoundToggle({
    super.key,
    required this.enabled,
    required this.onEnabledChanged,
    this.labelEnable = 'Enable sounds',
    this.labelDisable = 'Mute sounds',
  });
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final String labelEnable, labelDisable;
  @override
  Widget build(BuildContext context) => KIconButton(
    icon: enabled ? KIconName.volume2 : KIconName.volumeOff,
    label: enabled ? labelDisable : labelEnable,
    onPressed: () => onEnabledChanged(!enabled),
  );
}
