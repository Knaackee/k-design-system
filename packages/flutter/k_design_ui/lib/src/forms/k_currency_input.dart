import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'currency_value.dart';
import 'k_input.dart';
import 'k_field.dart';

class KCurrencyInput extends StatefulWidget {
  const KCurrencyInput({
    required this.value,
    required this.onCommit,
    required this.currency,
    required this.locale,
    this.fractionDigits = 2,
    this.onInvalidDraft,
    this.enabled = true,
    this.readOnly = false,
    this.label,
    this.placeholder,
    this.clearable = false,
    this.clearLabel,
    this.autofocus = false,
    this.focusNode,
    super.key,
  });
  final int? value;
  final ValueChanged<int?> onCommit;
  final ValueChanged<String>? onInvalidDraft;
  final String currency;
  final String locale;
  final int fractionDigits;
  final bool enabled;
  final bool readOnly;
  final String? label;
  final String? placeholder;
  final bool clearable;
  final String? clearLabel;
  final bool autofocus;
  final FocusNode? focusNode;
  @override
  State<KCurrencyInput> createState() => _KCurrencyInputState();
}

class _KCurrencyInputState extends State<KCurrencyInput> {
  late final TextEditingController _controller;
  late FocusNode _focus;
  bool _invalid = false;
  String _format({bool? display}) => formatCurrencyMinorUnits(
    widget.value,
    currency: widget.currency,
    locale: widget.locale,
    fractionDigits: widget.fractionDigits,
    currencyDisplay: display ?? !_focus.hasFocus,
  );
  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _focus.addListener(_focusChanged);
    _controller = TextEditingController(text: _format());
  }

  void _focusChanged() {
    if (_focus.hasFocus) {
      if (!_invalid) _controller.text = _format(display: false);
    } else if (_commit()) {
      _controller.text = _format(display: true);
    }
  }

  bool _commit() {
    if (!widget.enabled || widget.readOnly) return true;
    final result = parseCurrencyMinorUnits(
      _controller.text,
      currency: widget.currency,
      locale: widget.locale,
      fractionDigits: widget.fractionDigits,
    );
    setState(() => _invalid = !result.valid);
    if (!result.valid) {
      widget.onInvalidDraft?.call(_controller.text);
      return false;
    }
    widget.onCommit(result.value);
    return true;
  }

  @override
  void didUpdateWidget(KCurrencyInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focus.removeListener(_focusChanged);
      if (oldWidget.focusNode == null) _focus.dispose();
      _focus = widget.focusNode ?? FocusNode();
      _focus.addListener(_focusChanged);
    }
    if (oldWidget.value != widget.value ||
        oldWidget.currency != widget.currency ||
        oldWidget.locale != widget.locale ||
        oldWidget.fractionDigits != widget.fractionDigits) {
      _controller.text = _format();
      _invalid = false;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    if (widget.focusNode == null) _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () {
        _controller.text = _format();
        setState(() => _invalid = false);
      },
    },
    child: KFieldScope(
      label: widget.label ?? KFieldScope.of(context)?.label ?? '',
      helperText: KFieldScope.of(context)?.helperText,
      invalid: _invalid || (KFieldScope.of(context)?.invalid ?? false),
      required: KFieldScope.of(context)?.required ?? false,
      child: KInput(
        controller: _controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        label: widget.label,
        placeholder: widget.placeholder,
        clearable: widget.clearable,
        clearLabel: widget.clearLabel,
        onSubmitted: (_) => _commit(),
        onChanged: (text) {
          setState(() => _invalid = false);
          if (text.isEmpty && widget.clearable) widget.onCommit(null);
        },
      ),
    ),
  );
}
