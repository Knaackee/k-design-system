import 'package:flutter/material.dart';

import '../forms/k_field.dart';
import '../forms/k_input.dart';
import '../overlays/k_adaptive_dialog.dart';
import '../primitives/k_button.dart';
import '../primitives/k_layout.dart';
import '../primitives/k_text.dart';
import 'k_editor_types.dart';

final _invalidUrlCharacters = RegExp(r'[\s\x00-\x1f\x7f<>\\]');

String? kMarkdownLinkUrl(String input) {
  final value = input.trim();
  if (value.isEmpty || _invalidUrlCharacters.hasMatch(value)) return null;
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  return switch (uri.scheme) {
    '' => value,
    'mailto' when value.length > 'mailto:'.length => value,
    'http' || 'https' when uri.host.isNotEmpty => value,
    _ => null,
  };
}

Future<String?> showKMarkdownLinkDialog(
  BuildContext context,
  KEditorLabels labels,
) => KAdaptiveDialog.show<String>(
  context: context,
  useRootNavigator: false,
  builder: (context) {
    var value = '';
    var invalid = false;
    return StatefulBuilder(
      builder: (context, setState) {
        void submit(String input) {
          final url = kMarkdownLinkUrl(input);
          if (url == null) {
            setState(() => invalid = true);
          } else {
            Navigator.of(context).pop(url);
          }
        }

        return KAdaptiveDialog(
          title: KText(labels.linkDialogTitle, variant: KTextVariant.heading5),
          closeLabel: labels.linkClose,
          onClose: () => Navigator.of(context).pop(),
          expandBody: false,
          actions: KInline(
            gap: KLayoutGap.action,
            wrap: true,
            children: [
              KButton(
                label: labels.linkCancel,
                variant: KButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
              KButton(label: labels.linkSubmit, onPressed: () => submit(value)),
            ],
          ),
          child: KField(
            label: labels.linkUrl,
            errorText: invalid ? labels.linkInvalidUrl : null,
            child: KInput(
              autofocus: true,
              autocorrect: false,
              keyboardType: TextInputType.url,
              onChanged: (input) {
                value = input;
                if (invalid) setState(() => invalid = false);
              },
              onSubmitted: submit,
            ),
          ),
        );
      },
    );
  },
);
