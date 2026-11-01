import 'package:flutter/material.dart';
import 'form_style.dart';

class KField extends StatelessWidget {
  const KField({
    required this.label,
    required this.child,
    this.helperText,
    this.errorText,
    this.required = false,
    super.key,
  });
  final String label;
  final String? helperText;
  final String? errorText;
  final bool required;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = formTokens(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: t.spaceControlGap,
      children: [
        ExcludeSemantics(
          child: _FieldText(
            '$label${required ? ' *' : ''}',
            color: t.colorTextPrimary,
          ),
        ),
        KFieldScope(
          label: label,
          helperText: errorText ?? helperText,
          invalid: errorText != null,
          required: required,
          child: child,
        ),
        if (errorText ?? helperText case final String description)
          Semantics(
            liveRegion: errorText != null,
            child: _FieldText(
              description,
              multiline: true,
              color: errorText != null
                  ? t.colorStatusErrorForeground
                  : t.colorTextMuted,
            ),
          ),
      ],
    );
  }
}

class KFieldScope extends InheritedWidget {
  const KFieldScope({
    required this.label,
    required this.invalid,
    required this.required,
    required super.child,
    this.helperText,
    super.key,
  });
  final String label;
  final String? helperText;
  final bool invalid;
  final bool required;
  static KFieldScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KFieldScope>();
  @override
  bool updateShouldNotify(KFieldScope oldWidget) =>
      label != oldWidget.label ||
      helperText != oldWidget.helperText ||
      invalid != oldWidget.invalid ||
      required != oldWidget.required;
}

/// Match the shared CSS pixel-grid line height, including wrapped helper text.
class _FieldText extends StatelessWidget {
  const _FieldText(this.text, {required this.color, this.multiline = false});
  final String text;
  final Color color;
  final bool multiline;
  @override
  Widget build(BuildContext context) {
    final style = formTextStyle(context, color: color);
    final scaled = MediaQuery.textScalerOf(context).scale(style.fontSize!);
    return Text(
      text,
      style: style.copyWith(
        height: multiline
            ? formTokens(context).fontRelaxedHeight
            : scaled.round() / scaled,
      ),
    );
  }
}
