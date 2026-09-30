import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

enum OrbitDemoFilter { all, active, questions }

class OrbitDemoPanel extends StatelessWidget {
  const OrbitDemoPanel({
    required this.communication,
    required this.deep,
    required this.nodes,
    required this.allNodes,
    required this.selectedNode,
    required this.pinnedNodeId,
    required this.filter,
    required this.labelVisibility,
    required this.showAdded,
    required this.signalStyle,
    required this.duration,
    required this.minZoom,
    required this.maxZoom,
    required this.maxAngularSpeed,
    required this.events,
    required this.onSelected,
    required this.onProgress,
    required this.onRadius,
    required this.onPeriod,
    required this.onPulse,
    required this.onBadge,
    required this.onPinned,
    required this.onFilter,
    required this.onLabelVisibility,
    required this.onShowAdded,
    required this.onOpenDetails,
    required this.onStatus,
    required this.onPingSelected,
    required this.onTrigger,
    required this.onSignalStyle,
    required this.onDuration,
    required this.onBurst,
    required this.onMinZoom,
    required this.onMaxZoom,
    required this.onMaxAngularSpeed,
    super.key,
  });

  final bool communication, deep, showAdded;
  final List<KOrbitNode> nodes, allNodes;
  final KOrbitNode? selectedNode;
  final String? pinnedNodeId;
  final OrbitDemoFilter filter;
  final KOrbitLabelVisibility labelVisibility;
  final KOrbitSignalStyle signalStyle;
  final double duration, minZoom, maxZoom, maxAngularSpeed;
  final List<String> events;
  final ValueChanged<String?> onSelected, onPinned;
  final ValueChanged<double> onProgress, onRadius, onPeriod;
  final VoidCallback onPulse, onBadge, onShowAdded, onOpenDetails;
  final VoidCallback onPingSelected, onTrigger, onBurst;
  final ValueChanged<OrbitDemoFilter> onFilter;
  final ValueChanged<KOrbitLabelVisibility> onLabelVisibility;
  final ValueChanged<KOrbitStatus> onStatus;
  final ValueChanged<KOrbitSignalStyle> onSignalStyle;
  final ValueChanged<double> onDuration, onMinZoom, onMaxZoom;
  final ValueChanged<double> onMaxAngularSpeed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final selected = selectedNode;
    return KSurface(
      radius: KSurfaceRadius.card,
      child: ListView(
        padding: EdgeInsets.all(t.spaceCardPadding),
        children: [
          KText(
            deep
                ? 'Deep hierarchy'
                : communication
                ? 'Communication'
                : 'Team command center',
            variant: KTextVariant.heading3,
          ),
          _gap(t),
          KText(
            deep
                ? 'Team → issues → agents → subtasks → signals.'
                : 'Team → issues → agents. Filtered results keep their ancestor path.',
            variant: KTextVariant.bodySmall,
          ),
          _gap(t),
          KSelect(
            label: 'Configure node',
            placeholder: 'Choose a node…',
            clearable: true,
            value: selected?.id,
            options: [
              for (final node in nodes)
                KSelectOption(value: node.id, label: node.label),
            ],
            onChanged: onSelected,
          ),
          if (selected != null) ...[
            _gap(t),
            KText(
              'Progress: ${(selected.progress ?? 0).round()}%',
              variant: KTextVariant.bodySmall,
            ),
            KSlider(
              label: 'Node progress',
              min: 0,
              max: 100,
              divisions: 100,
              value: selected.progress ?? 0,
              valueLabel: (value) => '${value.round()}%',
              onChanged: onProgress,
            ),
            KText(
              'Radius: ${(selected.radius ?? 10).round()} world units',
              variant: KTextVariant.bodySmall,
            ),
            KSlider(
              label: 'Selected node radius',
              min: 2,
              max: 80,
              divisions: 78,
              value: selected.radius ?? 10,
              valueLabel: (value) => '${value.round()} world units',
              onChanged: onRadius,
            ),
            if (selected.levelId != null) ...[
              KText(
                'Orbit duration: ${(selected.periodSeconds ?? _levelPeriod(selected)).round()} seconds',
                variant: KTextVariant.bodySmall,
              ),
              KSlider(
                label: 'Selected node orbit duration',
                min: 10,
                max: 180,
                divisions: 34,
                value: selected.periodSeconds ?? _levelPeriod(selected),
                valueLabel: (value) => '${value.round()}s',
                onChanged: onPeriod,
              ),
            ],
            _actions(t, [
              KButton(
                label: 'Toggle pulse',
                variant: KButtonVariant.secondary,
                onPressed: onPulse,
              ),
              KButton(
                label: 'Toggle custom badge',
                variant: KButtonVariant.secondary,
                onPressed: onBadge,
              ),
            ]),
          ],
          if (pinnedNodeId != null) ...[
            _gap(t),
            KButton(
              label:
                  'Stop following: ${allNodes.where((node) => node.id == pinnedNodeId).firstOrNull?.label ?? pinnedNodeId}',
              variant: KButtonVariant.secondary,
              onPressed: () => onPinned(null),
            ),
          ],
          _gap(t),
          _actions(t, [
            for (final value in OrbitDemoFilter.values)
              KButton(
                label: switch (value) {
                  OrbitDemoFilter.all => 'All',
                  OrbitDemoFilter.active => 'Active',
                  OrbitDemoFilter.questions => 'Questions',
                },
                variant: filter == value
                    ? KButtonVariant.primary
                    : KButtonVariant.secondary,
                onPressed: () => onFilter(value),
              ),
          ]),
          _gap(t),
          _actions(t, [
            for (final value in KOrbitLabelVisibility.values)
              KButton(
                label: 'Labels: ${value.name}',
                variant: labelVisibility == value
                    ? KButtonVariant.primary
                    : KButtonVariant.secondary,
                onPressed: () => onLabelVisibility(value),
              ),
          ]),
          _gap(t),
          _actions(t, [
            KButton(
              label: showAdded ? 'Remove issue + agent' : 'Add issue + agent',
              onPressed: onShowAdded,
            ),
            KButton(
              label: 'Open details',
              variant: KButtonVariant.secondary,
              onPressed: selected == null ? null : onOpenDetails,
            ),
          ]),
          _gap(t),
          _actions(t, [
            KButton(
              label: 'Toggle question',
              variant: KButtonVariant.secondary,
              onPressed: selected == null
                  ? null
                  : () => onStatus(KOrbitStatus.question),
            ),
            KButton(
              label: 'Toggle active',
              variant: KButtonVariant.secondary,
              onPressed: selected == null
                  ? null
                  : () => onStatus(KOrbitStatus.active),
            ),
            KButton(
              label: 'Ping selected',
              variant: KButtonVariant.secondary,
              onPressed: selected == null ? null : onPingSelected,
            ),
          ]),
          _gap(t),
          KButton(label: 'Trigger event', onPressed: onTrigger),
          if (communication) ...[
            _gap(t),
            KSelect(
              label: 'Signal style',
              value: signalStyle.name,
              options: const [
                KSelectOption(value: 'point', label: 'Travelling point'),
                KSelectOption(value: 'trail', label: 'Travelling trail'),
                KSelectOption(
                  value: 'endpointPingsOnly',
                  label: 'Endpoint pings',
                ),
              ],
              onChanged: (value) => onSignalStyle(
                KOrbitSignalStyle.values.byName(value ?? 'trail'),
              ),
            ),
            KSlider(
              label: 'Signal duration',
              value: duration,
              min: 400,
              max: 2400,
              divisions: 10,
              valueLabel: (value) => '${value.round()} milliseconds',
              onChanged: onDuration,
            ),
            KButton(
              label: 'Burst',
              variant: KButtonVariant.secondary,
              onPressed: onBurst,
            ),
          ],
          _gap(t),
          KText(
            'Minimum zoom: ${minZoom.toStringAsFixed(2)}×',
            variant: KTextVariant.bodySmall,
          ),
          KSlider(
            label: 'Minimum zoom',
            min: .1,
            max: 1,
            divisions: 18,
            value: minZoom,
            onChanged: onMinZoom,
          ),
          KText(
            'Maximum zoom: ${maxZoom.toStringAsFixed(1)}×',
            variant: KTextVariant.bodySmall,
          ),
          KSlider(
            label: 'Maximum zoom',
            min: 1,
            max: 10,
            divisions: 90,
            value: maxZoom,
            onChanged: onMaxZoom,
          ),
          KSlider(
            label: 'Maximum angular speed',
            min: 0,
            max: 30,
            divisions: 30,
            value: maxAngularSpeed,
            valueLabel: (value) => '${value.round()}°/s',
            onChanged: onMaxAngularSpeed,
          ),
          _gap(t),
          const KText('Event log', variant: KTextVariant.heading4),
          Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final event in events)
                  KText(event, variant: KTextVariant.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _levelPeriod(KOrbitNode node) => switch (node.levelId) {
    'issues' => 90,
    'agents' => 60,
    'subtasks' => 50,
    'signals' => 45,
    _ => 60,
  };

  Widget _gap(KDesignTokens t) => SizedBox(height: t.spaceContentActionGap);

  Widget _actions(KDesignTokens t, List<Widget> children) => Wrap(
    spacing: t.spaceControlGap,
    runSpacing: t.spaceControlGap,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}
