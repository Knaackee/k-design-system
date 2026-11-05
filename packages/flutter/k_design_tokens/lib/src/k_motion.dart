import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'generated/k_design_tokens.g.dart';

/// What moves (Decision 0011). Components pick a role, never a duration.
enum KMotionRole {
  /// Press, hover and focus feedback.
  feedback,

  /// State changes of a control: toggle, select, expand, reorder.
  control,

  /// Something appears: sheet, dialog, popover, toast.
  enter,

  /// Something leaves. Shorter than [enter] and never bouncy.
  exit,

  /// Navigation between screens and tab content.
  page,

  /// Rare emphasis: a completed goal, a celebration.
  attention,
}

/// The resolved motion of one role: a spring given by perceptual duration
/// and bounce, the same model as SwiftUI and the Web tokens' `linear()`
/// easing, so both platforms move identically.
@immutable
class KMotionSpec {
  const KMotionSpec({
    required this.duration,
    required this.bounce,
    required this.distance,
  });

  /// Perceptual duration (time to visually arrive).
  final Duration duration;

  /// 0 = no overshoot; 0.4 = playful overshoot.
  final double bounce;

  /// Multiplier for travelled distance: 1 = full movement, 0 = fade only
  /// (reduced motion). Multiply slide offsets and scale deltas with it.
  final double distance;

  /// Spring for physics-driven animations (`AnimationController.animateWith`).
  SpringDescription get spring => SpringDescription.withDurationAndBounce(
    duration: duration.inMicroseconds == 0
        ? const Duration(milliseconds: 1)
        : duration,
    bounce: bounce,
  );

  /// Time until the spring rests within 0.1 % of its target. Use it as the
  /// `duration` of implicit animations together with [curve].
  Duration get settle {
    final simulation = SpringSimulation(spring, 0, 1, 0);
    var time = 0.0;
    var settled = 0.0;
    final limit = duration.inMicroseconds / 1e6 * 6;
    while (time <= limit) {
      if ((1 - simulation.x(time)).abs() > 0.001) settled = time + 0.002;
      time += 0.002;
    }
    return Duration(microseconds: (settled * 1e6).round().clamp(1000, 1 << 31));
  }

  /// The spring as a [Curve] over [settle], for implicit animations and
  /// transitions that take a duration and a curve.
  Curve get curve => _KSpringCurve(spring, settle);
}

class _KSpringCurve extends Curve {
  const _KSpringCurve(this.spring, this.settle);

  final SpringDescription spring;
  final Duration settle;

  @override
  double transformInternal(double t) {
    final seconds = settle.inMicroseconds / 1e6 * t;
    return SpringSimulation(spring, 0, 1, 0).x(seconds);
  }
}

/// Motion lookup from the resolved tokens of the current theme.
extension KMotionTokens on KDesignTokens {
  KMotionSpec motion(KMotionRole role) => switch (role) {
    KMotionRole.feedback => KMotionSpec(
      duration: motionFeedbackDuration,
      bounce: motionFeedbackBounce,
      distance: motionFeedbackDistance,
    ),
    KMotionRole.control => KMotionSpec(
      duration: motionControlDuration,
      bounce: motionControlBounce,
      distance: motionControlDistance,
    ),
    KMotionRole.enter => KMotionSpec(
      duration: motionEnterDuration,
      bounce: motionEnterBounce,
      distance: motionEnterDistance,
    ),
    KMotionRole.exit => KMotionSpec(
      duration: motionExitDuration,
      bounce: motionExitBounce,
      distance: motionExitDistance,
    ),
    KMotionRole.page => KMotionSpec(
      duration: motionPageDuration,
      bounce: motionPageBounce,
      distance: motionPageDistance,
    ),
    KMotionRole.attention => KMotionSpec(
      duration: motionAttentionDuration,
      bounce: motionAttentionBounce,
      distance: motionAttentionDistance,
    ),
  };
}
