import {
  useEffect,
  useMemo,
  useState,
  type HTMLAttributes,
  type ReactNode,
} from "react";
import { KBadge, type KBadgeVariant } from "../basic-components.js";
import { KSpinner } from "../extended-components.js";
import { KIcon, type KIconName } from "../primitives/icon.js";

export type KWorkflowStatus =
  | "pending"
  | "running"
  | "paused"
  | "waiting"
  | "succeeded"
  | "failed"
  | "cancelled";

export type KWorkflowEventKind =
  | "status"
  | "log"
  | "progress"
  | "question"
  | "answer"
  | "result"
  | "approval"
  | "artifact"
  | "custom";

export type KWorkflowPresentation = "auto" | "detailed" | "compact";

export interface KWorkflowEvent {
  id: string;
  kind: KWorkflowEventKind;
  title: string;
  description?: string;
  timestamp?: string;
  sequence?: number;
  status?: KWorkflowStatus;
  content?: ReactNode;
  /** Technical events are hidden by default in the compact presentation. */
  importance?: "primary" | "secondary" | "technical";
  interactive?: boolean;
}

export interface KWorkflowPhase {
  id: string;
  title: string;
  status: KWorkflowStatus;
  startedAt?: string | number | Date;
  endedAt?: string | number | Date;
  durationLabel?: string;
  events: readonly KWorkflowEvent[];
  defaultOpen?: boolean;
}

export interface KWorkflowLabels {
  timeline?: string;
  steps?: string;
  duration?: string;
  start?: string;
  end?: string;
  notEnded?: string;
  running?: string;
  pending?: string;
  paused?: string;
  waiting?: string;
  succeeded?: string;
  failed?: string;
  cancelled?: string;
}

export interface KWorkflowProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "onSelect"
> {
  title: string;
  status: KWorkflowStatus;
  phases: readonly KWorkflowPhase[];
  statusLabel?: string;
  startedAt?: string | number | Date;
  endedAt?: string | number | Date;
  durationLabel?: string;
  stepCountLabel?: string;
  presentation?: KWorkflowPresentation;
  labels?: KWorkflowLabels;
  expandedPhaseIds?: readonly string[];
  defaultExpandedPhaseIds?: readonly string[];
  onExpandedPhaseIdsChange?: (phaseIds: string[]) => void;
  onPhaseOpenChange?: (phase: KWorkflowPhase, open: boolean) => void;
  onEventActivate?: (event: KWorkflowEvent, phase: KWorkflowPhase) => void;
  renderEvent?: (event: KWorkflowEvent, phase: KWorkflowPhase) => ReactNode;
  renderPhaseIcon?: (phase: KWorkflowPhase) => ReactNode;
  showTechnicalEventsInCompact?: boolean;
  now?: string | number | Date;
  formatDuration?: (milliseconds: number, running: boolean) => string;
  formatDateTime?: (value: string | number | Date) => string;
}

const defaultLabels: Required<KWorkflowLabels> = {
  timeline: "Workflow",
  steps: "Steps",
  duration: "Duration",
  start: "Start",
  end: "End",
  notEnded: "Not finished",
  running: "Running",
  pending: "Pending",
  paused: "Paused",
  waiting: "Waiting",
  succeeded: "Completed",
  failed: "Failed",
  cancelled: "Cancelled",
};

export function KWorkflow({
  title,
  status,
  phases,
  statusLabel,
  startedAt,
  endedAt,
  durationLabel,
  stepCountLabel,
  presentation = "auto",
  labels,
  expandedPhaseIds,
  defaultExpandedPhaseIds,
  onExpandedPhaseIdsChange,
  onPhaseOpenChange,
  onEventActivate,
  renderEvent,
  renderPhaseIcon,
  showTechnicalEventsInCompact = false,
  now,
  formatDuration,
  formatDateTime = defaultFormatDateTime,
  className,
  ...props
}: KWorkflowProps) {
  const text = { ...defaultLabels, ...labels };
  const initialExpanded = useMemo(
    () =>
      defaultExpandedPhaseIds ??
      phases
        .filter((phase) => phase.defaultOpen ?? phase.status !== "succeeded")
        .map(({ id }) => id),
    [defaultExpandedPhaseIds, phases],
  );
  const [internalExpanded, setInternalExpanded] =
    useState<readonly string[]>(initialExpanded);
  const expanded = expandedPhaseIds ?? internalExpanded;

  const updatePhase = (phase: KWorkflowPhase, open: boolean) => {
    const next = open
      ? [...expanded.filter((id) => id !== phase.id), phase.id]
      : expanded.filter((id) => id !== phase.id);
    if (expandedPhaseIds === undefined) setInternalExpanded(next);
    onExpandedPhaseIdsChange?.(next);
    onPhaseOpenChange?.(phase, open);
  };

  return (
    <section
      className={["k-workflow", className].filter(Boolean).join(" ")}
      data-presentation={presentation}
      data-status={status}
      aria-label={title}
      {...props}
    >
      <header className="k-workflow__summary">
        <div className="k-workflow__identity">
          <h2>{title}</h2>
          <KBadge variant={badgeVariant(status)}>
            {statusLabel ?? text[status]}
          </KBadge>
        </div>
        <dl className="k-workflow__metrics">
          <div>
            <dt>{text.steps}</dt>
            <dd>{stepCountLabel ?? phases.length}</dd>
          </div>
          <div>
            <dt>{text.duration}</dt>
            <dd>
              {durationLabel ?? (
                <KElapsedTime
                  startedAt={startedAt}
                  endedAt={endedAt}
                  now={now}
                  formatDuration={formatDuration}
                />
              )}
            </dd>
          </div>
        </dl>
        {(startedAt || endedAt) && (
          <dl className="k-workflow__dates">
            <div>
              <dt>{text.start}</dt>
              <dd>{startedAt ? formatDateTime(startedAt) : "–"}</dd>
            </div>
            <div>
              <dt>{text.end}</dt>
              <dd>{endedAt ? formatDateTime(endedAt) : text.notEnded}</dd>
            </div>
          </dl>
        )}
      </header>

      <div className="k-workflow__heading">
        <KIcon name="sliders-horizontal" />
        <h3>{text.timeline}</h3>
      </div>

      <ol className="k-workflow__timeline">
        {phases.map((phase) => {
          const open = expanded.includes(phase.id);
          return (
            <li
              key={phase.id}
              className="k-workflow__phase"
              data-status={phase.status}
            >
              <span className="k-workflow__phase-node">
                {renderPhaseIcon?.(phase) ?? (
                  <WorkflowStateIcon status={phase.status} />
                )}
              </span>
              <div className="k-workflow__phase-content">
                <div className="k-workflow__phase-header">
                  <button
                    type="button"
                    className="k-workflow__phase-toggle"
                    aria-expanded={open}
                    onClick={() => updatePhase(phase, !open)}
                  >
                    <KIcon name={open ? "chevron-down" : "chevron-right"} />
                    <span>{phase.title}</span>
                  </button>
                  <KElapsedTime
                    className="k-workflow__phase-duration"
                    startedAt={phase.startedAt}
                    endedAt={phase.endedAt}
                    label={phase.durationLabel}
                    now={now}
                    formatDuration={formatDuration}
                  />
                </div>
                {open && (
                  <ol className="k-workflow__events">
                    {phase.events.map((event) => (
                      <WorkflowEventRow
                        key={event.id}
                        event={event}
                        phase={phase}
                        renderEvent={renderEvent}
                        onActivate={onEventActivate}
                        showTechnicalInCompact={showTechnicalEventsInCompact}
                      />
                    ))}
                  </ol>
                )}
              </div>
            </li>
          );
        })}
      </ol>
    </section>
  );
}

function WorkflowEventRow({
  event,
  phase,
  renderEvent,
  onActivate,
  showTechnicalInCompact,
}: {
  event: KWorkflowEvent;
  phase: KWorkflowPhase;
  renderEvent?: KWorkflowProps["renderEvent"];
  onActivate?: KWorkflowProps["onEventActivate"];
  showTechnicalInCompact: boolean;
}) {
  const body = renderEvent?.(event, phase) ?? (
    <>
      <div className="k-workflow-event__meta">
        <span className="k-workflow-event__kind">
          <KIcon name={eventIcon(event)} />
          {event.title}
        </span>
        <span>
          {event.sequence !== undefined ? `#${event.sequence} · ` : ""}
          {event.timestamp}
        </span>
      </div>
      {event.description && <p>{event.description}</p>}
      {event.content}
    </>
  );
  const interactive = event.interactive && Boolean(onActivate);
  return (
    <li
      className="k-workflow-event"
      data-kind={event.kind}
      data-importance={event.importance ?? "primary"}
      data-show-technical-compact={showTechnicalInCompact || undefined}
      data-status={event.status}
    >
      <article>
        {body}
        {interactive ? (
          <button
            type="button"
            className="k-workflow-event__activate"
            aria-label={event.title}
            onClick={() => onActivate?.(event, phase)}
          >
            <KIcon name="chevron-right" />
          </button>
        ) : null}
      </article>
    </li>
  );
}

export interface KElapsedTimeProps extends Omit<
  HTMLAttributes<HTMLSpanElement>,
  "children"
> {
  startedAt?: string | number | Date;
  endedAt?: string | number | Date;
  now?: string | number | Date;
  label?: string;
  formatDuration?: (milliseconds: number, running: boolean) => string;
}

export function KElapsedTime({
  startedAt,
  endedAt,
  now,
  label,
  formatDuration = defaultFormatDuration,
  ...props
}: KElapsedTimeProps) {
  const [clock, setClock] = useState(() => Date.now());
  const running = Boolean(startedAt && !endedAt);
  useEffect(() => {
    if (!running || now !== undefined || label) return;
    const timer = window.setInterval(() => setClock(Date.now()), 1000);
    return () => window.clearInterval(timer);
  }, [label, now, running]);
  if (label) return <span {...props}>{label}</span>;
  if (!startedAt) return <span {...props}>–</span>;
  const start = toMilliseconds(startedAt);
  const end = endedAt
    ? toMilliseconds(endedAt)
    : now !== undefined
      ? toMilliseconds(now)
      : clock;
  return (
    <span {...props}>{formatDuration(Math.max(0, end - start), running)}</span>
  );
}

function WorkflowStateIcon({ status }: { status: KWorkflowStatus }) {
  if (status === "running") return <KSpinner label="Running" />;
  return <KIcon name={statusIcon(status)} />;
}

const statusIcon = (status: KWorkflowStatus): KIconName =>
  status === "succeeded"
    ? "circle-check"
    : status === "failed"
      ? "circle-alert"
      : status === "cancelled"
        ? "x"
        : status === "paused" || status === "waiting"
          ? "clock"
          : "info";

const eventIcon = (event: KWorkflowEvent): KIconName =>
  event.kind === "artifact"
    ? "paperclip"
    : event.kind === "result" || event.kind === "approval"
      ? "circle-check"
      : event.kind === "question"
        ? "info"
        : event.kind === "log"
          ? "file-text"
          : statusIcon(event.status ?? "pending");

const badgeVariant = (status: KWorkflowStatus): KBadgeVariant =>
  status === "failed"
    ? "destructive"
    : status === "succeeded"
      ? "success"
      : status === "running"
        ? "info"
        : status === "paused" || status === "waiting"
          ? "warning"
          : status === "cancelled"
            ? "secondary"
            : "outline";

const toMilliseconds = (value: string | number | Date) =>
  value instanceof Date ? value.getTime() : new Date(value).getTime();

const defaultFormatDateTime = (value: string | number | Date) =>
  new Intl.DateTimeFormat(undefined, {
    dateStyle: "short",
    timeStyle: "short",
  }).format(new Date(value));

function defaultFormatDuration(milliseconds: number, running: boolean) {
  const seconds = Math.floor(milliseconds / 1000);
  if (seconds < 60) return running ? `${seconds} sec.` : "<1 min.";
  const minutes = Math.floor(seconds / 60);
  const remainder = seconds % 60;
  return running
    ? `${minutes}:${remainder.toString().padStart(2, "0")}`
    : `${minutes} min.`;
}
