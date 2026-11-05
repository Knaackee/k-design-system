import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:k_design_tokens/k_design_tokens.dart';

import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_text.dart';

enum KPresentationCollectionLayout { carousel, list }

class KPresentationCollection extends StatefulWidget {
  const KPresentationCollection({
    required this.children,
    required this.label,
    this.layout = KPresentationCollectionLayout.carousel,
    this.previousLabel = 'Vorherige Karten',
    this.nextLabel = 'Weitere Karten',
    super.key,
  });
  final List<Widget> children;
  final String label;
  final KPresentationCollectionLayout layout;
  final String previousLabel;
  final String nextLabel;

  @override
  State<KPresentationCollection> createState() =>
      _KPresentationCollectionState();
}

class _KPresentationCollectionState extends State<KPresentationCollection> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _move(int direction) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final target =
        (position.pixels + direction * position.viewportDimension * .8).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: Theme.of(
          context,
        ).extension<KDesignTokens>()!.motion(KMotionRole.control).settle,
        curve: Theme.of(
          context,
        ).extension<KDesignTokens>()!.motion(KMotionRole.control).curve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final gap = t.spaceControlGap;
    final carousel = widget.layout == KPresentationCollectionLayout.carousel;
    return Semantics(
      label: widget.label,
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: KText(
                  widget.label,
                  style: TextStyle(fontWeight: t.fontHeadingWeight),
                ),
              ),
              if (carousel) ...[
                KIconButton(
                  label: widget.previousLabel,
                  icon: KIconName.chevronLeft,
                  onPressed: () => _move(-1),
                ),
                KIconButton(
                  label: widget.nextLabel,
                  icon: KIconName.chevronRight,
                  onPressed: () => _move(1),
                ),
              ],
            ],
          ),
          SizedBox(height: gap),
          if (carousel)
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.hasBoundedWidth
                    ? math.min(constraints.maxWidth * .82, 300.0)
                    : 300.0;
                return SingleChildScrollView(
                  controller: _scroll,
                  scrollDirection: Axis.horizontal,
                  physics: _CardSnapPhysics(extent: width + gap * 1.5),
                  padding: EdgeInsets.fromLTRB(
                    t.spaceMicro,
                    t.spaceMicro,
                    t.spaceMicro,
                    gap,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < widget.children.length; i++) ...[
                        if (i > 0) SizedBox(width: gap * 1.5),
                        SizedBox(width: width, child: widget.children[i]),
                      ],
                    ],
                  ),
                );
              },
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < widget.children.length; i++) ...[
                  if (i > 0) SizedBox(height: gap),
                  widget.children[i],
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CardSnapPhysics extends ScrollPhysics {
  const _CardSnapPhysics({required this.extent, super.parent});
  final double extent;

  @override
  _CardSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _CardSnapPhysics(extent: extent, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    var page = position.pixels / extent;
    if (velocity < -tolerance.velocity) page -= .5;
    if (velocity > tolerance.velocity) page += .5;
    final target = (page.roundToDouble() * extent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((target - position.pixels).abs() < tolerance.distance) return null;
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}
