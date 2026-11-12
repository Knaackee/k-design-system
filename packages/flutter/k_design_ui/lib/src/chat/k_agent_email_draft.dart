import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import '../actions/k_icon_button.dart';
import '../basic_display.dart';
import '../basic_feedback.dart';
import '../editors/k_markdown_editor.dart';
import '../editors/k_editor_types.dart';
import '../forms/k_dictation_action.dart';
import '../forms/k_field.dart';
import '../forms/k_input.dart';
import '../primitives/k_button.dart';
import '../primitives/k_card.dart';
import '../primitives/k_icon.dart';
import '../primitives/k_layout.dart';
import '../primitives/k_separator.dart';
import '../primitives/k_text.dart';
import 'k_agent_email_draft_types.dart';
import 'k_agent_email_draft_layout.dart';
export 'k_agent_email_draft_types.dart';

/// Controlled approval surface; attachment selection and sending belong to the host.
class KAgentEmailDraft extends StatelessWidget {
  const KAgentEmailDraft({
    required this.draftId,
    required this.title,
    required this.from,
    required this.value,
    required this.onChanged,
    required this.onSend,
    required this.onDiscard,
    this.attachments = const [],
    this.onAddAttachment,
    this.onRemoveAttachment,
    this.status = KAgentEmailDraftStatus.pending,
    this.statusLabel,
    this.error,
    this.errors = const {},
    this.sendDisabled = false,
    this.disabled = false,
    this.labels = const KAgentEmailDraftLabels(),
    this.border = KCardBorder.none,
    this.showFormatBar = false,
    this.showExpandButton = false,
    this.dictationState,
    this.dictationAudioLevel,
    this.onDictationPressed,
    this.editorKey,
    this.subjectController,
    this.subjectDictationState,
    this.subjectDictationAudioLevel,
    this.subjectDictationOffset,
    this.subjectDictationLabel = 'Dictate subject',
    this.onSubjectDictationPressed,
    super.key,
  });
  final String draftId, title, from;
  final KAgentEmailDraftValue value;
  final ValueChanged<KAgentEmailDraftValue> onChanged;
  final VoidCallback onSend, onDiscard;
  final List<KAgentEmailDraftAttachment> attachments;
  final VoidCallback? onAddAttachment;
  final ValueChanged<String>? onRemoveAttachment;
  final KAgentEmailDraftStatus status;
  final String? statusLabel, error;
  final Map<KAgentEmailDraftField, String> errors;
  final bool sendDisabled, disabled, showFormatBar, showExpandButton;
  final KAgentEmailDraftLabels labels;
  final KCardBorder border;
  final KDictationState? dictationState;
  final double? dictationAudioLevel;
  final VoidCallback? onDictationPressed;

  /// Optional host controller for cursor-aware Subject transcription and selection.
  final TextEditingController? subjectController;
  final KDictationState? subjectDictationState;
  final double? subjectDictationAudioLevel;
  final int? subjectDictationOffset;
  final String subjectDictationLabel;
  final VoidCallback? onSubjectDictationPressed;

  /// Host access to the existing editor's cursor-aware insertion and undo API.
  final GlobalKey<KMarkdownEditorState>? editorKey;
  @override
  Widget build(BuildContext context) =>
      _EmailDraftSession(key: ValueKey(draftId), draft: this);
}

class _EmailDraftSession extends StatefulWidget {
  const _EmailDraftSession({required this.draft, super.key});
  final KAgentEmailDraft draft;
  @override
  State<_EmailDraftSession> createState() => _EmailDraftSessionState();
}

class _EmailDraftSessionState extends State<_EmailDraftSession> {
  final controllers = <KAgentEmailDraftField, TextEditingController>{};
  late final TextEditingController account;
  bool showBcc = false;
  KAgentEmailDraft get d => widget.draft;
  bool get locked => d.disabled || d.status != KAgentEmailDraftStatus.pending;
  Map<KAgentEmailDraftField, String> get values => {
    KAgentEmailDraftField.to: d.value.to,
    KAgentEmailDraftField.cc: d.value.cc,
    KAgentEmailDraftField.bcc: d.value.bcc,
    KAgentEmailDraftField.subject: d.value.subject,
  };
  @override
  void initState() {
    super.initState();
    for (final entry in values.entries) {
      controllers[entry.key] =
          entry.key == KAgentEmailDraftField.subject &&
              d.subjectController != null
          ? d.subjectController!
          : TextEditingController(text: entry.value);
    }
    final subject = controllers[KAgentEmailDraftField.subject]!;
    if (subject.text != d.value.subject) subject.text = d.value.subject;
    account = TextEditingController(text: d.from);
  }

  @override
  void didUpdateWidget(covariant _EmailDraftSession oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.subjectController != d.subjectController) {
      if (oldWidget.draft.subjectController == null) {
        controllers[KAgentEmailDraftField.subject]!.dispose();
      }
      controllers[KAgentEmailDraftField.subject] =
          d.subjectController ?? TextEditingController(text: d.value.subject);
    }
    for (final entry in values.entries) {
      if (controllers[entry.key]!.text != entry.value) {
        controllers[entry.key]!.text = entry.value;
      }
    }
    if (account.text != d.from) account.text = d.from;
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      if (controller != d.subjectController) controller.dispose();
    }
    account.dispose();
    super.dispose();
  }

  void change(KAgentEmailDraftField field, String text) =>
      d.onChanged(switch (field) {
        KAgentEmailDraftField.to => d.value.copyWith(to: text),
        KAgentEmailDraftField.cc => d.value.copyWith(cc: text),
        KAgentEmailDraftField.bcc => d.value.copyWith(bcc: text),
        KAgentEmailDraftField.subject => d.value.copyWith(subject: text),
        KAgentEmailDraftField.markdown => d.value.copyWith(markdown: text),
      });
  Widget field(
    KAgentEmailDraftField field,
    String label, {
    bool heading = false,
  }) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    final error = d.errors[field];
    final input = KFieldScope(
      label: label,
      invalid: error != null,
      required: false,
      helperText: error,
      child: KInput(
        controller: controllers[field],
        label: label,
        dictationState: heading ? d.subjectDictationState : null,
        dictationOffset: heading ? d.subjectDictationOffset : null,
        trailingAction: heading && d.subjectDictationState != null
            ? KDictationAction(
                state: d.subjectDictationState!,
                label: d.subjectDictationLabel,
                audioLevel: d.subjectDictationAudioLevel,
                onPressed: d.onSubjectDictationPressed,
              )
            : null,
        keyboardType: heading ? null : TextInputType.emailAddress,
        autocorrect: heading,
        appearance: heading
            ? KInputAppearance.inlineHeading
            : KInputAppearance.inline,
        placeholder: heading ? label : d.labels.recipientPlaceholder,
        enabled: !locked,
        onChanged: (text) => change(field, text),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading)
          input
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: t.spaceControlGap,
            children: [
              KText(
                label,
                style: TextStyle(
                  color: t.colorTextMuted,
                  fontSize: t.fontControlSize,
                  fontWeight: t.fontBodyWeight,
                ),
              ),
              Expanded(child: input),
            ],
          ),
        if (error != null)
          Semantics(
            liveRegion: true,
            child: KText(
              error,
              variant: KTextVariant.caption,
              style: TextStyle(color: t.colorStatusErrorForeground),
            ),
          ),
        if (!heading) const KSeparator(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KCard(
      border: d.status == KAgentEmailDraftStatus.pending
          ? d.border
          : KCardBorder.none,
      child: KStack(
        align: KLayoutAlign.stretch,
        gap: KLayoutGap.action,
        children: [
          KInline(children: [const KIcon(KIconName.mail), KText(d.title)]),
          field(KAgentEmailDraftField.subject, d.labels.subject, heading: true),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: t.spaceControlGap,
                children: [
                  KText(
                    d.labels.from,
                    style: TextStyle(
                      color: t.colorTextMuted,
                      fontSize: t.fontControlSize,
                      fontWeight: t.fontBodyWeight,
                    ),
                  ),
                  Expanded(
                    child: KInput(
                      controller: account,
                      readOnly: true,
                      label: d.labels.from,
                      appearance: KInputAppearance.inline,
                    ),
                  ),
                ],
              ),
              const KSeparator(),
              field(KAgentEmailDraftField.to, d.labels.to),
              field(KAgentEmailDraftField.cc, d.labels.cc),
              if (showBcc ||
                  d.value.bcc.isNotEmpty ||
                  d.errors.containsKey(KAgentEmailDraftField.bcc))
                field(KAgentEmailDraftField.bcc, d.labels.bcc)
              else
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: KButton(
                    label: d.labels.showBcc,
                    variant: KButtonVariant.ghost,
                    onPressed: locked
                        ? null
                        : () => setState(() => showBcc = true),
                  ),
                ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) => KMarkdownEditor(
              key: d.editorKey,
              markdown: d.value.markdown,
              onChanged: (text, transaction) {
                if (!locked &&
                    transaction.origin == KEditorTransactionOrigin.local) {
                  change(KAgentEmailDraftField.markdown, text);
                }
              },
              inline: true,
              readOnly: locked,
              semanticLabel: d.labels.message,
              showModeSwitcher: false,
              showSearchButton: false,
              showFixedToolbar: d.showFormatBar && !locked,
              showFloatingToolbar: false,
              showExpandButton: d.showExpandButton && !locked,
              expandLabel: d.labels.expand,
              collapseLabel: d.labels.collapse,
              minHeight: emailDraftBodyHeight(
                context,
                d.value.markdown,
                constraints.maxWidth,
                expand: d.showExpandButton && !locked,
                toolbar:
                    !locked &&
                    (d.showFormatBar ||
                        (!d.showExpandButton && d.dictationState != null)),
              ),
              dictationState: locked ? null : d.dictationState,
              dictationAudioLevel: d.dictationAudioLevel,
              onDictationPressed: locked ? null : d.onDictationPressed,
            ),
          ),
          if (d.errors[KAgentEmailDraftField.markdown] case final String error)
            Semantics(
              liveRegion: true,
              child: KText(
                error,
                variant: KTextVariant.caption,
                style: TextStyle(color: t.colorStatusErrorForeground),
              ),
            ),
          if (d.attachments.isNotEmpty || d.onAddAttachment != null)
            Semantics(
              label: d.labels.attachments,
              child: KInline(
                wrap: true,
                children: [
                  for (final file in d.attachments)
                    IntrinsicWidth(
                      child: KAttachment(
                        title: KText(
                          file.name,
                          variant: KTextVariant.bodySmall,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        description: file.description == null
                            ? null
                            : KText(
                                file.description!,
                                variant: KTextVariant.caption,
                              ),
                        size: KAttachmentSize.compact,
                        actions: d.onRemoveAttachment == null
                            ? null
                            : KIconButton(
                                icon: KIconName.x,
                                label:
                                    d.labels.removeAttachment?.call(
                                      file.name,
                                    ) ??
                                    'Remove ${file.name}',
                                onPressed: locked
                                    ? null
                                    : () => d.onRemoveAttachment!(file.id),
                              ),
                      ),
                    ),
                  if (d.onAddAttachment != null)
                    KButton(
                      variant: KButtonVariant.ghost,
                      leading: const KIcon(KIconName.paperclip),
                      label: d.labels.addAttachment,
                      onPressed: locked ? null : d.onAddAttachment,
                    ),
                ],
              ),
            ),
          if (d.error != null)
            KAlert(title: KText(d.error!), tone: KStatusTone.error),
          if (d.statusLabel != null)
            Semantics(
              liveRegion: true,
              child: KText(d.statusLabel!, variant: KTextVariant.caption),
            ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: KInline(
              gap: KLayoutGap.action,
              wrap: true,
              children: [
                KButton(
                  label: d.labels.discard,
                  variant: KButtonVariant.ghost,
                  onPressed: locked ? null : d.onDiscard,
                ),
                KButton(
                  label: d.labels.send,
                  leading: const KIcon(KIconName.send),
                  loading: d.status == KAgentEmailDraftStatus.submitting,
                  onPressed:
                      locked ||
                          d.sendDisabled ||
                          d.errors.isNotEmpty ||
                          [d.subjectDictationState, d.dictationState].any(
                            (state) =>
                                state == KDictationState.recording ||
                                state == KDictationState.processing,
                          )
                      ? null
                      : d.onSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
