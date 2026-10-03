import 'package:flutter/material.dart';
import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';

enum KDictationState { ready, recording, processing, unavailable, error }

/// Presentation only. Consumers own recording, permission and transcription.
class KDictationAction extends StatelessWidget {
  const KDictationAction({
    required this.state,
    required this.label,
    this.onPressed,
    super.key,
  });

  final KDictationState state;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: state == KDictationState.recording,
    liveRegion: state == KDictationState.processing,
    child: KIconButton(
      label: label,
      icon: switch (state) {
        KDictationState.ready => KIconName.mic,
        KDictationState.recording => KIconName.square,
        KDictationState.processing => KIconName.loaderCircle,
        KDictationState.unavailable => KIconName.micOff,
        KDictationState.error => KIconName.circleAlert,
      },
      selected: state == KDictationState.recording,
      onPressed:
          state == KDictationState.processing ||
              state == KDictationState.unavailable
          ? null
          : onPressed,
    ),
  );
}
