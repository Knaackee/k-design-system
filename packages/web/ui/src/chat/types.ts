export type KChatRole = "user" | "assistant" | "system";

export type KChatRunState =
  | "idle"
  | "submitted"
  | "streaming"
  | "awaiting-input"
  | "stopped"
  | "completed"
  | "failed";

export type KAgentToolState =
  | "pending"
  | "running"
  | "approval-required"
  | "succeeded"
  | "failed"
  | "cancelled";

export type KAgentResolutionState =
  "pending" | "answered" | "approved" | "rejected" | "cancelled" | "expired";

export interface KChatTextPart {
  id: string;
  type: "text";
  text: string;
  streaming?: boolean;
}

export interface KChatAttachmentPart {
  id: string;
  type: "attachment";
  title: string;
  description?: string;
  mediaType?: string;
  progress?: number;
  state?: "ready" | "uploading" | "processing" | "error" | "complete";
}

export interface KAgentSourcePart {
  id: string;
  type: "source";
  title: string;
  description?: string;
  url?: string;
}

export interface KAgentToolPart {
  id: string;
  type: "tool";
  toolName: string;
  title: string;
  description?: string;
  state: KAgentToolState;
  arguments?: unknown;
  result?: unknown;
  error?: string;
}

export interface KAgentApprovalOption {
  id: string;
  label: string;
  tone?: "primary" | "secondary" | "destructive";
}

export interface KAgentApprovalPart {
  id: string;
  type: "approval";
  title: string;
  description?: string;
  detail?: string;
  state: KAgentResolutionState;
  options: readonly KAgentApprovalOption[];
  selectedOptionId?: string;
  responseSummary?: string;
}

export type KAgentQuestionKind =
  "text" | "single-choice" | "multiple-choice" | "confirmation" | "custom";

export interface KAgentQuestionOption {
  id: string;
  label: string;
  description?: string;
}

export interface KAgentQuestionPart {
  id: string;
  type: "question";
  title: string;
  description?: string;
  kind: KAgentQuestionKind;
  state: KAgentResolutionState;
  options?: readonly KAgentQuestionOption[];
  selectedOptionIds?: readonly string[];
  answerSummary?: string;
  placeholder?: string;
  submitLabel?: string;
}

export type KAgentTaskState =
  "pending" | "active" | "completed" | "failed" | "skipped";

export interface KAgentTaskItem {
  id: string;
  title: string;
  description?: string;
  state: KAgentTaskState;
}

export interface KAgentTaskPart {
  id: string;
  type: "tasks";
  title: string;
  items: readonly KAgentTaskItem[];
}

export interface KAgentArtifactPart {
  id: string;
  type: "artifact";
  title: string;
  description?: string;
  artifactType?: string;
  reference: string;
}

export interface KAgentActivityPart {
  id: string;
  type: "activity";
  title: string;
  summary: string;
  active?: boolean;
}

export interface KAgentStatusPart {
  id: string;
  type: "status";
  title: string;
  description?: string;
  tone?: "neutral" | "info" | "success" | "warning" | "error";
}

export type KAgentFormFieldKind =
  "text" | "number" | "boolean" | "single-choice" | "multiple-choice";

export interface KAgentFormField {
  id: string;
  kind: KAgentFormFieldKind;
  label: string;
  description?: string;
  placeholder?: string;
  required?: boolean;
  defaultValue?: unknown;
  options?: readonly KAgentQuestionOption[];
  minimum?: number;
  maximum?: number;
  minItems?: number;
  maxItems?: number;
}

export interface KAgentFormPart {
  id: string;
  type: "form";
  title: string;
  description?: string;
  state: KAgentResolutionState;
  fields: readonly KAgentFormField[];
  submitLabel?: string;
  cancelLabel?: string;
  responseSummary?: string;
}

export interface KAgentExternalActionPart {
  id: string;
  type: "external-action";
  title: string;
  description?: string;
  url: string;
  actionLabel: string;
  cancelLabel?: string;
  state: KAgentResolutionState;
  responseSummary?: string;
}

export interface KAgentAttachmentRequestPart {
  id: string;
  type: "attachment-request";
  title: string;
  description?: string;
  actionLabel: string;
  accept?: string;
  multiple?: boolean;
  maxFiles?: number;
  state: KAgentResolutionState;
  attachments?: readonly KChatAttachmentPart[];
  responseSummary?: string;
}

export type KChatMessagePart =
  | KChatTextPart
  | KChatAttachmentPart
  | KAgentSourcePart
  | KAgentToolPart
  | KAgentApprovalPart
  | KAgentQuestionPart
  | KAgentFormPart
  | KAgentExternalActionPart
  | KAgentAttachmentRequestPart
  | KAgentTaskPart
  | KAgentArtifactPart
  | KAgentActivityPart
  | KAgentStatusPart;

export interface KChatMessageValue {
  id: string;
  role: KChatRole;
  parts: readonly KChatMessagePart[];
  authorLabel?: string;
  timestamp?: string;
  status?: "sending" | "sent" | "failed";
}

export interface KAgentApprovalResponse {
  approvalId: string;
  optionId: string;
  reason?: string;
}

export interface KAgentQuestionResponse {
  questionId: string;
  optionIds?: readonly string[];
  text?: string;
  value?: unknown;
}

export interface KAgentFormResponse {
  formId: string;
  action: "submit" | "cancel";
  values: Readonly<Record<string, unknown>>;
}

export interface KAgentExternalActionResponse {
  actionId: string;
  action: "open" | "cancel";
  url: string;
}

export interface KAgentAttachmentRequestResponse {
  requestId: string;
  action: "select" | "cancel";
  accept?: string;
  multiple: boolean;
  maxFiles?: number;
}

export interface KAgentUiAdapter<TSnapshot = unknown, TIntent = unknown> {
  toMessages(snapshot: TSnapshot): readonly KChatMessageValue[];
  toRunState(snapshot: TSnapshot): KChatRunState;
  toHostIntent(intent: KAgentUiIntent): TIntent;
}

export type KAgentUiIntent =
  | { type: "submit-message"; text: string }
  | { type: "stop-run" }
  | { type: "load-older" }
  | { type: "activate-attachment"; partId: string }
  | { type: "activate-source"; partId: string }
  | { type: "activate-artifact"; partId: string }
  | { type: "approval-response"; response: KAgentApprovalResponse }
  | { type: "question-response"; response: KAgentQuestionResponse }
  | { type: "form-response"; response: KAgentFormResponse }
  | { type: "external-action"; response: KAgentExternalActionResponse }
  | {
      type: "attachment-request";
      response: KAgentAttachmentRequestResponse;
    };
