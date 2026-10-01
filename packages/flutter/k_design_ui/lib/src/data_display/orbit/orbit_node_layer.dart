import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../../actions/k_context_menu.dart';
import '../../actions/k_menu_button.dart';

import 'orbit_models.dart';
import 'orbit_projection.dart';

class KOrbitNodeLayer extends StatefulWidget {
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
    this.nodeActions,
    this.onContextMenuOpenChange,
    required this.repaint,
    required this.extentOverride,
    required this.opacityFor,
    required this.scaleFor,
    required this.isDeparting,
    this.sceneFor,
    this.labelVisibility = KOrbitLabelVisibility.interaction,
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
  final List<KMenuAction> Function(KOrbitNode)? nodeActions;
  final ValueChanged<bool>? onContextMenuOpenChange;
  final Listenable repaint;
  final double? extentOverride;
  final double Function(String id) opacityFor;
  final double Function(String id) scaleFor;
  final bool Function(String id) isDeparting;
  final KOrbitSceneProjection Function(Size)? sceneFor;
  final KOrbitLabelVisibility labelVisibility;
  final Widget? centerContent;

  @override
  State<KOrbitNodeLayer> createState() => _KOrbitNodeLayerState();
}

class _KOrbitNodeLayerState extends State<KOrbitNodeLayer> {
  String? hoveredId;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => AnimatedBuilder(
      animation: widget.repaint,
      builder: (context, _) {
        final size = constraints.biggest;
        final scene =
            widget.sceneFor?.call(size) ??
            projectKOrbitScene(
              size: size,
              levels: widget.levels,
              nodes: widget.nodes,
              connections: widget.connections,
              view: widget.view(),
              timeSeconds: widget.time(),
              radiusRatio: widget.tokens.componentOrbitCenterRadiusRatio,
              extentOverride: widget.extentOverride,
            );
        final labels = kOrbitLabelLayout(
          scene: scene,
          size: size,
          visibleIds: widget.labelVisibility == KOrbitLabelVisibility.always
              ? null
              : widget.labelVisibility == KOrbitLabelVisibility.hidden
              ? const <String>{}
              : {if (widget.selectedId != null) widget.selectedId!, ?hoveredId},
          fontSize: widget.tokens.componentOrbitNodeLabelSize,
          labelHeight: widget.tokens.fontCaptionLineHeight,
          labelOffset: widget.tokens.componentOrbitNodeLabelOffset,
          nodeSize: widget.tokens.componentOrbitNodeSize,
          selectedId: widget.selectedId,
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            final node = kOrbitHitTest(
              scene: scene,
              labels: labels,
              point: details.localPosition,
              hitTargetSize: widget.tokens.componentOrbitNodeHitTargetSize,
              eligible: (item) =>
                  !widget.isDeparting(item.node.id) && !_occluded(item, scene),
            );
            if (node != null) widget.onActivate(node);
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
    final radius = scene.radiusFor(node.id) * widget.scaleFor(node.id);
    final visualSize = radius * 2;
    final hitSize = visualSize < widget.tokens.componentOrbitNodeHitTargetSize
        ? widget.tokens.componentOrbitNodeHitTargetSize
        : visualSize;
    final occluded = _occluded(item, scene);
    final hidden = occluded || widget.isDeparting(node.id);
    final marker = _KOrbitMarker(
      node: node,
      selected: node.id == widget.selectedId,
      tokens: widget.tokens,
      size: visualSize,
      onActivate: hidden || node.disabled
          ? null
          : () => widget.onActivate(node),
      centerContent: node.isCenter ? widget.centerContent : null,
    );
    final depth = .55 + .45 * ((item.point.depth + 1) / 2).clamp(0, 1);
    return Positioned(
      left: item.point.offset.dx - hitSize / 2,
      top: item.point.offset.dy - hitSize / 2,
      width: hitSize,
      height: hitSize,
      child: MouseRegion(
        onEnter: (_) => setState(() => hoveredId = node.id),
        onExit: (_) =>
            setState(() => hoveredId = hoveredId == node.id ? null : hoveredId),
        child: ExcludeSemantics(
          excluding: hidden,
          child: Opacity(
            opacity: occluded ? 0 : depth * widget.opacityFor(node.id),
            child: widget.nodeActions == null
                ? marker
                : KContextMenu(
                    label: node.label,
                    actions: widget.nodeActions!(node),
                    onOpenChange: widget.onContextMenuOpenChange,
                    disabled: hidden || node.disabled,
                    child: marker,
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
    final depth = .55 + .45 * ((item.point.depth + 1) / 2).clamp(0, 1);
    return Positioned.fromRect(
      rect: Rect.fromLTWH(
        rect.left - widget.tokens.spaceControlGap,
        rect.top - widget.tokens.spaceMicro,
        rect.width + 2 * widget.tokens.spaceControlGap,
        rect.height + 2 * widget.tokens.spaceMicro,
      ),
      child: IgnorePointer(
        ignoring: true,
        child: Opacity(
          opacity: _occluded(item, scene)
              ? 0
              : depth * widget.opacityFor(item.node.id),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.tokens.spaceControlGap,
              vertical: widget.tokens.spaceMicro,
            ),
            decoration: BoxDecoration(
              color: widget.tokens.colorSurfaceRaised.withValues(
                alpha: widget.tokens.opacityProminent,
              ),
              borderRadius: BorderRadius.circular(widget.tokens.radiusControl),
            ),
            child: Text(
              item.node.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: item.node.isCenter
                  ? TextAlign.center
                  : TextAlign.start,
              style: TextStyle(
                color: widget.tokens.colorTextPrimary,
                fontFamily: widget.tokens.fontFamily,
                fontSize: widget.tokens.componentOrbitNodeLabelSize,
                height:
                    widget.tokens.fontCaptionLineHeight /
                    widget.tokens.componentOrbitNodeLabelSize,
                fontWeight: widget.tokens.fontLabelWeight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _occluded(KOrbitProjectedNode item, KOrbitSceneProjection scene) {
    final radius = scene.radiusFor(item.node.id);
    return scene.nodes.any(
      (other) =>
          other.node.id != item.node.id &&
          other.point.depth > item.point.depth &&
          (item.point.offset - other.point.offset).distance + radius <
              scene.radiusFor(other.node.id),
    );
  }
}

class _KOrbitMarker extends StatelessWidget {
  const _KOrbitMarker({
    required this.node,
    required this.selected,
    required this.tokens,
    required this.size,
    this.onActivate,
    this.centerContent,
  });

  final KOrbitNode node;
  final bool selected;
  final KDesignTokens tokens;
  final double size;
  final VoidCallback? onActivate;
  final Widget? centerContent;

  @override
  Widget build(BuildContext context) {
    final content =
        centerContent ??
        node.content ??
        (node.appearance == KOrbitNodeAppearance.sphere
            ? null
            : Text(
                _initials(node.label),
                style: TextStyle(
                  color: _tone(node),
                  fontWeight: tokens.fontLabelWeight,
                ),
              ));
    return Semantics(
      key: ValueKey('k-orbit-node-${node.id}'),
      button: !node.disabled,
      onTap: onActivate,
      selected: selected,
      label: node.label,
      hint: [
        node.description,
        node.badge?.label,
        node.progress == null ? null : '${node.progress!.round()}%',
        node.statusLabel ??
            (node.status == KOrbitStatus.idle ? null : node.status.name),
      ].whereType<String>().where((value) => value.isNotEmpty).join('. '),
      enabled: !node.disabled,
      child: Center(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (content != null)
                ClipOval(
                  child: SizedBox.square(
                    dimension: size,
                    child: FittedBox(
                      child: SizedBox.square(
                        dimension: tokens.componentOrbitNodeSize,
                        child: DefaultTextStyle(
                          style: TextStyle(
                            fontFamily: tokens.fontFamily,
                            fontSize: tokens.fontBodySize,
                            fontWeight: tokens.fontLabelWeight,
                            color: tokens.colorTextPrimary,
                          ),
                          child: Center(
                            child: FractionallySizedBox(
                              widthFactor:
                                  node.appearance == KOrbitNodeAppearance.avatar
                                  ? 1
                                  : .7,
                              heightFactor:
                                  node.appearance == KOrbitNodeAppearance.avatar
                                  ? 1
                                  : .7,
                              child: Center(child: content),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (selected)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tokens.colorBorderFocus,
                        width: tokens.borderWidthStrong,
                      ),
                    ),
                  ),
                ),
              if (node.showBadge &&
                  (node.badge != null || node.status != KOrbitStatus.idle))
                _badge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge() {
    final badge = node.badge;
    final color = badge == null ? _statusTone(node) : _toneValue(badge.tone);
    final content =
        badge?.content ??
        Text(switch (node.status) {
          KOrbitStatus.question => '?',
          KOrbitStatus.error => '!',
          KOrbitStatus.completed => '✓',
          _ => '•',
        });
    return Positioned(
      left: size * .85 - tokens.sizeContent / 2,
      top: size * .15 - tokens.sizeContent / 2,
      child: Transform.scale(
        scale: size / (2 * tokens.componentOrbitNodeSize),
        child: Container(
          width: tokens.sizeContent,
          height: tokens.sizeContent,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.colorSurfaceRaised,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: tokens.borderWidthDefault),
          ),
          child: IconTheme(
            data: IconThemeData(size: tokens.sizeContent * .65, color: color),
            child: DefaultTextStyle(
              style: TextStyle(
                color: color,
                fontSize: tokens.sizeContent * .65,
                fontWeight: tokens.fontLabelWeight,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String value) =>
      value.trim().characters.take(2).toString().toUpperCase();
  Color _statusTone(KOrbitNode item) => item.status == KOrbitStatus.question
      ? tokens.colorStatusWarningAccent
      : item.status == KOrbitStatus.error
      ? tokens.colorStatusErrorAccent
      : item.status == KOrbitStatus.completed
      ? tokens.colorStatusSuccessAccent
      : _tone(item);
  Color _tone(KOrbitNode item) => item.borderColor ?? _toneValue(item.tone);
  Color _toneValue(KOrbitTone tone) => switch (tone) {
    KOrbitTone.neutral => tokens.componentOrbitConnectionColor,
    KOrbitTone.brand => tokens.colorBrandPrimaryAccent,
    KOrbitTone.info => tokens.colorStatusInfoAccent,
    KOrbitTone.success => tokens.colorStatusSuccessAccent,
    KOrbitTone.warning => tokens.colorStatusWarningAccent,
    KOrbitTone.error => tokens.colorStatusErrorAccent,
  };
}
