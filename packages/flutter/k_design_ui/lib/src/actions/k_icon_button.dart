import 'package:flutter/material.dart';
import '../primitives/k_icon.dart';
import 'action_control.dart';

class KIconButton extends StatefulWidget {
  const KIconButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    super.key,
  });
  final String label;
  final KIconName icon;
  final VoidCallback? onPressed;
  final bool selected;
  @override
  State<KIconButton> createState() => _KIconButtonState();
}

class _KIconButtonState extends State<KIconButton> {
  final _focus = FocusNode();
  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.label,
    excludeFromSemantics: true,
    child: KActionControl(
      label: widget.label,
      icon: widget.icon,
      iconOnly: true,
      selected: widget.selected,
      focusNode: _focus,
      onPressed: widget.onPressed,
    ),
  );
}
