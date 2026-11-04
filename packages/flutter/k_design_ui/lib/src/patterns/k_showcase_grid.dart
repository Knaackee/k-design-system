import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

class KShowcaseGridItem {
  const KShowcaseGridItem({required this.id, required this.content});
  final String id;

  /// Decorative content; avoid GlobalKeys because looping repeats each item.
  final Widget content;
}

/// Decorative preview wall. The foreground alone is interactive and semantic.
class KShowcaseGrid extends StatefulWidget {
  const KShowcaseGrid({
    required this.items,
    this.child,
    this.columns = 4,
    this.compactColumns = 2,
    this.tilt = -8,
    this.gap,
    this.animate = true,
    this.durationMs = 900,
    this.staggerMs = 90,
    this.edgeFade = true,
    this.loop = false,
    this.loopDurationMs = 45000,
    super.key,
  });
  final List<KShowcaseGridItem> items;
  final Widget? child;
  final int columns, compactColumns, durationMs, staggerMs, loopDurationMs;
  final double tilt;
  final double? gap;
  final bool animate, edgeFade, loop;
  @override
  State<KShowcaseGrid> createState() => _KShowcaseGridState();
}

class _KShowcaseGridState extends State<KShowcaseGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(vsync: this);
  double _groupHeight = 0;
  bool _reduced = false;
  int get _entranceMs =>
      math.max(1, widget.durationMs) +
      math.min(11, math.max(0, widget.items.length - 1)) *
          math.max(0, widget.staggerMs);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(KShowcaseGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loop != widget.loop) _animation.value = 0;
    _sync();
  }

  void _sync() {
    _animation.stop();
    _animation.duration = Duration(
      milliseconds: widget.loop
          ? math.max(1000, widget.loopDurationMs)
          : _entranceMs,
    );
    if (_reduced || !widget.animate || widget.items.isEmpty) return;
    if (widget.loop) {
      _animation.repeat();
    } else {
      _animation.forward();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 512.0;
        final columns = (width <= 640 ? widget.compactColumns : widget.columns)
            .clamp(1, 12);
        final gap = (widget.gap?.isFinite ?? false)
            ? math.max(0.0, widget.gap!)
            : tokens.spaceLayoutSectionGap;
        final planeWidth = width * 1.2;
        final tiltRadians =
            (widget.tilt.isFinite ? widget.tilt : -8) * math.pi / 180;
        // Center the tilted wall in the lower, visible part of tall phones;
        // the upper portion is faded behind the foreground content.
        final compactTiltOffset = width <= 640
            ? math.sin(tiltRadians) * height * .75
            : 0.0;
        Widget group() => ConstrainedBox(
          constraints: BoxConstraints(minHeight: widget.loop ? height : 0),
          child: Padding(
            padding: EdgeInsets.only(bottom: widget.loop ? gap : 0),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var index = 0; index < widget.items.length; index++)
                  SizedBox(
                    key: ValueKey(widget.items[index].id),
                    width: math.max(
                      0,
                      (planeWidth - (columns - 1) * gap) / columns,
                    ),
                    child: _entry(widget.items[index], index),
                  ),
              ],
            ),
          ),
        );
        Widget backdrop = OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: planeWidth,
          maxWidth: planeWidth,
          minHeight: 0,
          maxHeight: double.infinity,
          child: Transform.translate(
            offset: Offset(-width * .1 + compactTiltOffset, -width * .06),
            child: Transform.rotate(
              angle: tiltRadians,
              alignment: Alignment.topCenter,
              child: AnimatedBuilder(
                animation: _animation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MeasureHeight(
                      onHeight: (value) {
                        if (mounted && _groupHeight != value) {
                          setState(() => _groupHeight = value);
                        }
                      },
                      child: group(),
                    ),
                    if (widget.loop) group(),
                  ],
                ),
                builder: (context, child) => Transform.translate(
                  offset: Offset(
                    0,
                    widget.loop && !_reduced
                        ? -_animation.value * _groupHeight
                        : 0,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
        if (widget.edgeFade) {
          backdrop = ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: widget.loop
                  ? const [Colors.transparent, Colors.white]
                  : const [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
              stops: widget.loop ? const [.38, .82] : const [0, .16, .78, 1],
            ).createShader(rect),
            child: backdrop,
          );
        }
        return SizedBox(
          width: width,
          height: height,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ExcludeSemantics(child: IgnorePointer(child: backdrop)),
                if (widget.child != null)
                  // The foreground scrolls when large system text makes it
                  // taller than the stage; it stays centred otherwise.
                  LayoutBuilder(
                    builder: (context, stage) => SingleChildScrollView(
                      padding: EdgeInsets.all(tokens.spaceLayoutSectionGap),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: math.max(
                            0,
                            stage.maxHeight - 2 * tokens.spaceLayoutSectionGap,
                          ),
                        ),
                        child: Center(child: widget.child),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _entry(KShowcaseGridItem item, int index) {
    if (widget.loop || _reduced || !widget.animate) return item.content;
    return AnimatedBuilder(
      animation: _animation,
      child: item.content,
      builder: (context, child) {
        final elapsed =
            _animation.value * _entranceMs -
            math.min(index, 11) * math.max(0, widget.staggerMs);
        final progress = (elapsed / math.max(1, widget.durationMs)).clamp(
          0.0,
          1.0,
        );
        final eased = const Cubic(.16, 1, .3, 1).transform(progress);
        return Opacity(
          opacity: eased,
          child: FractionalTranslation(
            translation: Offset(0, .35 * (1 - eased)),
            child: child,
          ),
        );
      },
    );
  }
}

class _MeasureHeight extends SingleChildRenderObjectWidget {
  const _MeasureHeight({required this.onHeight, required super.child});
  final ValueChanged<double> onHeight;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _HeightObserver(onHeight);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant _HeightObserver renderObject,
  ) {
    renderObject.onHeight = onHeight;
  }
}

class _HeightObserver extends RenderProxyBox {
  _HeightObserver(this.onHeight);
  ValueChanged<double> onHeight;
  double? _last;
  @override
  void performLayout() {
    super.performLayout();
    if (size.height == _last) return;
    _last = size.height;
    final height = size.height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onHeight(height);
    });
  }
}
