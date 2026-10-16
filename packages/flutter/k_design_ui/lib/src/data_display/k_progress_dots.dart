import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

/// Passive step progress. The consumer owns step navigation.
class KProgressDots extends StatelessWidget {
  const KProgressDots({
    super.key,
    required this.count,
    required this.activeIndex,
    this.label = 'Progress',
    this.dotSize = 6,
    this.activeWidth = 20,
    this.gap = 12,
    this.color,
    this.activeColor,
  });
  final int count, activeIndex;
  final String label;
  final double dotSize, activeWidth, gap;
  final Color? color, activeColor;
  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final current = activeIndex.clamp(0, count - 1);
    final tokens =
        Theme.of(context).extension<KDesignTokens>() ??
        KDesignTokens.orbitLight;
    final foreground = tokens.colorTextPrimary;
    return Semantics(
      label: label,
      value: '${current + 1} / $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(width: gap),
            AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : tokens.motionModerate,
              width: i == current ? activeWidth : dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(tokens.radiusFull),
                color: i == current
                    ? activeColor ?? foreground
                    : color ??
                          foreground.withValues(
                            alpha: tokens.componentProgressDotsInactiveOpacity,
                          ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
