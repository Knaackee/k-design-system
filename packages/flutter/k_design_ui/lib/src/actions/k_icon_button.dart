import 'package:flutter/material.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_button.dart';
import 'action_control.dart';

class KIconButton extends StatefulWidget {
  const KIconButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconContent,
    this.selected = false,
    this.variant = KButtonVariant.ghost,
    super.key,
  });
  final String label;
  final KIconName icon;

  /// Optional animated/custom visual; [icon] remains the static fallback.
  final Widget? iconContent;
  final VoidCallback? onPressed;
  final bool selected;
  final KButtonVariant variant;
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
      iconContent: widget.iconContent,
      iconOnly: true,
      selected: widget.selected,
      variant: widget.variant,
      focusNode: _focus,
      onPressed: widget.onPressed,
    ),
  );
}
