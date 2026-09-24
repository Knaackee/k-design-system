import { useState, type ReactNode } from "react";
import { KAlert, KAttachment, KBadge } from "../basic-components.js";
import { KProgress } from "../extended-components.js";
import { KButton } from "../primitives/button.js";
import { KDisclosure } from "../primitives/disclosure.js";
import { KIcon } from "../primitives/icon.js";
import type {
  KAgentActivityPart,
  KAgentApprovalPart,
  KAgentApprovalResponse,
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

export interface KAgentPartActions {
  onApprovalResponse?: (response: KAgentApprovalResponse) => void;
  onQuestionResponse?: (response: KAgentQuestionResponse) => void;
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
  const complete = ["succeeded", "failed", "cancelled"].includes(part.state);
  return (
    <KDisclosure
      className="k-agent-card k-agent-tool"
      title={part.title}
      defaultOpen={!complete}
      leadingIcon={<ToolStateIcon state={part.state} />}
      actions={<KBadge variant="outline">{toolStateLabel(part.state)}</KBadge>}
    >
      {part.description ? <p>{part.description}</p> : null}
      {part.arguments !== undefined ? (
        <AgentData label="Arguments" value={part.arguments} />
      ) : null}
      {part.result !== undefined ? (
        <AgentData label="Result" value={part.result} />
      ) : null}
      {part.error ? <KAlert tone="error" title={part.error} /> : null}
    </KDisclosure>
  );
}

export function KAgentApproval({
  part,
  onResponse,
  reasonLabel = "Optional reason",
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
          <label className="k-agent-reason">
            <span>{reasonLabel}</span>
            <textarea
              value={reason}
              onChange={(event) => setReason(event.target.value)}
            />
          </label>
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
}: {
  part: KAgentQuestionPart;
  onResponse?: (response: KAgentQuestionResponse) => void;
}) {
  const [text, setText] = useState("");
  const [selected, setSelected] = useState<string[]>([]);
  if (part.state !== "pending") {
    return (
      <section className="k-agent-card">
        <div className="k-agent-card__heading">
          <KIcon name="info" />
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
        <KIcon name="info" />
        <div>
          <strong>{part.title}</strong>
          {part.description ? <p>{part.description}</p> : null}
        </div>
      </div>
      {part.kind === "text" ? (
        <textarea
          value={text}
          placeholder={part.placeholder}
          onChange={(event) => setText(event.target.value)}
        />
      ) : null}
      <div className="k-agent-options">
        {part.options?.map((option) => (
          <label key={option.id}>
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
      title={part.title}
      defaultOpen={Boolean(part.active)}
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
