import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

enum KAgentCursorState { pointing, clicking }

/// Decorative cursor. Position its parent at the arrow tip; input passes through.
class KAgentCursor extends StatelessWidget {
  const KAgentCursor({
    this.state = KAgentCursorState.pointing,
    this.visible = true,
    this.size = 32,
    this.avatar,
    this.label,
    this.fill,
    this.outline,
    this.glow,
    this.glowEnabled = true,
    this.glowIntensity = 1,
    this.glowColor,
    super.key,
  }) : assert(size > 0 && size < double.infinity),
       assert(glowIntensity >= 0 && glowIntensity <= 1);

  final KAgentCursorState state;
  final bool visible;
  final double size;
  final Widget? avatar;
  final String? label;
  final Color? fill;
  final Color? outline;

  /// Compatibility alias; glowColor takes precedence.
  final Color? glow;
  final bool glowEnabled;
  final double glowIntensity;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _CursorPainter(
                    state: state,
                    fill: fill ?? t.componentPresentationCoverScrim,
                    outline: outline ?? t.componentPresentationCoverForeground,
                    glow: glowColor ?? glow ?? t.colorStatusInfoAccent,
                    glowIntensity: glowEnabled ? glowIntensity : 0,
                  ),
                ),
              ),
              if (avatar != null || (label?.isNotEmpty ?? false))
                Positioned(
                  left: size * .65,
                  top: size * .5,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: t.spaceControlGap,
                    children: [
                      ?avatar,
                      if (label?.isNotEmpty ?? false)
                        Container(
                          padding: EdgeInsets.all(t.spaceControlGap),
                          decoration: BoxDecoration(
                            color: t.colorSurfaceRaised,
                            borderRadius: BorderRadius.circular(
                              t.radiusControl,
                            ),
                          ),
                          child: Text(
                            label!,
                            style: TextStyle(
                              color: t.colorTextPrimary,
                              fontFamily: t.fontFamily,
                              fontSize: t.fontBodySize,
                              height: t.fontBodyLineHeight / t.fontBodySize,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CursorPainter extends CustomPainter {
  const _CursorPainter({
    required this.state,
    required this.fill,
    required this.outline,
    required this.glow,
    required this.glowIntensity,
  });
  final KAgentCursorState state;
  final Color fill;
  final Color outline;
  final Color glow;
  final double glowIntensity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 32);
    final path = Path()
      ..moveTo(1, .4)
      ..quadraticBezierTo(-.5, -.5, .4, 1)
      ..lineTo(9, 27)
      ..quadraticBezierTo(10, 29, 11, 27)
      ..lineTo(15.5, 16.5)
      ..quadraticBezierTo(15.8, 15.8, 16.5, 15.5)
      ..lineTo(27, 11)
      ..quadraticBezierTo(29, 10, 27, 9)
      ..close();
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    if (glowIntensity > 0) {
      for (final blur in [4.48, 8.96]) {
        canvas.drawPath(
          path,
          Paint()
            ..color = glow.withValues(
              alpha: glow.a * glowIntensity * (blur == 4.48 ? 1 : .75),
            )
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur),
        );
      }
    }
    if (state == KAgentCursorState.clicking) {
      canvas.drawCircle(Offset.zero, 8, stroke..color = glow);
    }
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(path, stroke..color = outline);
  }

  @override
  bool shouldRepaint(_CursorPainter oldDelegate) =>
      state != oldDelegate.state ||
      fill != oldDelegate.fill ||
      outline != oldDelegate.outline ||
      glow != oldDelegate.glow ||
      glowIntensity != oldDelegate.glowIntensity;
}
