part of 'k_map_location_picker.dart';

class _LandingMarker extends StatefulWidget {
  const _LandingMarker({required this.animate, super.key});

  final bool animate;

  @override
  State<_LandingMarker> createState() => _LandingMarkerState();
}

class _LandingMarkerState extends State<_LandingMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this, value: 1);
    if (widget.animate) {
      _controller.value = 0;
      _controller.animateWith(
        SpringSimulation(
          const SpringDescription(mass: 1, stiffness: 350, damping: 18),
          0,
          1,
          0,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final marker = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.colorSurfaceRaised,
        border: Border.all(
          color: tokens.colorBrandPrimaryAccent,
          width: tokens.borderWidthStrong,
        ),
        borderRadius: BorderRadius.circular(tokens.radiusFull),
        boxShadow: tokens.elevationMedium,
      ),
      child: SizedBox.square(
        dimension: tokens.spaceHairline * 44,
        child: const Center(child: KIcon(KIconName.mapPin, size: 32)),
      ),
    );
    if (!widget.animate) return marker;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -20 * (1 - value)),
            child: Transform.scale(scale: .8 + .2 * value, child: child),
          ),
        );
      },
      child: marker,
    );
  }
}
