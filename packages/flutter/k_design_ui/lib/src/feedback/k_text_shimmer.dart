import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

/// Activity on existing text, with static accessible text under reduced motion.
class KTextShimmer extends StatefulWidget {
  const KTextShimmer({
    super.key,
    required this.text,
    this.active = false,
    this.color,
    this.label,
  });
  final String text;
  final bool active;
  final Color? color;
  final String? label;
  @override
  State<KTextShimmer> createState() => _KTextShimmerState();
}

class _KTextShimmerState extends State<KTextShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(vsync: this);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  @override
  void didUpdateWidget(KTextShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configure();
  }

  void _configure() {
    _motion.duration = Theme.of(
      context,
    ).extension<KDesignTokens>()!.motionSkeleton;
    if (widget.active &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final color =
        widget.color ??
        DefaultTextStyle.of(context).style.color ??
        tokens.colorTextMuted;
    final text = Text(
      widget.text,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: TextStyle(color: color),
    );
    return Semantics(
      label: widget.label ?? widget.text,
      excludeSemantics: true,
      child: !widget.active || MediaQuery.disableAnimationsOf(context)
          ? text
          : AnimatedBuilder(
              animation: _motion,
              child: text,
              builder: (context, child) => ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment(3 - _motion.value * 6, 0),
                  end: Alignment(4 - _motion.value * 6, 0),
                  colors: [color, tokens.colorTextPrimary, color],
                  stops: const [0, .5, 1],
                ).createShader(bounds),
                child: child,
              ),
            ),
    );
  }
}
