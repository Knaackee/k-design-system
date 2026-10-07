part of 'k_agent_switcher.dart';

typedef _AgentScrollBuilder = Widget Function(ScrollController controller);

class _HorizontalAgentScroll extends StatefulWidget {
  const _HorizontalAgentScroll({required this.builder});
  final _AgentScrollBuilder builder;

  @override
  State<_HorizontalAgentScroll> createState() => _HorizontalAgentScrollState();
}

class _HorizontalAgentScrollState extends State<_HorizontalAgentScroll> {
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
