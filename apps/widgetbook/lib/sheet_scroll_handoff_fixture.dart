import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class SheetScrollHandoffFixture extends StatelessWidget {
  const SheetScrollHandoffFixture({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: KButton(
      label: 'Open scrollable sheet',
      onPressed: () => KAdaptiveDialog.show<void>(
        context: context,
        builder: (route) => _SettingsSheet(route: route),
      ),
    ),
  );
}

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet({required this.route});
  final BuildContext route;
  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  final Set<int> selected = {};
  @override
  Widget build(BuildContext context) => KAdaptiveDialog(
    title: const Text('Settings'),
    description: const Text(
      'Scroll the settings, then pull down without lifting your finger. The sheet takes over at the top.',
    ),
    onClose: () => Navigator.pop(widget.route),
    actions: KButton(
      label: 'Done',
      onPressed: () => Navigator.pop(widget.route),
    ),
    child: KStack(
      gap: KLayoutGap.section,
      children: [
        for (var i = 0; i < 24; i++)
          KSwitch(
            label: 'Setting ${i + 1}',
            value: selected.contains(i),
            onChanged: (value) => setState(() {
              if (value) {
                selected.add(i);
              } else {
                selected.remove(i);
              }
            }),
          ),
      ],
    ),
  );
}
