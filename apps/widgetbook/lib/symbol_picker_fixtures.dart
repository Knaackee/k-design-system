import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class SymbolPickerFixture extends StatefulWidget {
  const SymbolPickerFixture({this.emoji = false, super.key});
  final bool emoji;
  @override
  State<SymbolPickerFixture> createState() => _SymbolPickerFixtureState();
}

class _SymbolPickerFixtureState extends State<SymbolPickerFixture> {
  String? selected;
  String label = '';
  List<String> recent = [];
  void select(KSymbolItem item) => setState(() {
    selected = item.id;
    label = item.label;
    recent = [
      item.id,
      ...recent.where((id) => id != item.id),
    ].take(24).toList();
  });
  Widget picker({
    VoidCallback? onDismiss,
    ValueChanged<KSymbolItem>? onSelect,
  }) => widget.emoji
      ? KEmojiPicker(
          value: selected,
          recentIds: recent,
          onSelect: onSelect ?? select,
          onDismiss: onDismiss,
        )
      : KIconPicker(
          value: selected,
          recentIds: recent,
          onSelect: onSelect ?? select,
          onDismiss: onDismiss,
        );
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        picker(),
        const SizedBox(height: 16),
        KText(
          label.isEmpty ? 'Choose a reaction or an icon' : 'Selected: $label',
          variant: KTextVariant.bodySmall,
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}
