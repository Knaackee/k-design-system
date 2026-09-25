import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';

class RadioFixture extends StatefulWidget {
  const RadioFixture({super.key});
  @override
  State<RadioFixture> createState() => _RadioFixtureState();
}

class _RadioFixtureState extends State<RadioFixture> {
  String? _value = 'all';
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return Padding(
      padding: EdgeInsets.all(t.spaceCardPadding),
      child: KRadioGroup<String>(
        label: 'Notifications',
        value: _value,
        onChanged: (value) => setState(() => _value = value),
        items: const [
          KRadioOption(value: 'all', label: 'All updates'),
          KRadioOption(value: 'important', label: 'Important updates only'),
          KRadioOption(value: 'none', label: 'No updates'),
          KRadioOption(
            value: 'managed',
            label: 'Managed by administrator',
            disabled: true,
          ),
        ],
      ),
    );
  }
}
