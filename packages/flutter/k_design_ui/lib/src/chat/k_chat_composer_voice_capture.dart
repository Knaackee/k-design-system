part of 'k_chat_composer.dart';

class _KChatVoiceCaptureView extends StatelessWidget {
  const _KChatVoiceCaptureView({
    required this.state,
    required this.samples,
    required this.processingLabel,
    required this.recordingLabel,
    required this.errorLabel,
  });

  final KDictationState state;
  final List<double> samples;
  final String processingLabel;
  final String recordingLabel;
  final String errorLabel;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    if (state == KDictationState.recording) {
      return Semantics(
        liveRegion: true,
        label: recordingLabel,
        child: SizedBox(
          key: const ValueKey('k-chat-composer-voice-waveform'),
          width: double.infinity,
          height: math.min(t.sizeHitTarget, t.sizeIconDefault * 1.5),
          child: CustomPaint(
            painter: _KChatVoiceWaveformPainter(
              samples: List<double>.of(samples),
              color: t.colorTextMuted,
              strokeWidth: t.borderWidthStrong,
            ),
          ),
        ),
      );
    }
    final error = state == KDictationState.error;
    final content = Row(
      key: ValueKey(
        error
            ? 'k-chat-composer-voice-error'
            : 'k-chat-composer-voice-processing',
      ),
      children: [
        error
            ? const KIcon(KIconName.circleAlert)
            : const KDictationPulse(child: KIcon(KIconName.loaderCircle)),
        SizedBox(width: t.spaceControlGap),
        Expanded(
          child: Text(
            error ? errorLabel : processingLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: t.colorTextMuted,
              fontSize: t.fontBodySmallSize,
            ),
          ),
        ),
      ],
    );
    return Semantics(
      liveRegion: true,
      label: error ? errorLabel : processingLabel,
      child: ExcludeSemantics(child: content),
    );
  }
}

class _KChatVoiceWaveformPainter extends CustomPainter {
  const _KChatVoiceWaveformPainter({
    required this.samples,
    required this.color,
    required this.strokeWidth,
  });

  final List<double> samples;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    const count = 80;
    final visible = samples.length > count
        ? samples.sublist(samples.length - count)
        : samples;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final step = size.width / count;
    for (var index = 0; index < count; index++) {
      final sample = index < visible.length ? visible[index] : 0.0;
      // Display quiet speech on a decibel scale without amplifying recorded audio.
      final level = sample.isFinite && sample > 0
          ? ((20 * math.log(sample.clamp(0.000001, 1.0)) / math.ln10 + 60) / 48)
                .clamp(0.0, 1.0)
          : 0.0;
      final minimum = strokeWidth / 2;
      final halfHeight = minimum + level * (size.height / 2 - minimum);
      final x = step * (index + .5);
      canvas.drawLine(
        Offset(x, size.height / 2 - halfHeight),
        Offset(x, size.height / 2 + halfHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KChatVoiceWaveformPainter oldDelegate) =>
      samples != oldDelegate.samples ||
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth;
}
