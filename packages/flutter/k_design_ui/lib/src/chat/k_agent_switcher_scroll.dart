part of 'k_agent_switcher.dart';

typedef _AgentScrollBuilder = Widget Function(ScrollController controller);

class _AgentScroll extends StatefulWidget {
  const _AgentScroll({required this.orientation, required this.builder});
  final Axis orientation;
  final _AgentScrollBuilder builder;

  @override
  State<_AgentScroll> createState() => _AgentScrollState();
}

class _AgentScrollState extends State<_AgentScroll> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: _onPointerSignal,
    child: ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: const {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.stylus,
          PointerDeviceKind.invertedStylus,
          PointerDeviceKind.trackpad,
        },
      ),
      child: widget.builder(_controller),
    ),
  );

  void _onPointerSignal(PointerSignalEvent event) {
    if (widget.orientation != Axis.horizontal) return;
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    if (event.scrollDelta.dx != 0 || event.scrollDelta.dy == 0) return;
    final position = _controller.position;
    final target = (position.pixels + event.scrollDelta.dy).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return;
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      (_) => _controller.jumpTo(target),
    );
  }
}
