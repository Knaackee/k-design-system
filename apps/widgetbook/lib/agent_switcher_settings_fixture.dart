import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class AgentSwitcherSettingsFixture extends StatefulWidget {
  const AgentSwitcherSettingsFixture({super.key});
  @override
  State<AgentSwitcherSettingsFixture> createState() => _SettingsState();
}

class _SettingsState extends State<AgentSwitcherSettingsFixture> {
  static const agents = {'ada': 'Ada', 'linus': 'Linus', 'mira': 'Mira'};
  List<String> pins = ['ada', 'linus'];
  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 480,
      child: KAgentSwitcher(
        settings: true,
        selectedId: null,
        onSelect: (_) {},
        items: [
          for (final id in [
            ...pins,
            ...agents.keys.where((id) => !pins.contains(id)),
          ])
            KAgentSwitcherItem(
              id: id,
              name: agents[id]!,
              avatar: Text({'ada': '🧭', 'linus': '🌙', 'mira': '✨'}[id]!),
              reorderable: pins.contains(id),
              controlContent: KSwitch(
                label: 'Pin ${agents[id]}',
                showLabel: false,
                value: pins.contains(id),
                onChanged: (enabled) => setState(
                  () => pins = enabled
                      ? [...pins, id]
                      : pins.where((pin) => pin != id).toList(),
                ),
              ),
            ),
        ],
        onReorder: (ids) =>
            setState(() => pins = ids.where(pins.contains).toList()),
      ),
    ),
  );
}
