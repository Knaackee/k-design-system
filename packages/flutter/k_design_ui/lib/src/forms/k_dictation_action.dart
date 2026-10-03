import 'dart:math' as math;
import 'form_style.dart';
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
      iconContent:
          state == KDictationState.recording ||
              state == KDictationState.processing
          ? KDictationPulse(
              child: KIcon(
                state == KDictationState.recording
                    ? KIconName.square
                    : KIconName.loaderCircle,
              ),
            )
          : null,
      selected: state == KDictationState.recording,
      onPressed:
          state == KDictationState.processing ||
              state == KDictationState.unavailable
          ? null
          : onPressed,
    ),
  );
}

/// Visual feedback only; consumers own the saved text offset and transcription.
class KDictationAnchor extends StatelessWidget {
  const KDictationAnchor({required this.state, super.key});
  final KDictationState state;
  @override
  Widget build(BuildContext context) {
    if (state != KDictationState.recording &&
        state != KDictationState.processing) {
      return const SizedBox.shrink();
    }
    final t = formTokens(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.colorSurfaceRaised,
            borderRadius: BorderRadius.circular(t.radiusSmall),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: t.spaceMicro),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < 3; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : t.spaceMicro,
                    ),
                    child: KDictationPulse(
                      phase: index / 3,
                      child: Container(
                        width: t.spaceMicro,
                        height: t.spaceMicro,
                        decoration: BoxDecoration(
                          color: t.colorBorderFocus,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Token-paced pulse with a static reduced-motion presentation.
class KDictationPulse extends StatefulWidget {
  const KDictationPulse({required this.child, this.phase = 0, super.key});
  final Widget child;
  final double phase;
  @override
  State<KDictationPulse> createState() => _KDictationPulseState();
}

class _KDictationPulseState extends State<KDictationPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(vsync: this);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animation.duration = formTokens(context).motionSpinner;
    if (MediaQuery.disableAnimationsOf(context)) {
      _animation.stop();
    } else {
      _animation.repeat();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    final minimum = formTokens(context).opacityDisabled;
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: disabled
            ? 1
            : minimum +
                  (1 - minimum) *
                      (1 +
                          math.cos(
                            (_animation.value - widget.phase) * math.pi * 2,
                          )) /
                      2,
        child: child,
      ),
    );
  }
}
