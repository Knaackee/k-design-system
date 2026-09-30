import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../../primitives/k_icon.dart';
import 'orbit_models.dart';
import 'orbit_projection.dart';

class KOrbitNodeLayer extends StatelessWidget {
  const KOrbitNodeLayer({
    required this.levels,
    required this.nodes,
    required this.connections,
    required this.view,
    required this.time,
    required this.tokens,
    required this.selectedId,
    required this.reducedMotion,
    required this.onActivate,
    required this.repaint,
    required this.extentOverride,
    required this.opacityFor,
    required this.scaleFor,
    required this.isDeparting,
    this.centerContent,
    super.key,
  });

  final List<KOrbitLevel> levels;
  final List<KOrbitNode> nodes;
  final List<KOrbitConnection> connections;
  final KOrbitViewState Function() view;
  final double Function() time;
  final KDesignTokens tokens;
  final String? selectedId;
  final bool reducedMotion;
  final ValueChanged<KOrbitNode> onActivate;
  final Listenable repaint;
  final double? extentOverride;
  final double Function(String id) opacityFor;
  final double Function(String id) scaleFor;
  final bool Function(String id) isDeparting;
  final Widget? centerContent;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => AnimatedBuilder(
      animation: repaint,
      builder: (context, _) {
        final size = constraints.biggest;
        final scene = projectKOrbitScene(
          size: size,
          levels: levels,
          nodes: nodes,
          connections: connections,
          view: view(),
          timeSeconds: time(),
          radiusRatio: tokens.componentOrbitCenterRadiusRatio,
          extentOverride: extentOverride,
        );
        final labels = kOrbitLabelLayout(
          scene: scene,
          size: size,
          fontSize: tokens.componentOrbitNodeLabelSize,
          labelHeight: tokens.fontCaptionLineHeight,
          labelOffset: tokens.componentOrbitNodeLabelOffset,
          nodeSize: tokens.componentOrbitNodeSize,
          selectedId: selectedId,
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final node = kOrbitHitTest(
              scene: scene,
              labels: labels,
              point: details.localPosition,
              hitTargetSize: tokens.componentOrbitNodeHitTargetSize,
              eligible: (item) =>
                  !isDeparting(item.node.id) && !_occluded(item, scene),
            );
            if (node != null) onActivate(node);
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final item in scene.nodes) _marker(item, scene),
              for (final item in scene.nodes)
                if (labels[item.node.id] case final rect?)
                  _label(item, scene, rect),
            ],
          ),
        );
      },
    ),
  );

  Widget _marker(KOrbitProjectedNode item, KOrbitSceneProjection scene) {
    final node = item.node;
    final center = item.point.offset;
    final markerSize = node.isCenter
        ? scene.centerRadius * 2
        : tokens.componentOrbitNodeSize;
    final occluded = _occluded(item, scene);
    final depth = .55 + .45 * ((item.point.depth + 1) / 2).clamp(0, 1);
    final hidden = occluded || isDeparting(node.id);
    return Positioned(
      left: center.dx - markerSize / 2,
      top: center.dy - markerSize / 2,
      width: markerSize,
      height: markerSize,
      child: IgnorePointer(
        ignoring: true,
        child: ExcludeSemantics(
          excluding: hidden,
          child: Transform.scale(
            scale: scaleFor(node.id),
            child: Opacity(
              opacity: occluded ? 0 : depth * opacityFor(node.id),
              child: _KOrbitMarker(
                node: node,
                selected: node.id == selectedId,
                tokens: tokens,
                size: node.isCenter
                    ? markerSize
                    : tokens.componentOrbitNodeSize,
                timeSeconds: time(),
                reducedMotion: reducedMotion,
                centerContent: node.isCenter ? centerContent : null,
                onActivate: () => onActivate(node),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(
    KOrbitProjectedNode item,
    KOrbitSceneProjection scene,
    Rect rect,
  ) {
    final occluded = _occluded(item, scene);
    final depth = .55 + .45 * ((item.point.depth + 1) / 2).clamp(0, 1);
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        ignoring: true,
        child: ExcludeSemantics(
          child: Opacity(
            opacity: occluded ? 0 : depth * opacityFor(item.node.id),
            child: Text(
              item.node.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: item.node.isCenter
                  ? TextAlign.center
                  : TextAlign.start,
              style: TextStyle(
                color: tokens.colorTextPrimary,
                fontFamily: tokens.fontFamily,
                fontSize: tokens.componentOrbitNodeLabelSize,
                height:
                    tokens.fontCaptionLineHeight /
                    tokens.componentOrbitNodeLabelSize,
                fontWeight: tokens.fontLabelWeight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _occluded(KOrbitProjectedNode item, KOrbitSceneProjection scene) =>
      !item.node.isCenter &&
      item.point.depth < 0 &&
      (item.point.offset - scene.center).distance < scene.centerRadius;
}

class _KOrbitMarker extends StatelessWidget {
  const _KOrbitMarker({
    required this.node,
    required this.selected,
    required this.tokens,
    required this.size,
    required this.timeSeconds,
    required this.reducedMotion,
    required this.onActivate,
    this.centerContent,
  });

  final KOrbitNode node;
  final bool selected;
  final KDesignTokens tokens;
  final double size;
  final double timeSeconds;
  final bool reducedMotion;
  final VoidCallback onActivate;
  final Widget? centerContent;

  Color get color => switch (node.status) {
    KOrbitStatus.active => tokens.colorStatusInfoAccent,
    KOrbitStatus.question => tokens.colorStatusWarningAccent,
    KOrbitStatus.error => tokens.colorStatusErrorAccent,
    KOrbitStatus.idle => switch (node.tone) {
      KOrbitTone.neutral => tokens.componentOrbitConnectionColor,
      KOrbitTone.brand => tokens.colorBrandPrimaryAccent,
      KOrbitTone.info => tokens.colorStatusInfoAccent,
      KOrbitTone.success => tokens.colorStatusSuccessAccent,
      KOrbitTone.warning => tokens.colorStatusWarningAccent,
      KOrbitTone.error => tokens.colorStatusErrorAccent,
    },
  };

  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('k-orbit-node-${node.id}'),
    button: !node.disabled,
    selected: selected,
    label: node.label,
    hint: [
      node.description,
      node.statusLabel,
    ].whereType<String>().where((value) => value.isNotEmpty).join('. '),
    enabled: !node.disabled,
    child: Material(
      type: MaterialType.transparency,
      child: InkResponse(
        radius: size / 2,
        canRequestFocus: !node.disabled,
        onTap: node.disabled ? null : onActivate,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (node.shouldPulse) _pulse(),
              if (node.isCenter && centerContent != null) centerContent!,
              if (!node.isCenter)
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: tokens.colorSurfaceRaised,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? tokens.colorBorderFocus : color,
                      width: selected
                          ? tokens.borderWidthStrong
                          : tokens.borderWidthDefault,
                    ),
                  ),
                  alignment: Alignment.center,
                  child:
                      node.content ??
                      KIcon(
                        KIconName.circle,
                        size: tokens.componentOrbitNodeSize * 2 / 3,
                        color: color,
                      ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _pulse() {
    final duration =
        node.pulsePeriod ?? tokens.componentOrbitMotionPulseDuration;
    final period = duration.inMicroseconds / Duration.microsecondsPerSecond;
    final phase = reducedMotion ? .2 : (timeSeconds / period) % 1;
    return Opacity(
      opacity: reducedMotion ? .32 : .48 * (1 - phase),
      child: Transform.scale(
        scale: reducedMotion ? 1.12 : 1 + phase * .5,
        child: Container(
          key: ValueKey('k-orbit-pulse-${node.id}'),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: tokens.borderWidthStrong),
          ),
        ),
      ),
    );
  }
}
