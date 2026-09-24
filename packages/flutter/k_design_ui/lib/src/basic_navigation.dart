import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import 'actions/k_icon_button.dart';
import 'primitives/k_icon.dart';

class KBreadcrumbItem {
  const KBreadcrumbItem({required this.id, required this.label, this.onSelect});
  final String id;
  final String label;
  final VoidCallback? onSelect;
}

class KBreadcrumb extends StatelessWidget {
  const KBreadcrumb({
    required this.items,
    this.label = 'Breadcrumb',
    this.separator,
    super.key,
  });
  final List<KBreadcrumbItem> items;
  final String label;
  final Widget? separator;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      label: label,
      container: true,
      child: Wrap(
        spacing: t.spaceControlGap,
        runSpacing: t.spaceControlGap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (index, item) in items.indexed) ...[
            if (index == items.length - 1)
              Semantics(
                selected: true,
                child: Text(
                  item.label,
                  style: _textStyle(
                    t,
                    t.fontControlSize,
                    t.fontControlWeight,
                    t.colorTextPrimary,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: item.onSelect,
                style: TextButton.styleFrom(
                  minimumSize: Size(0, t.sizeHitTarget),
                  padding: EdgeInsets.symmetric(horizontal: t.spaceControlGap),
                  foregroundColor: t.colorTextMuted,
                ),
                child: Text(item.label),
              ),
            if (index != items.length - 1)
              separator ?? const KIcon(KIconName.chevronRight, size: 14),
          ],
        ],
      ),
    );
  }
}

class KCarousel extends StatefulWidget {
  const KCarousel({
    required this.label,
    required this.children,
    this.previousLabel = 'Previous slide',
    this.nextLabel = 'Next slide',
    this.previousIcon = KIconName.chevronLeft,
    this.nextIcon = KIconName.chevronRight,
    this.initialIndex = 0,
    this.onIndexChanged,
    super.key,
  });
  final String label;
  final List<Widget> children;
  final String previousLabel;
  final String nextLabel;
  final KIconName previousIcon;
  final KIconName nextIcon;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  @override
  State<KCarousel> createState() => _KCarouselState();
}

class _KCarouselState extends State<KCarousel> {
  late final PageController controller;
  late int index;
  @override
  void initState() {
    super.initState();
    index = widget.children.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.children.length - 1).toInt();
    controller = PageController(initialPage: index);
  }

  @override
  void didUpdateWidget(covariant KCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.isEmpty) {
      index = 0;
      return;
    }
    if (index < widget.children.length) return;
    index = widget.children.length - 1;
    controller.jumpToPage(index);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void select(int value) {
    if (widget.children.isEmpty) return;
    final next = value.clamp(0, widget.children.length - 1).toInt();
    controller.animateToPage(
      next,
      duration: (Theme.of(
        context,
      ).extension<KDesignTokens>()!).componentCarouselTransitionDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Semantics(
      label: widget.label,
      container: true,
      child: Focus(
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            select(index - 1);
            return KeyEventResult.handled;
          }
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            select(index + 1);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                KIconButton(
                  label: widget.previousLabel,
                  icon: widget.previousIcon,
                  onPressed: index == 0 ? null : () => select(index - 1),
                ),
                SizedBox(width: t.spaceControlGap),
                Expanded(
                  child: SizedBox(
                    height: t.componentCarouselSlideHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(t.radiusCard),
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: const {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.stylus,
                            PointerDeviceKind.trackpad,
                          },
                          scrollbars: false,
                        ),
                        child: PageView.builder(
                          controller: controller,
                          physics: const PageScrollPhysics(),
                          itemCount: widget.children.length,
                          onPageChanged: (value) {
                            setState(() => index = value);
                            widget.onIndexChanged?.call(value);
                          },
                          itemBuilder: (_, slide) => Semantics(
                            label: '${slide + 1} of ${widget.children.length}',
                            child: widget.children[slide],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: t.spaceControlGap),
                KIconButton(
                  label: widget.nextLabel,
                  icon: widget.nextIcon,
                  onPressed: index >= widget.children.length - 1
                      ? null
                      : () => select(index + 1),
                ),
              ],
            ),
            SizedBox(height: t.spaceControlGap),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var dot = 0; dot < widget.children.length; dot++)
                  Container(
                    width: t.componentCarouselDotSize,
                    height: t.componentCarouselDotSize,
                    margin: EdgeInsets.symmetric(
                      horizontal: t.componentCarouselDotGap / 2,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dot == index
                          ? t.colorActionPrimaryBackground
                          : t.colorBorderStrong,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

TextStyle _textStyle(
  KDesignTokens t,
  double size,
  FontWeight weight,
  Color color,
) => TextStyle(
  color: color,
  fontFamily: t.fontFamily,
  fontSize: size,
  fontWeight: weight,
  height: t.fontRelaxedHeight,
  leadingDistribution: TextLeadingDistribution.even,
  fontVariations: [
    FontVariation.weight(weight.value.toDouble()),
    FontVariation.opticalSize(size.clamp(14, 32)),
  ],
);
