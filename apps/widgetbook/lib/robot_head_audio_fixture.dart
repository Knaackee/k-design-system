import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'robot_head_wav.dart';

typedef RobotHeadAudioSourceChanged =
    void Function(KRobotHeadAudioFrame Function()? source);

/// Consumer-owned local playback and analysis for the RobotHead gallery only.
class RobotHeadAudioFixture extends StatefulWidget {
  const RobotHeadAudioFixture({
    required this.onSourceChanged,
    required this.onPlayingChanged,
    super.key,
  });

  final RobotHeadAudioSourceChanged onSourceChanged;
  final ValueChanged<bool> onPlayingChanged;

  @override
  State<RobotHeadAudioFixture> createState() => _RobotHeadAudioFixtureState();
}

class _RobotHeadAudioFixtureState extends State<RobotHeadAudioFixture> {
  static const _silence = KRobotHeadAudioFrame(
    level: 0,
    bands: <double>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  );
  static const _wavTypes = XTypeGroup(
    label: 'Uncompressed PCM WAV',
    extensions: <String>['wav'],
    mimeTypes: <String>['audio/wav', 'audio/x-wav'],
    uniformTypeIdentifiers: <String>['com.microsoft.waveform-audio'],
  );

  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  RobotHeadWav? _wav;
  KRobotHeadAudioFrame _frame = _silence;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String _fileName = '';
  String _status = 'Noch keine Datei ausgewählt.';
  bool _loading = false;

  bool get _isPlaying => _playerState == PlayerState.playing;
  bool get _hasAudio => _wav != null;
  KRobotHeadAudioFrame _readFrame() => _isPlaying ? _frame : _silence;

  @override
  void initState() {
    super.initState();
    _subscriptions.addAll([
      _player.onPositionChanged.listen(_handlePosition),
      _player.onDurationChanged.listen((duration) {
        if (mounted) setState(() => _duration = duration);
      }),
      _player.onPlayerStateChanged.listen((state) {
        if (!mounted) return;
        final changed = _isPlaying != (state == PlayerState.playing);
        setState(() {
          _playerState = state;
          if (state != PlayerState.playing) _frame = _silence;
        });
        if (changed) widget.onPlayingChanged(state == PlayerState.playing);
      }),
      _player.onPlayerComplete.listen((_) {
        if (!mounted) return;
        setState(() {
          _position = _duration;
          _frame = _silence;
          _status = 'Wiedergabe beendet.';
        });
        widget.onPlayingChanged(false);
      }),
    ]);
    unawaited(_player.setReleaseMode(ReleaseMode.stop));
  }

  void _handlePosition(Duration position) {
    if (!mounted) return;
    final wav = _wav;
    setState(() {
      _position = position;
      _frame = wav?.frameAt(position) ?? _silence;
    });
  }

  Future<void> _pickFile() async {
    setState(() {
      _loading = true;
      _status = 'Dateiauswahl wird geöffnet …';
    });
    try {
      final file = await openFile(acceptedTypeGroups: const [_wavTypes]);
      if (file == null || !mounted) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final bytes = await file.readAsBytes();
      final wav = RobotHeadWav.parse(bytes);
      await _player.stop();
      await _player.setSource(BytesSource(bytes, mimeType: 'audio/wav'));
      if (!mounted) return;
      setState(() {
        _wav = wav;
        _frame = _silence;
        _position = Duration.zero;
        _duration = wav.duration;
        _fileName = file.name;
        _status = 'PCM-WAV bereit. Die Analyse folgt der echten Wiedergabe.';
        _loading = false;
      });
      widget.onSourceChanged(_readFrame);
      widget.onPlayingChanged(false);
    } on FormatException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Die Datei konnte nicht geöffnet oder abgespielt werden.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    unawaited(_player.stop());
    setState(() {
      _wav = null;
      _frame = _silence;
      _fileName = '';
      _loading = false;
      _status = message;
    });
    widget.onSourceChanged(null);
    widget.onPlayingChanged(false);
  }

  Future<void> _togglePlayback() async {
    if (!_hasAudio) return;
    try {
      if (_isPlaying) {
        await _player.pause();
        if (mounted) setState(() => _status = 'Wiedergabe pausiert.');
      } else {
        if (_position >= _duration && _duration > Duration.zero) {
          await _player.seek(Duration.zero);
        }
        await _player.resume();
        if (mounted) setState(() => _status = 'Audio läuft.');
      }
    } catch (_) {
      _showError(
        'Wiedergabe fehlgeschlagen. Bitte eine andere PCM-WAV-Datei wählen.',
      );
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _position = Duration.zero;
      _frame = _silence;
      _status = 'Wiedergabe gestoppt.';
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final maxMs = _duration.inMilliseconds
        .toDouble()
        .clamp(1, double.infinity)
        .toDouble();
    final positionMs = _position.inMilliseconds
        .toDouble()
        .clamp(0, maxMs)
        .toDouble();
    return KSurface(
      tone: KSurfaceTone.subtle,
      radius: KSurfaceRadius.card,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const KText('Lokale Audiodatei', variant: KTextVariant.heading4),
            SizedBox(height: tokens.spaceContentActionGap),
            const KText(
              'Demo-Einschränkung: nur unkomprimierte PCM-WAV-Dateien. '
              'Die Datei bleibt lokal; andere Formate werden sichtbar abgelehnt.',
              variant: KTextVariant.bodySmall,
            ),
            SizedBox(height: tokens.spaceContentActionGap),
            Wrap(
              spacing: tokens.spaceControlGap,
              runSpacing: tokens.spaceControlGap,
              children: [
                KButton(
                  label: _loading ? 'Wird geöffnet …' : 'PCM-WAV auswählen',
                  onPressed: _loading ? null : _pickFile,
                ),
                KButton(
                  label: _isPlaying ? 'Pause' : 'Abspielen',
                  variant: KButtonVariant.secondary,
                  onPressed: _hasAudio && !_loading ? _togglePlayback : null,
                ),
                KButton(
                  label: 'Stopp',
                  variant: KButtonVariant.ghost,
                  onPressed: _hasAudio ? _stop : null,
                ),
              ],
            ),
            if (_fileName.isNotEmpty) ...[
              SizedBox(height: tokens.spaceContentActionGap),
              KText(_fileName, variant: KTextVariant.label),
              KSlider(
                label: 'Wiedergabeposition',
                min: 0,
                max: maxMs,
                value: positionMs,
                valueLabel: (value) =>
                    _format(Duration(milliseconds: value.round())),
                onChanged: (value) =>
                    _player.seek(Duration(milliseconds: value.round())),
              ),
              KText(
                '${_format(_position)} / ${_format(_duration)}',
                variant: KTextVariant.bodySmall,
              ),
            ],
            SizedBox(height: tokens.spaceContentActionGap),
            Semantics(liveRegion: true, child: KText(_status)),
          ],
        ),
      ),
    );
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
