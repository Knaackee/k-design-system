part of 'k_offer_overview.dart';

class _KOfferDragData {
  _KOfferDragData(this.id, this.category);
  final String id, category;
  Offset anchor = Offset.zero;
}

class _KOfferDragRow extends StatelessWidget {
  const _KOfferDragRow({
    required this.data,
    required this.enabled,
    required this.child,
    required this.onDrop,
    super.key,
  });
  final _KOfferDragData data;
  final bool enabled;
  final Widget child;
  final void Function(_KOfferDragData data, bool after) onDrop;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => DragTarget<_KOfferDragData>(
      onWillAcceptWithDetails: (d) => enabled && d.data.id != data.id,
      onAcceptWithDetails: (d) {
        final box = context.findRenderObject()! as RenderBox;
        onDrop(
          d.data,
          box.globalToLocal(d.offset + d.data.anchor).dy > box.size.height / 2,
        );
      },
      builder: (context, candidates, _) => DecoratedBox(
        decoration: BoxDecoration(
          border: candidates.isEmpty
              ? null
              : Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).extension<KDesignTokens>()!.colorActionPrimaryBackground,
                    width: Theme.of(
                      context,
                    ).extension<KDesignTokens>()!.borderWidthStrong,
                  ),
                ),
        ),
        child: LongPressDraggable<_KOfferDragData>(
          data: data,
          dragAnchorStrategy: (_, context, position) {
            data.anchor = (context.findRenderObject()! as RenderBox)
                .globalToLocal(position);
            return data.anchor;
          },
          maxSimultaneousDrags: enabled ? 1 : 0,
          feedback: Material(
            elevation: 5,
            borderRadius: BorderRadius.circular(
              Theme.of(context).extension<KDesignTokens>()!.radiusExtraLarge,
            ),
            color: Theme.of(
              context,
            ).extension<KDesignTokens>()!.colorSurfaceRaised,
            child: SizedBox(width: constraints.maxWidth, child: child),
          ),
          childWhenDragging: Opacity(
            opacity: Theme.of(context).extension<KDesignTokens>()!.opacityDrag,
            child: child,
          ),
          child: child,
        ),
      ),
    ),
  );
}

class _KOfferDropArea extends StatelessWidget {
  const _KOfferDropArea({
    required this.enabled,
    required this.child,
    required this.onDrop,
  });
  final bool enabled;
  final Widget child;
  final ValueChanged<_KOfferDragData> onDrop;
  @override
  Widget build(BuildContext context) => DragTarget<_KOfferDragData>(
    onWillAcceptWithDetails: (_) => enabled,
    onAcceptWithDetails: (d) => onDrop(d.data),
    builder: (context, candidates, _) => ColoredBox(
      color: candidates.isEmpty
          ? Colors.transparent
          : Theme.of(
              context,
            ).extension<KDesignTokens>()!.colorBrandPrimaryBackground,
      child: child,
    ),
  );
}
