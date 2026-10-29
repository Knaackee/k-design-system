import 'package:flutter/widgets.dart';

/// Keeps row keys stable across reparenting, regrouping and undo.
/// All tree rows share one extent, so their positions can animate without
/// imposing separate reorder state on the controlled consumer model.
class SortableTreeMotion extends StatelessWidget {
  const SortableTreeMotion({
    required this.children,
    required this.rowExtent,
    required this.duration,
    super.key,
  });

  final List<Widget> children;
  final double rowExtent;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final effectiveDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : duration;
    return AnimatedSize(
      duration: effectiveDuration,
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: rowExtent * children.length,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < children.length; index++)
              AnimatedPositioned(
                key: children[index].key ?? ValueKey('tree-extra-$index'),
                duration: effectiveDuration,
                curve: Curves.easeInOut,
                top: rowExtent * index,
                left: 0,
                right: 0,
                height: rowExtent,
                child: children[index],
              ),
          ],
        ),
      ),
    );
  }
}
