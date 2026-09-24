import '../localization/k_localization.dart';
import 'dart:ui' show SemanticsValidationResult;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../primitives/k_icon.dart';
import 'form_style.dart';
import 'k_field.dart';
import 'form_clear.dart';

class KInput extends StatefulWidget {
  const KInput({
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.placeholder,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.label,
    this.clearable = false,
    this.clearLabel,
    super.key,
  });
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final String? placeholder;
  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;
  final String? label;
  final bool clearable;
  final String? clearLabel;
  Widget? prefix(BuildContext context) => null;
  @override
  State<KInput> createState() => _KInputState();
}

class _KInputState extends State<KInput> {
  late TextEditingController _controller;
  late FocusNode _focus;
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focus = widget.focusNode ?? FocusNode();
    _controller.addListener(_changed);
  }

  void _changed() => setState(() {});
  @override
  void didUpdateWidget(covariant KInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final value = _controller.value;
      _controller.removeListener(_changed);
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ?? TextEditingController.fromValue(value);
      _controller.addListener(_changed);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) _focus.dispose();
      _focus = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    final field = KFieldScope.of(context);
    final canClear =
        widget.clearable &&
        widget.enabled &&
        !widget.readOnly &&
        _controller.text.isNotEmpty;
    final appearance = formDecoration(
      context,
      placeholder: widget.placeholder,
      invalid: field?.invalid ?? false,
      prefix: widget.prefix(context),
      suffix: canClear
          ? SizedBox(
              width:
                  math.max(t.sizeIconDefault, t.sizeHitTarget) +
                  t.spaceControlGap -
                  t.spaceBadgeOffset,
              height: t.sizeContent,
            )
          : null,
    );
    return KFormClearOverlay(
      label: widget.clearLabel ?? KLocalization.of(context).text('clear'),
      onPressed: canClear
          ? () {
              _controller.clear();
              widget.onChanged?.call('');
              restoreFormFocus(_focus, () => mounted);
            }
          : null,
      child: Semantics(
        label: widget.label ?? field?.label,
        hint: field?.helperText,
        isRequired: field?.required,
        validationResult: field?.invalid == true
            ? SemanticsValidationResult.invalid
            : SemanticsValidationResult.none,
        child: Opacity(
          opacity: widget.enabled ? 1 : .48,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(t.sizeControl, t.sizeHitTarget),
            ),
            child: Center(
              heightFactor: 1,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                readOnly: widget.readOnly,
                textAlignVertical: formInputAlignment(appearance),
                style: formTextStyle(context),
                cursorColor: t.colorBorderFocus,
                decoration: appearance,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class KSearchField extends KInput {
  const KSearchField({
    super.controller,
    super.onChanged,
    super.placeholder,
    super.enabled,
    super.readOnly,
    super.focusNode,
    super.label,
    super.clearable,
    super.clearLabel,
    super.key,
  });
  @override
  Widget prefix(BuildContext context) {
    final t = formTokens(context);
    return Padding(
      padding: EdgeInsets.only(
        left: t.spaceControlInsetInline + 1,
        right: t.spaceControlGap - 4,
      ),
      child: KIcon(KIconName.search, color: t.colorTextMuted),
    );
  }
}
