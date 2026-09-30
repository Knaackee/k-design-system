import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

import 'orbit_demo_details.dart';
import 'orbit_demo_panel.dart';
import 'orbit_fixture_data.dart';

class OrbitFixture extends StatefulWidget {
  const OrbitFixture({
    this.communication = false,
    this.deep = false,
    this.freeze = false,
    super.key,
  });

  final bool communication, deep, freeze;

  @override
  State<OrbitFixture> createState() => _OrbitFixtureState();
}

class _OrbitFixtureState extends State<OrbitFixture> {
  final _controller = KOrbitController();
  final _events = <String>['Ready'];
  final _statuses = <String, KOrbitStatus>{};
  final _progress = <String, double>{};
  final _radii = <String, double>{};
  final _periods = <String, double>{};
  final _pulses = <String, bool>{};
  final _badges = <String, KOrbitBadge?>{};
  OrbitDemoFilter _filter = OrbitDemoFilter.all;
  KOrbitLabelVisibility _labelVisibility = KOrbitLabelVisibility.interaction;
  KOrbitSignalStyle _signalStyle = KOrbitSignalStyle.trail;
  String? _selected, _pinned;
  bool _showAdded = false, _paused = false;
  double _speed = 1, _duration = 1800, _minZoom = .65;
  double _maxZoom = 2.2, _maxAngularSpeed = 12;
  int _sequence = 1;

  @override
  void initState() {
    super.initState();
    if (widget.deep) _maxZoom = 5;
  }

  List<KOrbitNode> _allNodes(KDesignTokens tokens) {
    final source = [
      ...orbitNodes(tokens),
      if (widget.deep) ...orbitDeepExtraNodes,
      if (_showAdded) ...orbitAddedNodes,
    ];
    return [
      for (final node in source)
        node.copyWith(
          status: _statuses[node.id] ?? node.status,
          pulse:
              _pulses[node.id] ??
              (_statuses[node.id] ?? node.status) == KOrbitStatus.question,
          statusLabel:
              (_statuses[node.id] ?? node.status) == KOrbitStatus.question
              ? 'Needs your answer'
              : null,
          progress: _progress[node.id] ?? node.progress,
          radius: _radii[node.id] ?? node.radius,
          periodSeconds: _periods[node.id] ?? node.periodSeconds,
          badge: _badges.containsKey(node.id) ? _badges[node.id] : node.badge,
        ),
    ];
  }

  List<KOrbitNode> _visibleNodes(List<KOrbitNode> allNodes) {
    if (_filter == OrbitDemoFilter.all) return allNodes;
    final byId = {for (final node in allNodes) node.id: node};
    final visible = <String>{};
    for (final node in allNodes) {
      final matches = switch (_filter) {
        OrbitDemoFilter.active => node.status == KOrbitStatus.active,
        OrbitDemoFilter.questions => node.status == KOrbitStatus.question,
        OrbitDemoFilter.all => true,
      };
      if (!matches) continue;
      KOrbitNode? current = node;
      while (current != null) {
        visible.add(current.id);
        current = current.parentId == null ? null : byId[current.parentId];
      }
    }
    return allNodes.where((node) => visible.contains(node.id)).toList();
  }

  List<KOrbitConnection> _visibleConnections(List<KOrbitNode> nodes) {
    final source = [
      ...(widget.deep ? orbitDeepConnections : orbitConnections),
      if (_showAdded) ...orbitAddedConnections,
    ];
    final ids = nodes.map((node) => node.id).toSet();
    return source
        .where(
          (connection) =>
              ids.contains(connection.sourceId) &&
              ids.contains(connection.targetId),
        )
        .toList();
  }

  void _log(String event) => setState(() {
    _events.insert(0, event);
    if (_events.length > 6) _events.removeLast();
  });

  void _triggerConnection(String connectionId) {
    final id = 'demo-signal-${_sequence++}';
    final result = _controller.triggerSignal(
      KOrbitSignal(
        id: id,
        connectionId: connectionId,
        duration: Duration(milliseconds: _duration.round()),
        style: _signalStyle,
      ),
    );
    _log('$id: ${result.name}');
  }

  void _triggerSelected() {
    if (_selected == null) return;
    final id = 'node-ping-${_sequence++}';
    final result = _controller.triggerSignal(
      KOrbitSignal(
        id: id,
        nodeId: _selected,
        duration: Duration(milliseconds: _duration.round()),
      ),
    );
    _log('$id: ${result.name}');
  }

  void _toggleStatus(KOrbitNode? selected, KOrbitStatus status) {
    if (selected == null) return;
    final next = selected.status == status ? KOrbitStatus.idle : status;
    setState(() => _statuses[selected.id] = next);
    _log('${selected.label}: ${next.name}');
  }

  void _openDetails(KOrbitNode? node) {
    if (node == null) return;
    setState(() => _selected = node.id);
    showOrbitDemoDetails(
      context: context,
      node: node,
      pinnedNodeId: _pinned,
      onPinnedChange: (value) => setState(() => _pinned = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    final allNodes = _allNodes(tokens);
    final nodes = _visibleNodes(allNodes);
    final connections = _visibleConnections(nodes);
    final selected = allNodes.where((node) => node.id == _selected).firstOrNull;
    final orbit = KOrbit(
      levels: widget.deep ? orbitDeepLevels : orbitLevels,
      nodes: nodes,
      connections: connections,
      controller: _controller,
      initialViewState: const KOrbitViewState(zoom: 1.15),
      selectedNodeId: _selected,
      selectionControlled: true,
      pinnedNodeId: _pinned,
      onPinnedChange: (value) => setState(() => _pinned = value),
      labelVisibility: _labelVisibility,
      motionSpeed: _speed,
      maxAngularSpeed: _maxAngularSpeed,
      paused: _paused,
      elapsedSeconds: widget.freeze ? 0 : null,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
      onMotionSpeedChange: (value) => setState(() => _speed = value),
      onPausedChange: (value) => setState(() => _paused = value),
      onSelectionChange: (value) => setState(() => _selected = value),
      onNodeActivate: _openDetails,
      showControls: true,
      onSignalEnd: (id, reason) => _log('$id: ${reason.name}'),
    );
    final panel = OrbitDemoPanel(
      communication: widget.communication,
      deep: widget.deep,
      nodes: nodes,
      allNodes: allNodes,
      selectedNode: selected,
      pinnedNodeId: _pinned,
      filter: _filter,
      labelVisibility: _labelVisibility,
      showAdded: _showAdded,
      signalStyle: _signalStyle,
      duration: _duration,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
      maxAngularSpeed: _maxAngularSpeed,
      events: _events,
      onSelected: (value) => setState(() => _selected = value),
      onProgress: (value) => setState(() => _progress[selected!.id] = value),
      onRadius: (value) => setState(() => _radii[selected!.id] = value),
      onPeriod: (value) => setState(() => _periods[selected!.id] = value),
      onPulse: () =>
          setState(() => _pulses[selected!.id] = !(selected.pulse ?? false)),
      onBadge: () => setState(
        () => _badges[selected!.id] = selected.badge == null
            ? const KOrbitBadge(
                content: Text('99+'),
                label: '99+ updates',
                tone: KOrbitTone.info,
              )
            : null,
      ),
      onPinned: (value) => setState(() => _pinned = value),
      onFilter: (value) => setState(() => _filter = value),
      onLabelVisibility: (value) => setState(() => _labelVisibility = value),
      onShowAdded: () => setState(() => _showAdded = !_showAdded),
      onOpenDetails: () => _openDetails(selected),
      onStatus: (value) => _toggleStatus(selected, value),
      onPingSelected: _triggerSelected,
      onTrigger: () => _triggerConnection('team-issue-a'),
      onSignalStyle: (value) => setState(() => _signalStyle = value),
      onDuration: (value) => setState(() => _duration = value),
      onBurst: () {
        for (final connection in connections.take(5)) {
          _triggerConnection(connection.id);
        }
      },
      onMinZoom: (value) => setState(() => _minZoom = value),
      onMaxZoom: (value) => setState(() => _maxZoom = value),
      onMaxAngularSpeed: (value) => setState(() => _maxAngularSpeed = value),
    );
    return ColoredBox(
      color: tokens.colorSurfaceCanvas,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceControlGap),
          child: LayoutBuilder(
            builder: (context, constraints) =>
                MediaQuery.sizeOf(context).width >= 900
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: orbit),
                      SizedBox(width: tokens.spaceControlGap),
                      SizedBox(width: 352, child: panel),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 55, child: orbit),
                      SizedBox(height: tokens.spaceControlGap),
                      Expanded(flex: 45, child: panel),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
