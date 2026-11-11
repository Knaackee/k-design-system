import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';

import '../basic_display.dart';
import '../forms/k_checkbox.dart';
import '../forms/k_field.dart';
import '../forms/k_input.dart';
import '../forms/k_select.dart';
import '../primitives/k_button.dart';
import '../primitives/k_card.dart';
import '../primitives/k_icon.dart';
import 'k_agent_parts.dart';
import 'k_chat_types.dart';
import 'k_chat_appearance.dart';

class KAgentTextQuestion extends StatelessWidget {
  const KAgentTextQuestion({
    required this.part,
    this.onResponse,
    this.border = KCardBorder.none,
    super.key,
  });
  final KAgentQuestionPart part;
  final KCardBorder border;
  final ValueChanged<KAgentQuestionResponse>? onResponse;
  @override
  Widget build(BuildContext context) =>
      KAgentQuestion(part: part, onResponse: onResponse, border: border);
}

class KAgentSingleChoice extends KAgentTextQuestion {
  const KAgentSingleChoice({
    required super.part,
    super.onResponse,
    super.border,
    super.key,
  });
}

class KAgentMultipleChoice extends KAgentTextQuestion {
  const KAgentMultipleChoice({
    required super.part,
    super.onResponse,
    super.border,
    super.key,
  });
}

class KAgentConfirmation extends KAgentTextQuestion {
  const KAgentConfirmation({
    required super.part,
    super.onResponse,
    super.border,
    super.key,
  });
}

class KAgentForm extends StatefulWidget {
  const KAgentForm({
    required this.part,
    this.onResponse,
    this.requiredLabel = 'Required',
    super.key,
  });
  final KAgentFormPart part;
  final ValueChanged<KAgentFormResponse>? onResponse;
  final String requiredLabel;
  @override
  State<KAgentForm> createState() => _KAgentFormState();
}

class _KAgentFormState extends State<KAgentForm> {
  late final Map<String, Object?> _values = {
    for (final field in widget.part.fields)
      field.id: field.defaultValue ?? _defaultValue(field),
  };
  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.part.fields)
      if ({
        KAgentFormFieldKind.text,
        KAgentFormFieldKind.number,
      }.contains(field.kind))
        field.id: TextEditingController(text: '${_values[field.id] ?? ''}'),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _update(String id, Object? value) => setState(() => _values[id] = value);

  @override
  Widget build(BuildContext context) {
    final part = widget.part;
    if (part.state != KAgentResolutionState.pending) {
      return _ResolvedCard(
        title: part.title,
        summary: part.responseSummary,
        state: part.state,
      );
    }
    final t = _tokens(context);
    final valid = part.fields.every(
      (field) => _validate(field, _values[field.id]),
    );
    return _AskCard(
      icon: KIconName.info,
      title: part.title,
      description: part.description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: t.componentChatBlockGap,
        children: [
          for (final field in part.fields) _field(context, field),
          Wrap(
            spacing: t.spaceControlGap,
            runSpacing: t.spaceControlGap,
            alignment: WrapAlignment.end,
            children: [
              if (part.cancelLabel case final label?)
                KButton(
                  label: label,
                  variant: KButtonVariant.secondary,
                  onPressed: () => widget.onResponse?.call(
                    KAgentFormResponse(
                      formId: part.id,
                      submit: false,
                      values: Map.unmodifiable(_values),
                    ),
                  ),
                ),
              KButton(
                label: part.submitLabel ?? 'Continue',
                onPressed: valid
                    ? () => widget.onResponse?.call(
                        KAgentFormResponse(
                          formId: part.id,
                          submit: true,
                          values: Map.unmodifiable(_values),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(BuildContext context, KAgentFormField field) {
    final helper = [
      if (field.description != null) field.description!,
      if (field.required) widget.requiredLabel,
    ].join(' · ');
    if (field.kind == KAgentFormFieldKind.boolean) {
      return KField(
        label: field.label,
        helperText: helper.isEmpty ? null : helper,
        required: field.required,
        child: KCheckbox(
          label: field.label,
          value: _values[field.id] == true,
          onChanged: (value) => _update(field.id, value),
        ),
      );
    }
    if (field.kind == KAgentFormFieldKind.singleChoice) {
      return KField(
        label: field.label,
        helperText: helper.isEmpty ? null : helper,
        required: field.required,
        child: KSelect(
          options: [
            for (final option in field.options)
              KSelectOption(value: option.id, label: option.label),
          ],
          value: _values[field.id] as String?,
          placeholder: field.placeholder,
          onChanged: (value) => _update(field.id, value),
        ),
      );
    }
    if (field.kind == KAgentFormFieldKind.multipleChoice) {
      final selected = (_values[field.id] as List?)?.cast<String>() ?? [];
      return KField(
        label: field.label,
        helperText: helper.isEmpty ? null : helper,
        required: field.required,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final option in field.options)
              KCheckbox(
                label: option.label,
                value: selected.contains(option.id),
                onChanged: (checked) => _update(
                  field.id,
                  checked == true
                      ? [...selected, option.id]
                      : selected.where((id) => id != option.id).toList(),
                ),
              ),
          ],
        ),
      );
    }
    return KField(
      label: field.label,
      helperText: helper.isEmpty ? null : helper,
      required: field.required,
      child: KInput(
        controller: _controllers[field.id],
        placeholder: field.placeholder,
        onChanged: (value) => _update(
          field.id,
          field.kind == KAgentFormFieldKind.number
              ? num.tryParse(value)
              : value,
        ),
      ),
    );
  }
}

class KAgentExternalAction extends StatelessWidget {
  const KAgentExternalAction({required this.part, this.onResponse, super.key});
  final KAgentExternalActionPart part;
  final ValueChanged<KAgentExternalActionResponse>? onResponse;
  @override
  Widget build(BuildContext context) {
    if (part.state != KAgentResolutionState.pending) {
      return _ResolvedCard(
        title: part.title,
        summary: part.responseSummary,
        state: part.state,
      );
    }
    final t = _tokens(context);
    return _AskCard(
      icon: KIconName.externalLink,
      title: part.title,
      description: part.description,
      child: Wrap(
        spacing: t.spaceControlGap,
        runSpacing: t.spaceControlGap,
        alignment: WrapAlignment.end,
        children: [
          if (part.cancelLabel case final label?)
            KButton(
              label: label,
              variant: KButtonVariant.secondary,
              onPressed: () => onResponse?.call(
                KAgentExternalActionResponse(
                  actionId: part.id,
                  open: false,
                  url: part.url,
                ),
              ),
            ),
          KButton(
            label: part.actionLabel,
            onPressed: () => onResponse?.call(
              KAgentExternalActionResponse(
                actionId: part.id,
                open: true,
                url: part.url,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KAgentAttachmentRequest extends StatelessWidget {
  const KAgentAttachmentRequest({
    required this.part,
    this.onResponse,
    super.key,
  });
  final KAgentAttachmentRequestPart part;
  final ValueChanged<KAgentAttachmentRequestResponse>? onResponse;
  @override
  Widget build(BuildContext context) {
    if (part.state != KAgentResolutionState.pending) {
      return _ResolvedCard(
        title: part.title,
        summary: part.responseSummary,
        state: part.state,
      );
    }
    final t = _tokens(context);
    return _AskCard(
      icon: KIconName.paperclip,
      title: part.title,
      description: part.description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: t.spaceControlGap,
        children: [
          for (final attachment in part.attachments)
            KAttachment(
              title: Text(attachment.title),
              description: attachment.description == null
                  ? null
                  : Text(attachment.description!),
              state: _attachmentState(attachment.state),
              progress: attachment.progress,
            ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: KButton(
              label: part.actionLabel,
              onPressed: () => onResponse?.call(
                KAgentAttachmentRequestResponse(
                  requestId: part.id,
                  select: true,
                  multiple: part.multiple,
                  accept: part.accept,
                  maxFiles: part.maxFiles,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AskCard extends StatelessWidget {
  const _AskCard({
    required this.icon,
    required this.title,
    required this.child,
    this.description,
  });
  final KIconName icon;
  final String title;
  final String? description;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = _tokens(context);
    return KChatAppearance(
      child: Container(
        padding: EdgeInsets.all(t.spaceControlInsetInline),
        decoration: BoxDecoration(
          color: t.colorSurfaceRaised,
          border: Border.all(color: t.colorBorderDefault),
          borderRadius: BorderRadius.circular(t.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: t.componentChatBlockGap,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: t.spaceControlGap,
              children: [
                KIcon(icon),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _labelStyle(t)),
                      if (description case final value?)
                        Text(value, style: _mutedStyle(t)),
                    ],
                  ),
                ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _ResolvedCard extends StatelessWidget {
  const _ResolvedCard({required this.title, required this.state, this.summary});
  final String title;
  final String? summary;
  final KAgentResolutionState state;
  @override
  Widget build(BuildContext context) => _AskCard(
    icon: KIconName.check,
    title: title,
    description: summary ?? state.name,
    child: const SizedBox.shrink(),
  );
}

Object _defaultValue(KAgentFormField field) => switch (field.kind) {
  KAgentFormFieldKind.boolean => false,
  KAgentFormFieldKind.multipleChoice => <String>[],
  _ => '',
};

bool _validate(KAgentFormField field, Object? value) {
  if (field.kind == KAgentFormFieldKind.number) {
    if (value is! num) return !field.required;
    return (field.minimum == null || value >= field.minimum!) &&
        (field.maximum == null || value <= field.maximum!);
  }
  if (field.kind == KAgentFormFieldKind.multipleChoice) {
    final count = value is List ? value.length : 0;
    return (!field.required || count > 0) &&
        (field.minItems == null || count >= field.minItems!) &&
        (field.maxItems == null || count <= field.maxItems!);
  }
  if (!field.required) return true;
  return field.kind == KAgentFormFieldKind.boolean
      ? value == true
      : '$value'.trim().isNotEmpty;
}

KAttachmentState _attachmentState(KChatAttachmentPartState state) =>
    switch (state) {
      KChatAttachmentPartState.ready => KAttachmentState.ready,
      KChatAttachmentPartState.uploading => KAttachmentState.uploading,
      KChatAttachmentPartState.processing => KAttachmentState.processing,
      KChatAttachmentPartState.error => KAttachmentState.error,
      KChatAttachmentPartState.complete => KAttachmentState.complete,
    };

KDesignTokens _tokens(BuildContext context) =>
    Theme.of(context).extension<KDesignTokens>()!;
TextStyle _labelStyle(KDesignTokens t) => TextStyle(
  color: t.colorTextPrimary,
  fontFamily: t.fontFamily,
  fontSize: t.fontLabelSize,
  fontWeight: t.fontLabelWeight,
);
TextStyle _mutedStyle(KDesignTokens t) => TextStyle(
  color: t.colorTextMuted,
  fontFamily: t.fontFamily,
  fontSize: t.fontCaptionSize,
  height: t.fontCaptionLineHeight / t.fontCaptionSize,
);
