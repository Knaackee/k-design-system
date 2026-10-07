import { useState, type ReactNode } from "react";
import { KAlert, KAttachment, KBadge } from "../basic-components.js";
import { KProgress } from "../extended-components.js";
import { KButton } from "../primitives/button.js";
import { KDisclosure } from "../primitives/disclosure.js";
import { KIcon } from "../primitives/icon.js";
import { KInput } from "../forms/input.js";
import type {
  KAgentActivityPart,
  KAgentApprovalPart,
  KAgentApprovalResponse,
  KAgentAttachmentRequestResponse,
  KAgentExternalActionResponse,
  KAgentFormResponse,
  KAgentArtifactPart,
  KAgentQuestionPart,
  KAgentQuestionResponse,
  KAgentSourcePart,
  KAgentStatusPart,
  KAgentTaskPart,
  KAgentToolPart,
  KChatAttachmentPart,
} from "./types.js";

export type KAgentToolRenderer = (part: KAgentToolPart) => ReactNode;

export type KAgentQuestionInputRenderer = (props: {
  value: string;
  onChange: (value: string) => void;
}) => ReactNode;

export interface KAgentPartActions {
  onApprovalResponse?: (response: KAgentApprovalResponse) => void;
  onQuestionResponse?: (response: KAgentQuestionResponse) => void;
  onFormResponse?: (response: KAgentFormResponse) => void;
  onExternalAction?: (response: KAgentExternalActionResponse) => void;
  onAttachmentRequest?: (response: KAgentAttachmentRequestResponse) => void;
  onAttachmentActivate?: (part: KChatAttachmentPart) => void;
  onSourceActivate?: (part: KAgentSourcePart) => void;
  onArtifactActivate?: (part: KAgentArtifactPart) => void;
}

export function KAgentToolCall({
  part,
  renderer,
}: {
  part: KAgentToolPart;
  renderer?: KAgentToolRenderer;
}) {
  if (renderer) return renderer(part);
  return (
    <>
      <KDisclosure
        className="k-agent-tool"
        data-state={part.state}
        title={part.title}
        leadingIcon={<ToolStateIcon state={part.state} />}
        actions={
          <span className="k-visually-hidden">
            {toolStateLabel(part.state)}
          </span>
        }
      >
        {part.description ? <p>{part.description}</p> : null}
        {part.arguments !== undefined ? (
          <AgentData label="Arguments" value={part.arguments} />
        ) : null}
        {part.result !== undefined ? (
          <AgentData label="Result" value={part.result} />
        ) : null}
      </KDisclosure>
      {part.error ? <KAlert tone="error" title={part.error} /> : null}
    </>
  );
}

/** Consecutive calls of the same tool, without hiding questions or approvals. */
export function KAgentToolGroup({
  parts,
}: {
  parts: readonly KAgentToolPart[];
}) {
  const state = parts.some((part) => part.state === "failed")
    ? "failed"
    : parts.some((part) => part.state === "running")
      ? "running"
      : parts.some((part) => part.state === "approval-required")
        ? "approval-required"
        : parts.some((part) => part.state === "pending")
          ? "pending"
          : parts.every((part) => part.state === "cancelled")
            ? "cancelled"
            : "succeeded";
  return (
    <KDisclosure
      className="k-agent-tool k-agent-tool-group"
      data-state={state}
      title={`${parts[0].title} · ${parts.length}×`}
      leadingIcon={<ToolStateIcon state={state} />}
    >
      {parts.map((part) => (
        <KAgentToolCall key={part.id} part={part} />
      ))}
    </KDisclosure>
  );
}

export function KAgentApproval({
  part,
  onResponse,
  reasonLabel = "Add a note (optional)",
}: {
  part: KAgentApprovalPart;
  onResponse?: (response: KAgentApprovalResponse) => void;
  reasonLabel?: string;
}) {
  const [reason, setReason] = useState("");
  const pending = part.state === "pending";
  return (
    <section className="k-agent-card k-agent-approval" aria-live="polite">
      <div className="k-agent-card__heading">
        <KIcon name="lock" />
        <div>
          <strong>{part.title}</strong>
          {part.description ? <p>{part.description}</p> : null}
        </div>
      </div>
      {part.detail ? <pre className="k-agent-data">{part.detail}</pre> : null}
      {pending ? (
        <>
          <KDisclosure className="k-agent-note" title={reasonLabel}>
            <textarea
              aria-label={reasonLabel}
              className="k-agent-note__input"
              value={reason}
              onChange={(event) => setReason(event.target.value)}
            />
          </KDisclosure>
          <div className="k-agent-actions">
            {part.options.map((option) => (
              <KButton
                key={option.id}
                variant={option.tone === "primary" ? "primary" : "secondary"}
                onClick={() =>
                  onResponse?.({
                    approvalId: part.id,
                    optionId: option.id,
                    reason,
                  })
                }
              >
                {option.label}
              </KButton>
            ))}
          </div>
        </>
      ) : (
        <KBadge variant={part.state === "rejected" ? "destructive" : "outline"}>
          {part.responseSummary ?? resolutionLabel(part.state)}
        </KBadge>
      )}
    </section>
  );
}

export function KAgentQuestion({
  part,
  onResponse,
  inputRenderer,
}: {
  part: KAgentQuestionPart;
  onResponse?: (response: KAgentQuestionResponse) => void;
  inputRenderer?: KAgentQuestionInputRenderer;
}) {
  const [text, setText] = useState("");
  const [selected, setSelected] = useState<string[]>([]);
  if (part.state !== "pending") {
    return (
      <section className="k-agent-card k-agent-question">
        <div className="k-agent-card__heading">
          <span className="k-agent-question__icon">
            <KIcon name="circle-question-mark" />
          </span>
          <div>
            <strong>{part.title}</strong>
            <p>{part.answerSummary ?? resolutionLabel(part.state)}</p>
          </div>
        </div>
      </section>
    );
  }
  const multiple = part.kind === "multiple-choice";
  const toggle = (id: string) =>
    setSelected((current) =>
      multiple
        ? current.includes(id)
          ? current.filter((value) => value !== id)
          : [...current, id]
        : [id],
    );
  const submit = () =>
    onResponse?.({ questionId: part.id, optionIds: selected, text });
  return (
    <section className="k-agent-card k-agent-question">
      <div className="k-agent-card__heading">
        <span className="k-agent-question__icon">
          <KIcon name="circle-question-mark" />
        </span>
        <div>
          <strong>{part.title}</strong>
          {part.description ? <p>{part.description}</p> : null}
        </div>
      </div>
      {part.kind === "text" ? (
        inputRenderer ? (
          inputRenderer({ value: text, onChange: setText })
        ) : (
          <KInput
            value={text}
            placeholder={part.placeholder}
            onChange={(event) => setText(event.target.value)}
          />
        )
      ) : null}
      <div className="k-agent-options">
        {part.options?.map((option) => (
          <label key={option.id} data-selected={selected.includes(option.id)}>
            <input
              type={multiple ? "checkbox" : "radio"}
              name={part.id}
              checked={selected.includes(option.id)}
              onChange={() => toggle(option.id)}
            />
            <span>
              <strong>{option.label}</strong>
              {option.description ? <small>{option.description}</small> : null}
            </span>
          </label>
        ))}
      </div>
      <KButton
        onClick={submit}
        disabled={part.kind === "text" ? !text.trim() : selected.length === 0}
      >
        {part.submitLabel ?? "Continue"}
      </KButton>
    </section>
  );
}

export function KAgentTaskGroup({ part }: { part: KAgentTaskPart }) {
  const completed = part.items.filter(
    (item) => item.state === "completed",
  ).length;
  return (
    <KDisclosure
      className="k-agent-card k-agent-tasks"
      title={part.title}
      defaultOpen
      actions={
        <KBadge variant="outline">
          {completed}/{part.items.length}
        </KBadge>
      }
    >
      <KProgress value={completed} max={part.items.length} label={part.title} />
      <ol>
        {part.items.map((item) => (
          <li key={item.id} data-state={item.state}>
            <ToolStateIcon
              state={
                item.state === "active"
                  ? "running"
                  : item.state === "completed"
                    ? "succeeded"
                    : item.state === "failed"
                      ? "failed"
                      : "pending"
              }
            />
            <span>
              <strong>{item.title}</strong>
              {item.description ? <small>{item.description}</small> : null}
            </span>
          </li>
        ))}
      </ol>
    </KDisclosure>
  );
}

export function KAgentActivity({ part }: { part: KAgentActivityPart }) {
  return (
    <KDisclosure
      className="k-agent-activity"
      data-state={part.active ? "running" : "succeeded"}
      title={part.title}
      leadingIcon={
        <ToolStateIcon state={part.active ? "running" : "succeeded"} />
      }
    >
      <p>{part.summary}</p>
    </KDisclosure>
  );
}

export function KAgentAttachment({
  part,
  onActivate,
}: {
  part: KChatAttachmentPart;
  onActivate?: () => void;
}) {
  return (
    <KAttachment
      title={part.title}
      description={part.description}
      state={part.state}
      progress={part.progress}
      onActivate={onActivate}
    />
  );
}

export function KAgentReference({
  part,
  onActivate,
}: {
  part: KAgentSourcePart | KAgentArtifactPart;
  onActivate?: () => void;
}) {
  return (
    <button type="button" className="k-agent-reference" onClick={onActivate}>
      <KIcon name={part.type === "source" ? "external-link" : "file"} />
      <span className="k-agent-reference__content">
        <strong>{part.title}</strong>
        {part.description ? <small>{part.description}</small> : null}
      </span>
      <KIcon name="chevron-right" />
    </button>
  );
}

export function KAgentStatus({ part }: { part: KAgentStatusPart }) {
  return (
    <KAlert
      tone={part.tone ?? "neutral"}
      title={part.title}
      description={part.description}
    />
  );
}

function AgentData({ label, value }: { label: string; value: unknown }) {
  return (
    <div>
      <strong className="k-agent-data__label">{label}</strong>
      <pre className="k-agent-data">
        {typeof value === "string" ? value : JSON.stringify(value, null, 2)}
      </pre>
    </div>
  );
}

function ToolStateIcon({
  state,
}: {
  state:
    KAgentToolPart["state"] | "pending" | "running" | "succeeded" | "failed";
}) {
  const name =
    state === "running"
      ? "refresh-cw"
      : state === "succeeded"
        ? "check"
        : state === "failed"
          ? "x"
          : "clock";
  return (
    <KIcon
      name={name}
      className={state === "running" ? "k-agent-spin" : undefined}
    />
  );
}

const toolStateLabel = (state: KAgentToolPart["state"]) =>
  state.replaceAll("-", " ");
const resolutionLabel = (state: string) => state.replaceAll("-", " ");
