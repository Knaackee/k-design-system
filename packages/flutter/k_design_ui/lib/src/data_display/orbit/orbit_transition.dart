import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'orbit_models.dart';
import 'orbit_projection.dart';

class KOrbitNodeTransition extends ChangeNotifier {
  KOrbitNodeTransition({
    required TickerProvider vsync,
    required List<KOrbitNode> initialNodes,
    required List<KOrbitLevel> initialLevels,
  }) : _nodes = initialNodes,
       _levels = initialLevels,
       _controller = AnimationController(
         vsync: vsync,
         duration: Duration.zero,
       ) {
    _controller
      ..addListener(notifyListeners)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        _nodes = _target;
        _levels = _targetLevels;
        _entering.clear();
        _departing.clear();
        notifyListeners();
      });
  }

  final AnimationController _controller;
  List<KOrbitNode> _nodes;
  List<KOrbitLevel> _levels;
  List<KOrbitNode> _target = const [];
  List<KOrbitLevel> _targetLevels = const [];
  final Set<String> _entering = {};
  final Set<String> _departing = {};
  double _fromExtent = 1;
  double _toExtent = 1;

  List<KOrbitNode> get nodes => _nodes;
  List<KOrbitLevel> get levels => _levels;
  double get extent => lerpDouble(_fromExtent, _toExtent, _controller.value)!;
  double? get extentOverride => _controller.isAnimating ? extent : null;

  void setDuration(Duration value) => _controller.duration = value;

  void update({
    required List<KOrbitLevel> oldLevels,
    required List<KOrbitLevel> levels,
    required List<KOrbitNode> oldNodes,
    required List<KOrbitNode> nodes,
    required bool reducedMotion,
  }) {
    final oldIds = oldNodes.map((node) => node.id).toSet();
    final nextIds = nodes.map((node) => node.id).toSet();
    final entering = nextIds.difference(oldIds);
    final departing = oldIds.difference(nextIds);
    if (entering.isEmpty && departing.isEmpty) {
      _target = nodes;
      _targetLevels = levels;
      if (_controller.isAnimating) {
        _nodes = [
          ...nodes,
          for (final node in _nodes)
            if (_departing.contains(node.id) && !nextIds.contains(node.id))
              node,
        ];
      } else {
        _nodes = nodes;
        _levels = levels;
      }
      return;
    }
    if (reducedMotion || _controller.duration == Duration.zero) {
      _controller.stop();
      _nodes = _target = nodes;
      _levels = _targetLevels = levels;
      _entering.clear();
      _departing.clear();
      notifyListeners();
      return;
    }
    _entering
      ..clear()
      ..addAll(entering);
    _departing
      ..clear()
      ..addAll(departing);
    _fromExtent = _controller.isAnimating
        ? extent
        : kOrbitExtentFor(levels: oldLevels, nodes: oldNodes);
    _toExtent = kOrbitExtentFor(levels: levels, nodes: nodes);
    _target = nodes;
    _targetLevels = levels;
    final next = <KOrbitNode>[...nodes];
    for (final node in oldNodes) {
      if (_departing.contains(node.id)) next.add(node);
    }
    _nodes = next;
    final neededLevels = next
        .map((node) => node.levelId)
        .whereType<String>()
        .toSet();
    _levels = [
      ...levels,
      for (final level in oldLevels)
        if (neededLevels.contains(level.id) &&
            !levels.any((current) => current.id == level.id))
          level,
    ];
    _controller.forward(from: 0);
  }

  double opacityFor(String id) {
    if (_entering.contains(id)) return _controller.value;
    if (_departing.contains(id)) return 1 - _controller.value;
    return 1;
  }

  double scaleFor(String id) => _departing.contains(id)
      ? 1 - _controller.value * .15
      : _entering.contains(id)
      ? .85 + _controller.value * .15
      : 1;

  bool isDeparting(String id) => _departing.contains(id);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
