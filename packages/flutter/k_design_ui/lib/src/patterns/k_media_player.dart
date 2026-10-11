import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../primitives/k_icon.dart';

/// Playback is controlled by the host, including decoding and URL renewal.
class KMediaPlayer extends StatelessWidget {
  const KMediaPlayer({
    required this.name,
    required this.playing,
    required this.position,
    required this.duration,
    required this.volume,
    required this.onPlayPause,
    required this.onSeek,
    required this.onVolume,
    this.preview,
    this.loading = false,
    this.error,
    this.onRetry,
    super.key,
  });
  final String name;
  final bool playing, loading;
  final Duration position, duration;
  final double volume;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onVolume;
  final Widget? preview;
  final String? error;
  final VoidCallback? onRetry;
  static String time(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      label: name,
      child: Container(
        padding: EdgeInsets.all(tokens.spaceLayoutGutter),
        decoration: BoxDecoration(
          color: tokens.colorSurfaceRaised,
          borderRadius: BorderRadius.circular(tokens.radiusCard),
        ),
        child: Column(
          children: [
            if (preview != null)
              preview!
            else
              Padding(
                padding: EdgeInsets.all(tokens.spaceLayoutSectionGap),
                child: KIcon(KIconName.fileVolume, size: 48),
              ),
            if (loading) const LinearProgressIndicator(),
            if (error != null) Text(error!),
            if (error != null && onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Erneut laden')),
            Row(
              children: [
                IconButton(
                  tooltip: playing ? 'Pausieren' : 'Abspielen',
                  onPressed: loading || error != null ? null : onPlayPause,
                  icon: KIcon(playing ? KIconName.pause : KIconName.play),
                ),
                Text(time(position)),
                Expanded(
                  child: Slider(
                    semanticFormatterCallback: (value) =>
                        time(Duration(milliseconds: value.round())),
                    value: position.inMilliseconds
                        .clamp(0, duration.inMilliseconds)
                        .toDouble(),
                    max: duration.inMilliseconds > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1,
                    onChanged: duration.inMilliseconds > 0
                        ? (value) =>
                              onSeek(Duration(milliseconds: value.round()))
                        : null,
                  ),
                ),
                Text(time(duration)),
                IconButton(
                  tooltip: volume == 0 ? 'Ton einschalten' : 'Stummschalten',
                  onPressed: () => onVolume(volume == 0 ? 1 : 0),
                  icon: KIcon(
                    volume == 0 ? KIconName.volumeX : KIconName.volume2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
