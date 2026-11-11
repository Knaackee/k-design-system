import 'dictation_anchor.dart';
import 'k_dictation_action.dart';
import 'dart:math' as math;
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
    this.autocorrect = true,
    this.enableIMEPersonalizedLearning = true,
    this.rows = 4,
    this.maxLength,
    this.trailingAction,
    this.dictationState,
    this.dictationOffset,
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

  /// Disable text correction and suggestions for literal values such as keys.
  final bool autocorrect;

  /// Whether the input method may learn from text entered in this field.
  final bool enableIMEPersonalizedLearning;
  final int rows;
  final int? maxLength;

  /// A bottom end action, hidden for disabled or read-only text.
  final Widget? trailingAction;
  final KDictationState? dictationState;

  /// Saved UTF-16 insertion offset; defaults to the current caret.
  final int? dictationOffset;

  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    final field = KFieldScope.of(context);
    final style = formTextStyle(
      context,
    ).copyWith(height: t.fontBodyLineHeight / t.fontControlSize);
    final action = enabled && !readOnly ? trailingAction : null;
    return KDictationFieldOverlay(
      controller: controller,
      state: enabled && !readOnly ? dictationState : null,
      offset: dictationOffset,
      child: Stack(
        children: [
          Semantics(
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
                autocorrect: autocorrect,
                enableSuggestions: autocorrect,
                smartDashesType: autocorrect
                    ? SmartDashesType.enabled
                    : SmartDashesType.disabled,
                smartQuotesType: autocorrect
                    ? SmartQuotesType.enabled
                    : SmartQuotesType.disabled,
                enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
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
                decoration:
                    formDecoration(
                      context,
                      invalid: field?.invalid ?? false,
                    ).copyWith(
                      hintText: placeholder,
                      hintStyle: style.copyWith(color: t.colorTextMuted),
                      hintMaxLines: rows,
                      counterText: '',
                      contentPadding: EdgeInsets.fromLTRB(
                        t.spaceControlInsetInline,
                        t.spaceControlGap,
                        t.spaceControlInsetInline,
                        t.spaceControlGap +
                            (action != null
                                ? math.max(t.sizeControl, t.sizeHitTarget)
                                : 0),
                      ),
                    ),
              ),
            ),
          ),
          if (action != null)
            Positioned(
              right: t.borderWidthDefault,
              bottom: t.borderWidthDefault,
              child: TextFieldTapRegion(child: action),
            ),
        ],
      ),
    );
  }
}
