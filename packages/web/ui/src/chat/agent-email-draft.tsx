import { useId, useState, type Ref } from "react";
import { KAlert, KAttachment } from "../basic-components.js";
import { KIconButton } from "../actions/icon-button.js";
import {
  KMarkdownEditor,
  type KMarkdownEditorProps,
} from "../editors/markdown-editor.js";
import { KField } from "../forms/field.js";
import {
  KDictationAction,
  KDictationState,
  type KDictationActionProps,
} from "../forms/dictation-action.js";
import { KInput } from "../forms/input.js";
import { KButton } from "../primitives/button.js";
import { KCard, type KCardBorder } from "../primitives/card.js";
import { KIcon } from "../primitives/icon.js";
import { KInline, KStack } from "../primitives/layout.js";
import { KText } from "../primitives/text.js";

export interface KAgentEmailDraftValue {
  /** Address display strings; parsing and recipient validation belong to the host. */
  to: string;
  cc?: string;
  bcc?: string;
  subject: string;
  markdown: string;
}

export interface KAgentEmailDraftAttachment {
  id: string;
  name: string;
  description?: string;
}

export type KAgentEmailDraftStatus =
  "pending" | "submitting" | "sent" | "discarded";

export interface KAgentEmailDraftLabels {
  from: string;
  to: string;
  cc: string;
  bcc: string;
  subject: string;
  message: string;
  showBcc: string;
  recipientPlaceholder: string;
  attachments: string;
  addAttachment: string;
  removeAttachment: (name: string) => string;
  send: string;
  discard: string;
}

export interface KAgentEmailDraftProps {
  /** Changing identity resets the local Bcc disclosure. */
  draftId: string;
  title: string;
  /** Read-only sending account; the host owns account selection and authorization. */
  from: string;
  value: KAgentEmailDraftValue;
  onChange: (value: KAgentEmailDraftValue) => void;
  attachments?: readonly KAgentEmailDraftAttachment[];
  onAddAttachment?: () => void;
  onRemoveAttachment?: (id: string) => void;
  /** Explicit approval callbacks only; this component never sends a message. */
  onSend: () => void;
  onDiscard: () => void;
  status?: KAgentEmailDraftStatus;
  statusLabel?: string;
  description?: string;
  error?: string;
  errors?: Partial<Record<keyof KAgentEmailDraftValue, string>>;
  sendDisabled?: boolean;
  disabled?: boolean;
  labels?: Partial<KAgentEmailDraftLabels>;
  /** Optional host-owned Subject capture; no microphone is rendered by default. */
  subjectDictation?: KDictationActionProps & { offset?: number };
  /** Native selection and insertion access; the host owns transcription/undo. */
  subjectInputRef?: Ref<HTMLInputElement>;
  onSubjectSelectionChange?: (selection: {
    start: number;
    end: number;
  }) => void;
  /** One pending card may opt into the existing attention effect. */
  border?: KCardBorder;
  /** Existing editor capabilities; formatting and microphone are opt-in. */
  editor?: Pick<
    KMarkdownEditorProps,
    | "showFixedToolbar"
    | "showFloatingToolbar"
    | "showExpandButton"
    | "expandLabel"
    | "collapseLabel"
    | "labels"
    | "linkLabels"
    | "dictation"
  >;
}

const defaultLabels: KAgentEmailDraftLabels = {
  from: "From",
  to: "To",
  cc: "Cc",
  bcc: "Bcc",
  subject: "Subject",
  message: "Message",
  showBcc: "Add Bcc",
  recipientPlaceholder: "name@example.com",
  attachments: "Attachments",
  addAttachment: "Add attachment",
  removeAttachment: (name) => `Remove ${name}`,
  send: "Send",
  discard: "Discard",
};

/** Controlled approval surface. All draft, attachment and delivery state belongs to the host. */
export function KAgentEmailDraft(props: KAgentEmailDraftProps) {
  return <EmailDraftSession key={props.draftId} {...props} />;
}

function EmailDraftSession({
  title,
  from,
  value,
  onChange,
  attachments = [],
  onAddAttachment,
  onRemoveAttachment,
  onSend,
  onDiscard,
  status = "pending",
  statusLabel,
  description,
  error,
  errors = {},
  sendDisabled = false,
  disabled = false,
  labels: labelOverrides,
  border = "none",
  editor,
  subjectDictation,
  subjectInputRef,
  onSubjectSelectionChange,
}: KAgentEmailDraftProps) {
  const labels = { ...defaultLabels, ...labelOverrides };
  const titleId = useId();
  const messageErrorId = useId();
  const [showBcc, setShowBcc] = useState(false);
  const locked = disabled || status !== "pending";
  const dictating = [subjectDictation?.state, editor?.dictation?.state].some(
    (state) =>
      state === KDictationState.recording ||
      state === KDictationState.processing,
  );
  const hasErrors = Object.values(errors).some(Boolean);
  const field = (key: "to" | "cc" | "bcc" | "subject") => (
    <div
      className={`k-agent-email-draft__field${key === "subject" ? " k-agent-email-draft__subject" : ""}`}
    >
      <KField label={labels[key]} errorText={errors[key]}>
        <KInput
          ref={key === "subject" ? subjectInputRef : undefined}
          onSelect={
            key === "subject"
              ? (event) => {
                  const input = event.currentTarget;
                  onSubjectSelectionChange?.({
                    start: input.selectionStart ?? 0,
                    end: input.selectionEnd ?? 0,
                  });
                }
              : undefined
          }
          dictationState={
            key === "subject" ? subjectDictation?.state : undefined
          }
          dictationOffset={
            key === "subject" ? subjectDictation?.offset : undefined
          }
          trailingAction={
            key === "subject" && subjectDictation ? (
              <KDictationAction {...subjectDictation} />
            ) : undefined
          }
          className="k-agent-email-draft__input"
          value={value[key] ?? ""}
          inputMode={key === "subject" ? "text" : "email"}
          autoCapitalize={key === "subject" ? undefined : "none"}
          spellCheck={key === "subject" ? undefined : false}
          placeholder={
            key === "subject" ? labels.subject : labels.recipientPlaceholder
          }
          disabled={locked}
          onChange={(event) =>
            onChange({ ...value, [key]: event.target.value })
          }
        />
      </KField>
    </div>
  );
  return (
    <KCard
      className="k-agent-email-draft"
      border={status === "pending" ? border : "none"}
      aria-labelledby={titleId}
      aria-busy={status === "submitting" || undefined}
      data-state={status}
    >
      <KStack gap="action" align="stretch">
        <KInline
          gap="control"
          align="start"
          className="k-agent-email-draft__heading"
        >
          <KIcon name="mail" className="k-leading" />
          <KStack gap="control">
            <KText variant="body" id={titleId}>
              {title}
            </KText>
            {description ? (
              <KText variant="caption" className="k-agent-email-draft__muted">
                {description}
              </KText>
            ) : null}
          </KStack>
        </KInline>
        {field("subject")}
        <div className="k-agent-email-draft__metadata">
          <div className="k-agent-email-draft__field">
            <KField label={labels.from}>
              <KInput
                className="k-agent-email-draft__input"
                value={from}
                readOnly
              />
            </KField>
          </div>
          {field("to")}
          {field("cc")}
          {showBcc || value.bcc || errors.bcc ? (
            field("bcc")
          ) : (
            <KButton
              variant="ghost"
              disabled={locked}
              onClick={() => setShowBcc(true)}
            >
              {labels.showBcc}
            </KButton>
          )}
        </div>
        <div
          className="k-agent-email-draft__message"
          role="group"
          aria-label={labels.message}
          aria-describedby={errors.markdown ? messageErrorId : undefined}
        >
          <KMarkdownEditor
            {...editor}
            className="k-agent-email-draft__editor"
            markdown={value.markdown}
            onChange={(markdown, transaction) => {
              if (!locked && transaction.origin === "local") {
                onChange({ ...value, markdown });
              }
            }}
            readOnly={locked}
            ariaLabel={labels.message}
            showFixedToolbar={!locked && !!editor?.showFixedToolbar}
            showFloatingToolbar={!locked && !!editor?.showFloatingToolbar}
            showModeSwitcher={false}
            showSearchButton={false}
            showExpandButton={!locked && !!editor?.showExpandButton}
            dictation={locked ? undefined : editor?.dictation}
          />
          {errors.markdown ? (
            <KText variant="caption" id={messageErrorId} role="alert">
              {errors.markdown}
            </KText>
          ) : null}
        </div>
        {attachments.length || onAddAttachment ? (
          <KInline
            gap="control"
            align="center"
            wrap
            role="group"
            aria-label={labels.attachments}
          >
            {attachments.map((attachment) => (
              <KAttachment
                key={attachment.id}
                title={attachment.name}
                description={attachment.description}
                size="compact"
                actions={
                  onRemoveAttachment ? (
                    <KIconButton
                      icon="x"
                      label={labels.removeAttachment(attachment.name)}
                      disabled={locked}
                      onClick={() => onRemoveAttachment(attachment.id)}
                    />
                  ) : undefined
                }
              />
            ))}
            {onAddAttachment ? (
              <KButton
                variant="ghost"
                disabled={locked}
                onClick={onAddAttachment}
              >
                <KIcon name="paperclip" />
                {labels.addAttachment}
              </KButton>
            ) : null}
          </KInline>
        ) : null}
        {error ? <KAlert tone="error" title={error} /> : null}
        {statusLabel ? (
          <KText variant="caption" role="status">
            {statusLabel}
          </KText>
        ) : null}
        <KInline gap="action" wrap className="k-agent-email-draft__actions">
          <KButton variant="ghost" disabled={locked} onClick={onDiscard}>
            {labels.discard}
          </KButton>
          <KButton
            disabled={locked || sendDisabled || hasErrors || dictating}
            loading={status === "submitting"}
            onClick={onSend}
          >
            <KIcon name="send" />
            {labels.send}
          </KButton>
        </KInline>
      </KStack>
    </KCard>
  );
}
