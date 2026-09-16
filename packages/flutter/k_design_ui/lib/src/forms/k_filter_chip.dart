import '../localization/k_localization.dart';
import 'package:flutter/material.dart';
import '../actions/action_control.dart';
import '../primitives/k_icon.dart';

class KFilterChip extends StatefulWidget {
  const KFilterChip({
    required this.label,
    required this.onRemove,
    this.removeLabel,
    super.key,
  });
  final String label;
  final String? removeLabel;
  final VoidCallback? onRemove;
  @override
  State<KFilterChip> createState() => _KFilterChipState();
}

class _KFilterChipState extends State<KFilterChip> {
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  void _focusChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        widget.removeLabel ??
        KLocalization.of(
          context,
        ).text('remove').replaceAll('{label}', widget.label),
    excludeSemantics: true,
    button: true,
    focusable: widget.onRemove != null,
    focused: _focus.hasFocus,
    enabled: widget.onRemove != null,
    onTap: widget.onRemove,
    child: KActionControl(
      label: widget.label,
      onPressed: widget.onRemove,
      focusNode: _focus,
      icon: KIconName.x,
    ),
  );
}
