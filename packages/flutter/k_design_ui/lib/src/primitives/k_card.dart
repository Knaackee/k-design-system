import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_menu_button.dart';
import 'k_surface.dart';
import 'k_text.dart';

/// Animated border that conveys a state, never decoration (one per screen):
/// [pulse] needs input, [spin] work in progress, [aurora] AI input active,
/// [flame] critical, [dashed] drop zone or draft, [shimmer] loading,
/// [success] a one-time confirmation. Static under reduced motion.
enum KCardBorder { none, pulse, spin, aurora, flame, dashed, shimmer, success }

class KCard extends StatelessWidget {
  const KCard({
    this.child,
    this.tone = KSurfaceTone.raised,
    this.elevation = KSurfaceElevation.none,
    this.leading,
    this.title,
    this.description,
    this.menu,
    this.menuLabel = 'More actions',
    this.actions = const [],
    this.border = KCardBorder.none,
    this.borderColor,
    this.borderColors,
    this.borderDuration,
    super.key,
  });

  final Widget? child;
  final KSurfaceTone tone;
  final KSurfaceElevation elevation;

  /// Header: leading visual, title, description and a "…" menu at the end.
  final Widget? leading;
  final String? title;
  final String? description;

  /// Card actions in a "…" menu at the top end.
  final List<KMenuAction>? menu;
  final String menuLabel;

  /// Footer actions, e.g. KButtons.
  final List<Widget> actions;
  final KCardBorder border;

  /// Overrides `component.cardBorder.color` (single-colour effects).
  final Color? borderColor;

  /// Overrides the gradient colours of [KCardBorder.aurora] and
  /// [KCardBorder.flame].
  final List<Color>? borderColors;

  /// One animation cycle; overrides the effect's token.
  final Duration? borderDuration;

  /// Whether [context] is inside a [KCard].
  static bool isInside(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_KCardScope>() != null;

  @override
  Widget build(BuildContext context) {
    assert(
      !isInside(context),
      'Nested KCard (Decision 0010): a card must not contain another card. '
      'Inside a card use separators, a grouped list or a KStack section; '
      'move independent content into a sibling card.',
    );
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final hasHeader =
        title != null ||
        description != null ||
        leading != null ||
        (menu?.isNotEmpty ?? false);
    final gap = t.spaceControlGap;
    Widget content = Padding(
      padding: EdgeInsets.all(t.spaceCardPadding),
      child: child ?? const SizedBox.shrink(),
    );
    if (hasHeader || actions.isNotEmpty) {
      content = Padding(
        padding: EdgeInsets.all(t.spaceCardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: gap,
          children: [
            if (hasHeader)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: gap,
                children: [
                  ?leading,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          KText(title!, variant: KTextVariant.label),
                        if (description != null)
                          KText(
                            description!,
                            variant: KTextVariant.caption,
                            style: TextStyle(color: t.colorTextMuted),
                          ),
                      ],
                    ),
                  ),
                  if (menu?.isNotEmpty ?? false)
                    // The trigger sits on the card corner: its touch area
                    // reaches into the padding instead of pushing the title.
                    _KCardCornerAction(
                      inset: gap,
                      child: KMenuButton(
                        label: menuLabel,
                        actions: menu!,
                        overflow: true,
                        alignEnd: true,
                      ),
                    ),
                ],
              ),
            ?child,
            if (actions.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: gap),
                child: Wrap(spacing: gap, runSpacing: gap, children: actions),
              ),
          ],
        ),
      );
    }
    Widget card = KSurface(
      tone: tone,
      radius: KSurfaceRadius.card,
      elevation: elevation,
      child: content,
    );
    if (border != KCardBorder.none) {
      card = _KCardBorderEffect(
        border: border,
        color: borderColor,
        colors: borderColors,
        duration: borderDuration,
        child: card,
      );
    }
    return _KCardScope(child: card);
  }
}

/// Puts the card's "…" trigger on the corner: it reaches [inset] into the
/// padding at the top and the end, and takes that much less room in the
/// header, like the Web `margin-block`/`margin-inline-end` of `-gap`.
class _KCardCornerAction extends SingleChildRenderObjectWidget {
  const _KCardCornerAction({required this.inset, required super.child});

  final double inset;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderKCardCornerAction(inset, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderKCardCornerAction renderObject,
  ) {
    renderObject
      ..inset = inset
      ..textDirection = Directionality.of(context);
  }
}

class _RenderKCardCornerAction extends RenderProxyBox {
  _RenderKCardCornerAction(this._inset, this._textDirection);

  double _inset;
  set inset(double value) {
    if (value == _inset) return;
    _inset = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsPaint();
  }

  Offset get _childOffset =>
      Offset(_textDirection == TextDirection.rtl ? -_inset : 0, -_inset);

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(
      Size(
        math.max(0, child.size.width - _inset),
        math.max(0, child.size.height - 2 * _inset),
      ),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      context.paintChild(child!, offset + _childOffset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      result.addWithPaintOffset(
        offset: _childOffset,
        position: position,
        hitTest: (result, transformed) =>
            child!.hitTest(result, position: transformed),
      );

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      transform.translateByDouble(_childOffset.dx, _childOffset.dy, 0, 1);
}

class _KCardScope extends InheritedWidget {
  const _KCardScope({required super.child});

  @override
  bool updateShouldNotify(_KCardScope oldWidget) => false;
}

class _KCardBorderEffect extends StatefulWidget {
  const _KCardBorderEffect({
    required this.border,
    required this.child,
    this.color,
    this.colors,
    this.duration,
  });

  final KCardBorder border;
  final Color? color;
  final List<Color>? colors;
  final Duration? duration;
  final Widget child;

  @override
  State<_KCardBorderEffect> createState() => _KCardBorderEffectState();
}

class _KCardBorderEffectState extends State<_KCardBorderEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  Duration _cycle(KDesignTokens t) =>
      widget.duration ??
      switch (widget.border) {
        KCardBorder.pulse => t.componentCardBorderPulseDuration,
        KCardBorder.spin => t.componentCardBorderSpinDuration,
        KCardBorder.aurora => t.componentCardBorderAuroraDuration,
        KCardBorder.flame => t.componentCardBorderFlameDuration,
        KCardBorder.dashed => t.componentCardBorderDashedDuration,
        KCardBorder.shimmer => t.componentCardBorderShimmerDuration,
        KCardBorder.success => t.componentCardBorderSuccessDuration,
        KCardBorder.none => Duration.zero,
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_KCardBorderEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.border != widget.border ||
        oldWidget.duration != widget.duration) {
      _controller.reset();
      _sync();
    }
  }

  void _sync() {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    _controller.duration = _cycle(t);
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _controller.value = widget.border == KCardBorder.success ? 1 : 0;
      _controller.stop();
    } else if (widget.border == KCardBorder.success) {
      if (_controller.value == 0) _controller.forward();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final border = widget.border;
    final color =
        widget.color ??
        (border == KCardBorder.success
            ? t.componentCardBorderSuccessColor
            : t.componentCardBorderColor);
    final colors =
        widget.colors ??
        switch (border) {
          KCardBorder.aurora => [
            t.componentCardBorderAurora1,
            t.componentCardBorderAurora2,
            t.componentCardBorderAurora3,
            t.componentCardBorderAurora4,
          ],
          KCardBorder.flame => [
            t.componentCardBorderFlame1,
            t.componentCardBorderFlame2,
            t.componentCardBorderFlame3,
            t.componentCardBorderFlame2,
          ],
          _ => <Color>[color],
        };
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return CustomPaint(
      painter: _KCardBorderPainter(
        repaint: _controller,
        border: border,
        color: color,
        colors: colors,
        radius: t.radiusCard,
        width: t.componentCardBorderWidth,
        glowBlur: t.componentCardBorderGlowBlur,
        pulseSpread: t.componentCardBorderPulseSpread,
        dashLength: t.componentCardBorderDashLength,
        dashGap: t.componentCardBorderDashGap,
        glow: true,
        reduced: reduced,
        glowSpin: t.componentCardBorderGlowOpacitySpin,
        glowAurora: t.componentCardBorderGlowOpacityAurora,
        glowFlameLow: t.componentCardBorderGlowOpacityFlameLow,
        glowFlameHigh: t.componentCardBorderGlowOpacityFlameHigh,
      ),
      foregroundPainter: _KCardBorderPainter(
        repaint: _controller,
        border: border,
        color: color,
        colors: colors,
        radius: t.radiusCard,
        width: t.componentCardBorderWidth,
        glowBlur: t.componentCardBorderGlowBlur,
        pulseSpread: t.componentCardBorderPulseSpread,
        dashLength: t.componentCardBorderDashLength,
        dashGap: t.componentCardBorderDashGap,
        glow: false,
        reduced: reduced,
        glowSpin: t.componentCardBorderGlowOpacitySpin,
        glowAurora: t.componentCardBorderGlowOpacityAurora,
        glowFlameLow: t.componentCardBorderGlowOpacityFlameLow,
        glowFlameHigh: t.componentCardBorderGlowOpacityFlameHigh,
      ),
      child: widget.child,
    );
  }
}

class _KCardBorderPainter extends CustomPainter {
  _KCardBorderPainter({
    required this.repaint,
    required this.border,
    required this.color,
    required this.colors,
    required this.radius,
    required this.width,
    required this.glowBlur,
    required this.pulseSpread,
    required this.dashLength,
    required this.dashGap,
    required this.glow,
    required this.reduced,
    required this.glowSpin,
    required this.glowAurora,
    required this.glowFlameLow,
    required this.glowFlameHigh,
  }) : super(repaint: repaint);

  final double glowSpin;
  final double glowAurora;
  final double glowFlameLow;
  final double glowFlameHigh;

  final AnimationController repaint;
  final KCardBorder border;
  final Color color;
  final List<Color> colors;
  final double radius;
  final double width;
  final double glowBlur;
  final double pulseSpread;
  final double dashLength;
  final double dashGap;

  /// Behind the card: the outer glow; in front: the ring itself.
  final bool glow;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    final v = repaint.value;
    final rect = Offset.zero & size;
    final ring = RRect.fromRectAndRadius(
      rect.deflate(width / 2),
      Radius.circular(math.max(0, radius - width / 2)),
    );
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final sweep = SweepGradient(
      colors: [...colors, colors.first],
      transform: GradientRotation(reduced ? 0 : v * 2 * math.pi),
    ).createShader(rect);

    switch (border) {
      case KCardBorder.pulse:
      case KCardBorder.success:
        if (glow) {
          if (reduced) return;
          final grow = Curves.easeOut.transform(v);
          final spread = pulseSpread * grow;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect.inflate(spread / 2),
              Radius.circular(radius + spread / 2),
            ),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = spread
              ..color = color.withValues(alpha: 0.45 * (1 - grow)),
          );
          return;
        }
        canvas.drawRRect(ring, stroke..color = color);
      case KCardBorder.spin:
        final tail = SweepGradient(
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.4),
            color,
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.44, 0.72, 0.97, 1],
          transform: GradientRotation(reduced ? 0 : v * 2 * math.pi),
        ).createShader(rect);
        if (glow) {
          canvas.drawRRect(
            ring,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = width * 3
              ..shader = tail
              ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowBlur / 2)
              ..color = Colors.white.withValues(alpha: glowSpin),
          );
          return;
        }
        canvas.drawRRect(ring, stroke..shader = tail);
        return;
      case KCardBorder.aurora:
      case KCardBorder.flame:
        if (glow) {
          // The flame breathes slowly instead of flickering.
          final flicker = border == KCardBorder.flame
              ? glowFlameLow +
                    (glowFlameHigh - glowFlameLow) *
                        (0.5 + 0.5 * math.sin(v * 4 * math.pi))
              : glowAurora;
          canvas.drawRRect(
            ring,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = width * 3
              ..shader = sweep
              ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowBlur / 2)
              ..color = Colors.white.withValues(alpha: flicker),
          );
          return;
        }
        canvas.drawRRect(ring, stroke..shader = sweep);
      case KCardBorder.dashed:
        if (glow) return;
        final path = Path()..addRRect(ring);
        final dashes = Path();
        final period = dashLength + dashGap;
        for (final metric in path.computeMetrics()) {
          var d = reduced ? 0.0 : v * period;
          while (d < metric.length) {
            dashes.addPath(
              metric.extractPath(d, math.min(d + dashLength, metric.length)),
              Offset.zero,
            );
            d += period;
          }
        }
        canvas.drawPath(dashes, stroke..color = color);
      case KCardBorder.shimmer:
        if (glow || reduced) return;
        final x = size.width * (2.5 * (1 - v) - 1);
        canvas.drawRRect(
          ring,
          stroke
            ..shader = ui.Gradient.linear(
              Offset(x - size.width * 0.4, 0),
              Offset(x + size.width * 0.4, size.height * 0.3),
              [color.withValues(alpha: 0), color, color.withValues(alpha: 0)],
              [0, 0.5, 1],
            ),
        );
      case KCardBorder.none:
        return;
    }
  }

  @override
  bool shouldRepaint(_KCardBorderPainter old) =>
      old.border != border ||
      old.color != color ||
      old.colors != colors ||
      old.reduced != reduced;
}
