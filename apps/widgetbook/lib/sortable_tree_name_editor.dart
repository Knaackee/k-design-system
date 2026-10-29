import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class SortableTreeNameEditor extends StatefulWidget {
  const SortableTreeNameEditor({
    required this.name,
    required this.fresh,
    super.key,
  });
  final String name;
  final bool fresh;
  @override
  State<SortableTreeNameEditor> createState() => _NameEditorState();
}

class _NameEditorState extends State<SortableTreeNameEditor> {
  late final controller = TextEditingController(text: widget.name);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KDialog(
    title: KText(widget.fresh ? 'Eintrag hinzufügen' : 'Eintrag bearbeiten'),
    onClose: () => Navigator.of(context).pop(),
    actions: KInline(
      gap: KLayoutGap.action,
      children: [
        KButton(
          label: 'Abbrechen',
          variant: KButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        KButton(
          label: 'Übernehmen',
          onPressed:
              controller.text.trim().isEmpty || controller.text.length > 160
              ? null
              : () => Navigator.of(context).pop(controller.text.trim()),
        ),
      ],
    ),
    child: KField(
      label: 'Name',
      errorText: controller.text.length > 160
          ? 'Bitte höchstens 160 Zeichen verwenden.'
          : null,
      child: KInput(
        controller: controller,
        autofocus: true,
        onChanged: (_) => setState(() {}),
      ),
    ),
  );
}
