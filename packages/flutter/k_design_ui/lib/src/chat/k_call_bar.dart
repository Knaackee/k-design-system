import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../actions/k_icon_button.dart';
import '../primitives/k_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_text.dart';
import 'dart:math' as math;

/// Consumer controlled call status and measured microphone amplitude.
class KCallBar extends StatelessWidget {
  const KCallBar({
    required this.name,
    required this.status,
    required this.duration,
    required this.muted,
    required this.microphoneLevel,
    required this.onMutedChanged,
    this.regionLabel = 'Call',
    this.durationLabel = 'Call duration',
    this.muteLabel = 'Mute microphone',
    this.unmuteLabel = 'Unmute microphone',
    this.expanded = false,
    this.avatar,
    this.avatarOrigin,
    this.onExpandedChanged,
    this.onEndCall,
    this.minimizeLabel = 'Back to chat',
    this.expandLabel = 'Open call',
    this.endLabel = 'End call',
    super.key,
  });
  final String name,
      status,
      duration,
      regionLabel,
      durationLabel,
      muteLabel,
      unmuteLabel,
      minimizeLabel,
      expandLabel,
      endLabel;
  final bool expanded;
  final Widget? avatar;

  /// Global character bounds captured by a consumer before entering a call.
  final Rect? avatarOrigin;
  final ValueChanged<bool>? onExpandedChanged;
  final VoidCallback? onEndCall;
  final bool muted;
  final double microphoneLevel;
  final ValueChanged<bool>? onMutedChanged;
  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final amplitude = muted || !microphoneLevel.isFinite
        ? 0.0
        : microphoneLevel.clamp(0.0, 1.0);
    final level = amplitude == 0
        ? 0.0
        : ((20 * math.log(amplitude) / math.log(10) + 60) / 60).clamp(0.0, 1.0);
    if (expanded) {
      return Semantics(
        label: regionLabel,
        container: true,
        child: LayoutBuilder(
          builder: (context, bounds) {
            final size = math.min(
              340.0,
              math.min(
                MediaQuery.sizeOf(context).width * .64,
                bounds.maxHeight * .40,
              ),
            );
            return ColoredBox(
              color: t.colorSurfaceCanvas,
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(t.spaceLayoutGutter),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (avatar != null)
                              ExcludeSemantics(
                                child: _CallAvatarMotion(
                                  origin: avatarOrigin,
                                  child: SizedBox.square(
                                    dimension: size,
                                    child: FittedBox(child: avatar!),
                                  ),
                                ),
                              ),
                            SizedBox(height: t.spaceControlGap),
                            _CallEntryMotion(
                              delay: 220,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  KText(
                                    name,
                                    style: TextStyle(
                                      fontSize: t.fontHeading2Size,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: t.spaceControlGap),
                                  Semantics(
                                    liveRegion: true,
                                    child: KText(
                                      status,
                                      style: TextStyle(color: t.colorTextMuted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: t.spaceControlGap),
                            _CallEntryMotion(
                              delay: 280,
                              child: ExcludeSemantics(
                                child: SizedBox(
                                  height: t.sizeIconDefault,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (var i = 0; i < 25; i++)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            left: t.spaceControlGap / 4,
                                          ),
                                          child: Container(
                                            width: t.spaceControlGap / 4,
                                            height:
                                                t.sizeIconDefault *
                                                (.125 +
                                                    .875 *
                                                        level *
                                                        (.3 +
                                                            .7 *
                                                                math
                                                                    .sin(
                                                                      i * 1.7,
                                                                    )
                                                                    .abs())),
                                            color: muted
                                                ? t.colorTextMuted.withValues(
                                                    alpha: t.opacityDisabled,
                                                  )
                                                : t.colorStatusSuccessAccent,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: t.spaceControlGap),
                            _CallEntryMotion(
                              delay: 340,
                              child: Semantics(
                                label: '$durationLabel: $duration',
                                child: ExcludeSemantics(
                                  child: KText(
                                    duration,
                                    style: const TextStyle(
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: t.spaceLayoutGutter + t.spaceControlGap,
                            ),
                            _CallEntryMotion(
                              delay: 400,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _callControl(
                                    t,
                                    KIconName.mic,
                                    muted ? unmuteLabel : muteLabel,
                                    onMutedChanged == null
                                        ? null
                                        : () => onMutedChanged!(!muted),
                                    muted: muted,
                                  ),
                                  if (onEndCall != null) ...[
                                    SizedBox(width: t.spaceLayoutGutter),
                                    _callControl(
                                      t,
                                      KIconName.phoneOff,
                                      endLabel,
                                      onEndCall,
                                      end: true,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (onExpandedChanged != null)
                    Positioned(
                      top: t.spaceLayoutGutter,
                      left: t.spaceLayoutGutter,
                      child: KButton(
                        leading: const KIcon(KIconName.chevronDown),
                        variant: KButtonVariant.ghost,
                        label: minimizeLabel,
                        onPressed: () => onExpandedChanged!(false),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      );
    }
    return Semantics(
      label: regionLabel,
      container: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onExpandedChanged == null
            ? null
            : () => onExpandedChanged!(true),
        child: Container(
          constraints: BoxConstraints(
            minHeight: t.sizeIconDefault * 2 + t.spaceControlGap * 2,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: t.spaceLayoutGutter,
            vertical: t.spaceControlGap,
          ),
          decoration: BoxDecoration(
            color: t.colorSurfaceRaised,
            border: Border(bottom: BorderSide(color: t.colorBorderDefault)),
          ),
          child: LayoutBuilder(
            builder: (context, bounds) => Row(
              children: [
                if (avatar != null) ...[
                  ExcludeSemantics(
                    child: SizedBox.square(
                      dimension: t.sizeIconDefault * 2,
                      child: FittedBox(child: avatar!),
                    ),
                  ),
                  SizedBox(width: t.spaceControlGap),
                ],
                Expanded(
                  child: Semantics(
                    button: onExpandedChanged != null,
                    label: onExpandedChanged != null ? expandLabel : null,
                    child: InkWell(
                      onTap: onExpandedChanged == null
                          ? null
                          : () => onExpandedChanged!(true),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          KText(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: KDesignTokenVariants
                                  .typeScaleStandardFontBodySize,
                              height:
                                  t.fontBodyLineHeight /
                                  KDesignTokenVariants
                                      .typeScaleStandardFontBodySize,
                              fontWeight: FontWeight.bold,
                              fontVariations: [
                                FontVariation.weight(
                                  FontWeight.bold.value.toDouble(),
                                ),
                              ],
                            ),
                          ),
                          Semantics(
                            liveRegion: true,
                            child: KText(
                              onExpandedChanged == null
                                  ? status
                                  : '$status · $expandLabel',
                              variant: KTextVariant.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: t.colorTextMuted,
                                fontSize: KDesignTokenVariants
                                    .typeScaleStandardFontBodySmallSize,
                                height:
                                    t.fontBodySmallLineHeight /
                                    KDesignTokenVariants
                                        .typeScaleStandardFontBodySmallSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: t.spaceControlGap),
                // At narrow widths, enlarged text takes priority over the meter.
                if (bounds.maxWidth > 420 ||
                    (avatar == null &&
                        MediaQuery.textScalerOf(context).scale(
                              KDesignTokenVariants
                                  .typeScaleStandardFontBodySize,
                            ) <=
                            KDesignTokenVariants
                                .typeScaleStandardFontBodySize)) ...[
                  SizedBox(
                    width: t.sizeIconDefault * 5,
                    height: t.sizeIconDefault,
                    child: ClipRect(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const barCount = 25;
                          final unit = math.min(
                            t.spaceControlGap / 4,
                            constraints.maxWidth / (barCount * 2),
                          );
                          return ExcludeSemantics(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                for (var i = 0; i < barCount; i++)
                                  Padding(
                                    padding: EdgeInsets.only(left: unit),
                                    child: Container(
                                      key: ValueKey('k-call-bar-level-$i'),
                                      width: unit,
                                      height:
                                          t.sizeIconDefault *
                                          (0.125 +
                                              0.875 *
                                                  level *
                                                  (0.3 +
                                                      0.7 *
                                                          math
                                                              .sin(i * 1.7)
                                                              .abs())),
                                      color: muted
                                          ? t.colorTextMuted.withValues(
                                              alpha: t.opacityDisabled,
                                            )
                                          : t.colorStatusSuccessAccent,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: t.spaceControlGap),
                ],
                Semantics(
                  label: '$durationLabel: $duration',
                  child: ExcludeSemantics(
                    child: KText(
                      duration,
                      style: TextStyle(
                        fontSize:
                            KDesignTokenVariants.typeScaleStandardFontBodySize,
                        height:
                            t.fontBodyLineHeight /
                            KDesignTokenVariants.typeScaleStandardFontBodySize,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: t.spaceControlGap),
                KIconButton(
                  icon: muted ? KIconName.micOff : KIconName.mic,
                  label: muted ? unmuteLabel : muteLabel,
                  selected: muted,
                  onPressed: onMutedChanged == null
                      ? null
                      : () => onMutedChanged!(!muted),
                ),
                if (onEndCall != null) ...[
                  SizedBox(width: t.spaceControlGap),
                  Theme(
                    data: Theme.of(context).copyWith(
                      extensions: [
                        t.copyWith(
                          radiusControl: t.radiusFull,
                          colorActionGhostBackground: t.colorStatusErrorAccent,
                          colorActionGhostHover: t.colorStatusErrorAccent,
                          colorActionGhostPressed: t.colorStatusErrorAccent,
                          colorActionGhostForeground:
                              t.colorActionPrimaryForeground,
                        ),
                      ],
                    ),
                    child: KIconButton(
                      icon: KIconName.phoneOff,
                      label: endLabel,
                      onPressed: onEndCall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _callControl(
    KDesignTokens t,
    KIconName icon,
    String label,
    VoidCallback? onPressed, {
    bool end = false,
    bool muted = false,
  }) => Container(
    width: math.max(t.sizeHitTarget, t.sizeIconDefault * 2.5),
    height: math.max(t.sizeHitTarget, t.sizeIconDefault * 2.5),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: end ? t.colorStatusErrorAccent : t.colorSurfaceSubtle,
    ),
    child: Center(
      child: KIconButton(
        icon: muted ? KIconName.micOff : icon,
        selected: muted,
        iconContent: end ? KIcon(icon, color: t.colorSurfaceCanvas) : null,
        label: label,
        onPressed: onPressed,
      ),
    ),
  );
}

/// Matches the gallery's 520 ms staggered bounce, without opacity changes.
class _CallEntryMotion extends StatelessWidget {
  const _CallEntryMotion({required this.delay, required this.child});
  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: delay + 520),
      child: child,
      builder: (context, elapsed, child) {
        final progress = ((elapsed * (delay + 520) - delay) / 520).clamp(
          0.0,
          1.0,
        );
        final (scale, y) = progress < .65
            ? (
                1.08 * Curves.easeOutCubic.transform(progress / .65),
                12 - 15 * Curves.easeOutCubic.transform(progress / .65),
              )
            : progress < .85
            ? (
                1.08 - .10 * ((progress - .65) / .20),
                -3 + 4 * ((progress - .65) / .20),
              )
            : (
                .98 + .02 * ((progress - .85) / .15),
                1 - ((progress - .85) / .15),
              );
        return Transform.translate(
          offset: Offset(0, y),
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}

class _CallAvatarMotion extends StatefulWidget {
  const _CallAvatarMotion({required this.origin, required this.child});
  final Rect? origin;
  final Widget child;
  @override
  State<_CallAvatarMotion> createState() => _CallAvatarMotionState();
}

class _CallAvatarMotionState extends State<_CallAvatarMotion>
    with SingleTickerProviderStateMixin {
  final _anchor = GlobalKey();
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Rect? _target;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _anchor.currentContext?.findRenderObject() as RenderBox?;
      if (box != null &&
          widget.origin != null &&
          !MediaQuery.disableAnimationsOf(context)) {
        setState(() => _target = box.localToGlobal(Offset.zero) & box.size);
        _motion.forward();
      } else {
        _motion.value = 1;
      }
    });
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _motion,
    child: SizedBox(key: _anchor, child: widget.child),
    builder: (context, child) {
      final target = _target, origin = widget.origin;
      if (target == null || origin == null) return child!;
      final remaining = 1 - Curves.easeInOutCubic.transform(_motion.value);
      return Transform.translate(
        offset: (origin.topLeft - target.topLeft) * remaining,
        child: Transform.scale(
          alignment: Alignment.topLeft,
          scale: 1 + (origin.width / target.width - 1) * remaining,
          child: child,
        ),
      );
    },
  );
}
