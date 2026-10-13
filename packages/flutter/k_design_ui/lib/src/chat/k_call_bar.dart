import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../actions/k_icon_button.dart';
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
    super.key,
  });
  final String name,
      status,
      duration,
      regionLabel,
      durationLabel,
      muteLabel,
      unmuteLabel;
  final bool muted;
  final double microphoneLevel;
  final ValueChanged<bool>? onMutedChanged;
  @override
  Widget build(BuildContext context) {
    final t =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final level = muted || !microphoneLevel.isFinite
        ? 0.0
        : microphoneLevel.clamp(0.0, 1.0);
    return Semantics(
      label: regionLabel,
      container: true,
      child: Container(
        height: t.sizeIconDefault * 2 + t.spaceControlGap * 2,
        padding: EdgeInsets.symmetric(
          horizontal: t.spaceLayoutGutter,
          vertical: t.spaceControlGap,
        ),
        decoration: BoxDecoration(
          color: t.colorSurfaceRaised,
          border: Border(bottom: BorderSide(color: t.colorBorderDefault)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KText(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Semantics(
                    liveRegion: true,
                    child: KText(
                      status,
                      variant: KTextVariant.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.colorTextMuted),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: t.spaceControlGap),
            Flexible(
              child: SizedBox(
                width: t.sizeIconDefault * 5,
                height: t.sizeIconDefault,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.centerRight,
                    minWidth: t.sizeIconDefault * 5,
                    maxWidth: t.sizeIconDefault * 5,
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
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
                                    (0.125 +
                                        0.875 *
                                            level *
                                            (0.3 +
                                                0.7 * math.sin(i * 1.7).abs())),
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
              ),
            ),
            SizedBox(width: t.spaceControlGap),
            Semantics(
              label: '$durationLabel: $duration',
              child: ExcludeSemantics(
                child: KText(
                  duration,
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
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
          ],
        ),
      ),
    );
  }
}
