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
  late List<String> recent = widget.emoji
      ? ['1f600', '1f603', '1f604', '1f601']
      : ['heart', 'star', 'search', 'clock'];
  void select(KSymbolItem item) => setState(() {
    selected = item.id;
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
      children: [picker()],
    ),
  );
}
