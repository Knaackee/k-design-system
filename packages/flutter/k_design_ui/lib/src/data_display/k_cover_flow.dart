import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../actions/k_icon_button.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_text.dart';

class KCoverFlowItem {
  const KCoverFlowItem({
    required this.id,
    required this.label,
    required this.child,
  });
  final String id, label;
  final Widget child;
}

/// Consumer-owned covers with configurable perspective and no automatic advance.
class KCoverFlow extends StatefulWidget {
  const KCoverFlow({
    super.key,
    required this.items,
    required this.label,
    this.selectedIndex,
    this.initialIndex = 0,
    this.onIndexChange,
    this.previousLabel = 'Previous cover',
    this.nextLabel = 'Next cover',
    this.itemWidth = 380,
    this.itemWidthFraction = .66,
    this.height = 400,
    this.contentPadding = 16,
    this.clipSides = true,
    this.sideAngle = 55,
    this.sideOffset = 68,
    this.sideScale = 1,
    this.visibleNeighbors = 3,
    this.keepMounted = false,
    this.depth = 120,
    this.spacing = 28,
    this.perspective = 1100,
    this.showControls = true,
    this.showCaption = true,
    this.reducedMotion = false,
  });

  final List<KCoverFlowItem> items;
  final String label, previousLabel, nextLabel;
  final int? selectedIndex;
  final int initialIndex;
  final int visibleNeighbors;
  final ValueChanged<int>? onIndexChange;

  /// Maximum fraction of the viewport occupied by a cover (0–1).
  final double itemWidthFraction;
  final double itemWidth,
      height,
      contentPadding,
      sideAngle,
      sideOffset,
      sideScale,
      depth,
      spacing,
      perspective;
  final bool keepMounted;
  final bool clipSides, showControls, showCaption, reducedMotion;

  @override
  State<KCoverFlow> createState() => _KCoverFlowState();
}

class _KCoverFlowState extends State<KCoverFlow> {
  late int _index = widget.initialIndex;
  double _drag = 0;
  bool _dragging = false;
  int get _selected => (widget.selectedIndex ?? _index).clamp(
    0,
    math.max(0, widget.items.length - 1),
  );

  void _select(int value) {
    final next = value.clamp(0, math.max(0, widget.items.length - 1)).toInt();
    final changed = next != _selected && widget.items.isNotEmpty;
    setState(() {
      _drag = 0;
      _dragging = false;
      _index = next;
    });
    if (changed) widget.onIndexChange?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final reduced =
        widget.reducedMotion || MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: widget.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Focus(
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              final next = switch (event.logicalKey) {
                LogicalKeyboardKey.arrowLeft => selected - 1,
                LogicalKeyboardKey.arrowRight => selected + 1,
                LogicalKeyboardKey.home => 0,
                LogicalKeyboardKey.end => widget.items.length - 1,
                _ => null,
              };
              if (next == null) return KeyEventResult.ignored;
              _select(next);
              return KeyEventResult.handled;
            },
            child: SizedBox(
              height: widget.height,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = math.min(
                    constraints.maxWidth *
                        widget.itemWidthFraction.clamp(.1, 1.0),
                    math.max(1.0, widget.itemWidth),
                  );
                  final step = math.max(
                    1.0,
                    width * math.max(0, widget.sideOffset) / 100,
                  );
                  final target = (selected + _drag)
                      .clamp(0.0, math.max(0.0, widget.items.length - 1.0))
                      .toDouble();
                  Widget stage = TweenAnimationBuilder<double>(
                    tween: Tween(end: target),
                    duration: reduced || _dragging
                        ? Duration.zero
                        : const Duration(milliseconds: 420),
                    curve: const Cubic(.2, .8, .2, 1),
                    builder: (context, position, _) {
                      final indices =
                          List.generate(widget.items.length, (i) => i)
                            ..removeWhere(
                              (i) =>
                                  !widget.keepMounted &&
                                  (i - position).abs() >
                                      math.max(1, widget.visibleNeighbors) + 1,
                            )
                            ..sort(
                              (a, b) => (b - position).abs().compareTo(
                                (a - position).abs(),
                              ),
                            );
                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          const SizedBox.expand(),
                          for (final i in indices)
                            Builder(
                              key: ValueKey(widget.items[i].id),
                              builder: (context) {
                                final offset = i - position;
                                final turn = math.min(1.0, offset.abs());
                                final x =
                                    offset.sign *
                                    (turn * math.max(0, widget.sideOffset) +
                                        math.max(0, offset.abs() - 1) *
                                            math.max(0, widget.spacing)) *
                                    width /
                                    100;
                                final scale =
                                    1 -
                                    turn * (1 - widget.sideScale.clamp(.1, 1));
                                final transform = Matrix4.identity()
                                  ..setEntry(
                                    3,
                                    2,
                                    -1 / math.max(1, widget.perspective),
                                  )
                                  ..translateByDouble(
                                    x,
                                    0,
                                    -turn * math.max(0, widget.depth),
                                    1,
                                  )
                                  ..rotateY(
                                    -offset.sign *
                                        turn *
                                        widget.sideAngle.clamp(0, 85) *
                                        math.pi /
                                        180,
                                  )
                                  ..scaleByDouble(scale, scale, 1, 1);
                                final visibility =
                                    (math.max(1, widget.visibleNeighbors) +
                                            1 -
                                            offset.abs())
                                        .clamp(0.0, 1.0);
                                final hidden = visibility == 0;
                                return IgnorePointer(
                                  ignoring: hidden,
                                  child: TickerMode(
                                    enabled: !hidden,
                                    child: Opacity(
                                      opacity: visibility,
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: transform,
                                        child: GestureDetector(
                                          onTap: () => _select(i),
                                          behavior: HitTestBehavior.opaque,
                                          child: SizedBox(
                                            width: width,
                                            height: widget.height * .9,
                                            child: Padding(
                                              padding: EdgeInsets.all(
                                                math.max(
                                                  0,
                                                  widget.contentPadding,
                                                ),
                                              ),
                                              child: ExcludeSemantics(
                                                excluding: i != selected,
                                                child: ExcludeFocus(
                                                  excluding: i != selected,
                                                  child: IgnorePointer(
                                                    ignoring: i != selected,
                                                    child:
                                                        widget.items[i].child,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  );
                  if (widget.clipSides) {
                    stage = ClipRect(
                      clipper: const _SideClipper(),
                      child: stage,
                    );
                  }
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: widget.items.length < 2
                        ? null
                        : (_) => setState(() => _dragging = true),
                    onHorizontalDragUpdate: widget.items.length < 2
                        ? null
                        : (event) =>
                              setState(() => _drag -= event.delta.dx / step),
                    onHorizontalDragEnd: widget.items.length < 2
                        ? null
                        : (_) => _select((_selected + _drag).round()),
                    onHorizontalDragCancel: () => setState(() {
                      _drag = 0;
                      _dragging = false;
                    }),
                    child: stage,
                  );
                },
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.showControls)
                KIconButton(
                  label: widget.previousLabel,
                  icon: KIconName.chevronLeft,
                  onPressed: selected == 0 || widget.items.isEmpty
                      ? null
                      : () => _select(selected - 1),
                ),
              Semantics(
                liveRegion: true,
                label: widget.items.isEmpty
                    ? ''
                    : '${widget.items[selected].label}, ${selected + 1} / ${widget.items.length}',
                child: ExcludeSemantics(
                  child: widget.showCaption
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              KText(
                                widget.items.isEmpty
                                    ? ''
                                    : widget.items[selected].label,
                              ),
                              if (widget.items.isNotEmpty)
                                KText(
                                  '${selected + 1} / ${widget.items.length}',
                                  variant: KTextVariant.caption,
                                ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              if (widget.showControls)
                KIconButton(
                  label: widget.nextLabel,
                  icon: KIconName.chevronRight,
                  onPressed: selected >= widget.items.length - 1
                      ? null
                      : () => _select(selected + 1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SideClipper extends CustomClipper<Rect> {
  const _SideClipper();
  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, double.negativeInfinity, size.width, double.infinity);
  @override
  bool shouldReclip(_SideClipper oldClipper) => false;
}
