import 'dart:ui' show SemanticsValidationResult;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'form_style.dart';
import 'k_field.dart';

/// Plain multiline text. Enter inserts a newline; content scrolls within rows.
class KTextarea extends StatelessWidget {
  const KTextarea({
    this.controller,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.label,
    this.placeholder,
    this.enabled = true,
    this.readOnly = false,
    this.rows = 4,
    this.maxLength,
    super.key,
  }) : assert(rows > 0),
       assert(maxLength == null || maxLength > 0);

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? label;
  final String? placeholder;
  final bool enabled;
  final bool readOnly;
  final int rows;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    final field = KFieldScope.of(context);
    final style = formTextStyle(
      context,
    ).copyWith(height: t.fontBodyLineHeight / t.fontControlSize);
    return Semantics(
      label: label ?? field?.label,
      hint: field?.helperText,
      isRequired: field?.required,
      validationResult: field?.invalid == true
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: Opacity(
        opacity: enabled ? 1 : t.opacityDisabled,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          focusNode: focusNode,
          autofocus: autofocus,
          enabled: enabled,
          readOnly: readOnly,
          minLines: rows,
          maxLines: rows,
          maxLength: maxLength,
          maxLengthEnforcement:
              MaxLengthEnforcement.truncateAfterCompositionEnds,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          textAlignVertical: TextAlignVertical.top,
          style: style,
          cursorColor: t.colorBorderFocus,
          decoration: formDecoration(context, invalid: field?.invalid ?? false)
              .copyWith(
                hintText: placeholder,
                hintStyle: style.copyWith(color: t.colorTextMuted),
                hintMaxLines: rows,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: t.spaceControlInsetInline,
                  vertical: t.spaceControlGap,
                ),
              ),
        ),
      ),
    );
  }
}
