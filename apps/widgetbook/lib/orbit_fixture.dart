import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

const orbitLevels = [
  KOrbitLevel(
    id: 'projects',
    label: 'Projects',
    radius: 153,
    inclination: 1.043,
    azimuth: 0.488692,
    periodSeconds: 44,
  ),
  KOrbitLevel(
    id: 'issues',
    label: 'Issues',
    radius: 62,
    inclination: 0.85,
    azimuth: -0.418879,
    periodSeconds: 26,
    clockwise: false,
  ),
  KOrbitLevel(
    id: 'people',
    label: 'Agents and people',
    radius: 42,
    inclination: 0.9,
    azimuth: 0.331613,
    periodSeconds: 16,
  ),
];

const orbitNodes = [
  KOrbitNode(
    id: 'team',
    label: 'Platform team',
    description: 'The shared team center',
    status: KOrbitStatus.idle,
    content: KIcon(KIconName.folder, size: 16),
  ),
  KOrbitNode(
    id: 'atlas',
    levelId: 'projects',
    parentId: 'team',
    label: 'Atlas',
    description: 'Design system release',
    phase: 0.15,
    content: KIcon(KIconName.folder, size: 16),
  ),
  KOrbitNode(
    id: 'relay',
    levelId: 'projects',
    parentId: 'team',
    label: 'Relay',
    description: 'Messaging workspace',
    phase: 3.2,
    content: KIcon(KIconName.folder, size: 16),
  ),
  KOrbitNode(
    id: 'issue-a',
    levelId: 'issues',
    parentId: 'atlas',
    label: 'Token parity',
    description: 'Align Web and Flutter tokens',
    phase: 0.8,
    status: KOrbitStatus.question,
    statusLabel: 'Needs your answer',
    pulse: true,
    content: KIcon(KIconName.circleDot, size: 16),
  ),
  KOrbitNode(
    id: 'issue-b',
    levelId: 'issues',
    parentId: 'relay',
    label: 'Delivery status',
    description: 'Surface visual message progress',
    phase: 3.9,
    content: KIcon(KIconName.circleDot, size: 16),
  ),
  KOrbitNode(
    id: 'agent',
    levelId: 'people',
    parentId: 'issue-a',
    label: 'Orbit agent',
    description: 'Works on shared components',
    phase: 1.5,
    status: KOrbitStatus.active,
    content: KIcon(KIconName.bot, size: 16),
  ),
  KOrbitNode(
    id: 'human',
    levelId: 'people',
    parentId: 'issue-b',
    label: 'Mina',
    description: 'Product designer',
    phase: 4.5,
    content: KIcon(KIconName.user, size: 16),
  ),
];

const orbitConnections = [
  KOrbitConnection(
    id: 'team-atlas',
    sourceId: 'team',
    targetId: 'atlas',
    lineStyle: KOrbitLineStyle.solid,
  ),
  KOrbitConnection(
    id: 'team-relay',
    sourceId: 'team',
    targetId: 'relay',
    lineStyle: KOrbitLineStyle.solid,
  ),
  KOrbitConnection(id: 'atlas-issue', sourceId: 'atlas', targetId: 'issue-a'),
  KOrbitConnection(id: 'relay-issue', sourceId: 'relay', targetId: 'issue-b'),
  KOrbitConnection(id: 'issue-agent', sourceId: 'issue-a', targetId: 'agent'),
  KOrbitConnection(id: 'issue-human', sourceId: 'issue-b', targetId: 'human'),
  KOrbitConnection(
    id: 'agent-human',
    sourceId: 'agent',
    targetId: 'human',
    lineStyle: KOrbitLineStyle.dotted,
  ),
];

class OrbitFixture extends StatefulWidget {
  const OrbitFixture({
    this.communication = false,
    this.freeze = false,
    super.key,
  });

  final bool communication;
  final bool freeze;

  @override
  State<OrbitFixture> createState() => _OrbitFixtureState();
}

class _OrbitFixtureState extends State<OrbitFixture> {
  final _controller = KOrbitController();
  final _events = <String>['Ready'];
  bool _activeOnly = false;
  bool _answered = false;
  bool _paused = false;
  double _speed = 1;
  String? _selected;
  KOrbitSignalStyle _signalStyle = KOrbitSignalStyle.point;
  double _duration = 1200;
  int _signalCount = 1;

  List<KOrbitNode> get _allNodes => [
    for (final node in orbitNodes)
      if (node.id == 'issue-a' && _answered)
        const KOrbitNode(
          id: 'issue-a',
          levelId: 'issues',
          parentId: 'atlas',
          label: 'Token parity',
          description: 'Align Web and Flutter tokens',
          phase: 0.8,
          content: KIcon(KIconName.circleDot, size: 16),
        )
      else
        node,
  ];

  List<KOrbitNode> get _nodes => _activeOnly
      ? _allNodes
            .where((node) => !{'relay', 'issue-b', 'human'}.contains(node.id))
            .toList()
      : _allNodes;

  List<KOrbitConnection> get _connections {
    final ids = _nodes.map((node) => node.id).toSet();
    return orbitConnections
        .where(
          (item) => ids.contains(item.sourceId) && ids.contains(item.targetId),
        )
        .toList();
  }

  void _trigger(String connectionId) {
    final id = 'demo-signal-${_signalCount++}';
    final result = _controller.triggerSignal(
      KOrbitSignal(
        id: id,
        connectionId: connectionId,
        duration: Duration(milliseconds: _duration.round()),
        style: _signalStyle,
      ),
    );
    setState(() {
      _events.insert(0, '$id: ${result.name}');
      if (_events.length > 6) _events.removeLast();
    });
  }

  void _showDetails(KOrbitNode node) {
    setState(() => _selected = node.id);
    KResponsiveDrawer.show<void>(
      context: context,
      title: Text(node.label),
      description: node.description == null ? null : Text(node.description!),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KText('Stable ID: ${node.id}'),
          KText(
            'Parent: ${node.parentId ?? 'None'}',
            variant: KTextVariant.bodySmall,
          ),
          KText(
            'Level: ${node.levelId ?? 'Center'}',
            variant: KTextVariant.bodySmall,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<KDesignTokens>()!;
    return ColoredBox(
      color: tokens.colorSurfaceCanvas,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(tokens.spaceCardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KOrbit(
                    levels: orbitLevels,
                    nodes: _nodes,
                    connections: _connections,
                    controller: _controller,
                    selectedNodeId: _selected,
                    selectionControlled: true,
                    motionSpeed: _speed,
                    paused: _paused,
                    elapsedSeconds: widget.freeze ? 0 : null,
                    onMotionSpeedChange: (value) =>
                        setState(() => _speed = value),
                    onPausedChange: (value) => setState(() => _paused = value),
                    onSelectionChange: (value) =>
                        setState(() => _selected = value),
                    onNodeActivate: _showDetails,
                    onSignalEnd: (id, reason) => setState(() {
                      _events.insert(0, '$id: ${reason.name}');
                      if (_events.length > 6) _events.removeLast();
                    }),
                  ),
                  SizedBox(height: tokens.spaceLayoutGutter),
                  KSurface(
                    radius: KSurfaceRadius.card,
                    child: Padding(
                      padding: EdgeInsets.all(tokens.spaceCardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          KText(
                            widget.communication
                                ? 'Communication'
                                : 'Team projects',
                            variant: KTextVariant.heading3,
                          ),
                          SizedBox(height: tokens.spaceControlGap),
                          const KText(
                            'Consumer-owned filters, selection, camera and transient events.',
                            variant: KTextVariant.bodySmall,
                          ),
                          SizedBox(height: tokens.spaceContentActionGap),
                          Row(
                            children: [
                              KSwitch(
                                label: 'Show active project only',
                                value: _activeOnly,
                                onChanged: (value) =>
                                    setState(() => _activeOnly = value),
                              ),
                              SizedBox(width: tokens.spaceControlGap),
                              const Expanded(
                                child: Text('Show active project only'),
                              ),
                            ],
                          ),
                          SizedBox(height: tokens.spaceContentActionGap),
                          Wrap(
                            spacing: tokens.spaceControlGap,
                            runSpacing: tokens.spaceControlGap,
                            children: [
                              KButton(
                                label: 'Trigger event',
                                onPressed: () => _trigger('agent-human'),
                              ),
                              KButton(
                                label: _answered
                                    ? 'Reset question'
                                    : 'Answer question',
                                variant: KButtonVariant.secondary,
                                onPressed: () => setState(() {
                                  _answered = !_answered;
                                  _events.insert(
                                    0,
                                    _answered
                                        ? 'Question answered'
                                        : 'Question reset',
                                  );
                                }),
                              ),
                            ],
                          ),
                          if (widget.communication) ...[
                            SizedBox(height: tokens.spaceContentActionGap),
                            DropdownButton<KOrbitSignalStyle>(
                              value: _signalStyle,
                              items: [
                                for (final style in KOrbitSignalStyle.values)
                                  DropdownMenuItem(
                                    value: style,
                                    child: Text(style.name),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _signalStyle = value!),
                            ),
                            KSlider(
                              label: 'Signal duration',
                              value: _duration,
                              min: 400,
                              max: 2400,
                              divisions: 10,
                              valueLabel: (value) =>
                                  '${value.round()} milliseconds',
                              onChanged: (value) =>
                                  setState(() => _duration = value),
                            ),
                            KButton(
                              label: 'Burst',
                              variant: KButtonVariant.secondary,
                              onPressed: () {
                                for (final connection in _connections.take(5)) {
                                  _trigger(connection.id);
                                }
                              },
                            ),
                          ],
                          SizedBox(height: tokens.spaceContentActionGap),
                          const KText(
                            'Event log',
                            variant: KTextVariant.heading4,
                          ),
                          for (final event in _events.take(6))
                            KText(event, variant: KTextVariant.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
