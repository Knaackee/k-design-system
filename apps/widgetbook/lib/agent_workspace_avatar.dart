import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;

Future<rive.File?>? _file;
Future<rive.File?> _load() async {
  await rive.RiveNative.init();
  return rive.File.asset(
    'assets/rive/rive-character-v2.riv',
    riveFactory: rive.Factory.flutter,
  );
}

/// Gallery-owned avatar; the design-system layout accepts any widget.
class AgentWorkspaceAvatar extends StatefulWidget {
  const AgentWorkspaceAvatar({
    required this.shape,
    required this.color,
    this.status = 'idle',
    this.size = 144,
    this.label = 'Agent',
    super.key,
  });
  final String shape, status, label;
  final Color color;
  final double size;
  @override
  State<AgentWorkspaceAvatar> createState() => _AgentWorkspaceAvatarState();
}

class _AgentWorkspaceAvatarState extends State<AgentWorkspaceAvatar> {
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstance? _instance;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final file = await (_file ??= _load());
      if (!mounted) return;
      if (file == null) throw StateError('Avatar unavailable');
      final controller = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardSelector.byName('Avatar'),
        stateMachineSelector: rive.StateMachineSelector.byName('Avatar'),
      );
      _controller = controller;
      _instance = controller.dataBind(rive.DataBind.byName('Default'));
      _apply();
      setState(() {});
    } catch (_) {
      _file = null;
      if (mounted) setState(() => _failed = true);
    }
  }

  void _apply() {
    final vm = _instance;
    if (vm == null) return;
    for (final entry in {
      'bodyShape': widget.shape,
      'shapeTransition': 'hard',
      'status': widget.status,
      'pickMe': 'off',
      'accessory': 'none',
      'head': 'none',
      'faceAcc': 'none',
      'neck': 'none',
    }.entries) {
      vm.enumerator(entry.key)?.value = entry.value;
    }
    final reduced = MediaQuery.disableAnimationsOf(context);
    vm.boolean('reducedMotion')?.value = reduced;
    vm.boolean('fidgets')?.value = !reduced && widget.status == 'idle';
    // Resolve shape-entry defaults before applying the consumer's body color.
    _controller?.advance(1 / 60);
    _controller?.advance(1 / 60);
    vm.color('bodyColor')?.value = widget.color;
    _controller?.scheduleRepaint();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _apply();
  }

  @override
  void didUpdateWidget(AgentWorkspaceAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _apply();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: _failed ? '${widget.label}: Avatar nicht verfügbar' : widget.label,
    child: SizedBox.square(
      dimension: widget.size,
      child: _controller == null
          ? (_failed
                ? Center(child: Text(widget.label.characters.first))
                : const SizedBox.shrink())
          : IgnorePointer(
              child: RepaintBoundary(
                child: rive.RiveWidget(
                  controller: _controller!,
                  fit: rive.Fit.contain,
                ),
              ),
            ),
    ),
  );
}
