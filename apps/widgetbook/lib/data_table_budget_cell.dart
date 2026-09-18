import 'package:flutter/material.dart';
import 'package:k_design_ui/k_design_ui.dart';

class BudgetCell extends StatefulWidget {
  const BudgetCell({
    required this.id,
    required this.value,
    required this.onCommit,
    this.enabled = true,
    super.key,
  });
  final String id;
  final int value;
  final ValueChanged<int> onCommit;
  final bool enabled;
  @override
  State<BudgetCell> createState() => _BudgetCellState();
}

class _BudgetCellState extends State<BudgetCell> {
  bool _editing = false;
  final _focus = FocusNode();
  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && mounted && _editing) {
        setState(() => _editing = false);
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KEditableCell(
    label: 'Edit budget for ${widget.id}',
    editing: _editing,
    paddingInline: 4,
    onEdit: widget.enabled ? () => setState(() => _editing = true) : null,
    display: Text(
      formatCurrencyMinorUnits(
        widget.value,
        currency: 'EUR',
        locale: 'de-DE',
        fractionDigits: 0,
      ),
    ),
    editor: KCurrencyInput(
      label: 'Budget for ${widget.id}',
      value: widget.value,
      currency: 'EUR',
      locale: 'de-DE',
      fractionDigits: 0,
      enabled: widget.enabled,
      autofocus: true,
      focusNode: _focus,
      onCommit: (value) {
        if (value != null) widget.onCommit(value);
      },
    ),
  );
}
