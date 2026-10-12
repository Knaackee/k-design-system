import { useEffect, useId, useRef, type ReactNode } from "react";
import { KBadge } from "../basic-components.js";
import { KButton } from "../primitives/button.js";
import { KCard } from "../primitives/card.js";
import { KDisclosure } from "../primitives/disclosure.js";
import { KSelect } from "../forms/selection.js";

export type KBrowserPermissionDecision =
  "allow-once" | "allow" | "ask" | "block";
export type KBrowserRuleDecision = Exclude<
  KBrowserPermissionDecision,
  "allow-once"
>;
export interface KWebsiteIdentityProps {
  host: string;
  /** Consumer-supplied decorative favicon; use a local asset or privacy-safe source. */
  favicon?: ReactNode;
}
export function KWebsiteIdentity({ host, favicon }: KWebsiteIdentityProps) {
  return (
    <div className="k-website-identity">
      <span className="k-website-identity__icon" aria-hidden="true">
        {favicon ?? "↗"}
      </span>
      <strong>{host}</strong>
    </div>
  );
}

const defaultLabels = {
  waiting: "Needs your permission",
  manual: "Your action is needed",
  blocked: "Blocked",
  expired: "Request expired",
  agent: "Personal agent",
  scope: "Only this action on this path",
  details: "Action details",
  origin: "Origin",
  path: "Path",
  action: "Action",
  allowed: "Allowed",
  once: "Allow once",
  allow: "Remember permission",
  ask: "Always ask",
  block: "Block",
  takeover: "Take over browser",
  advanced: "Website permission",
  website: "Allow all website forms…",
  confirmation: "Allow all forms on this exact website?",
  confirm: "Confirm website permission",
  cancel: "Cancel",
  websiteScope:
    "Applies to all forms at this exact website address for this personal agent. Other hosts are separate. You can revoke it in permissions.",
  manualLimit:
    "Purchases, payments and messages still require your manual action.",
  manualNote:
    "Take over the browser to review and submit yourself. The agent is paused.",
  stoppedNote:
    "This request cannot be approved. Ask the agent for a new request to continue.",
  rules: "Browser permissions",
  rulesDescription: "Manage what your personal agent can do on each website.",
  searchNote:
    "Common searches are already allowed. Search results do not grant permission for other website actions.",
  baseline: "Included search rule",
  custom: "Your rule",
  active: "Active",
  revoked: "Revoked",
  ruleDecision: "Permission",
  revoke: "Revoke",
  reset: "Reset to included rule",
  empty: "No browser permissions yet",
  emptyDescription:
    "When your agent needs a website action, you decide. Saved permissions will appear here.",
};
export type KBrowserPermissionLabels = Partial<typeof defaultLabels>;
export interface KBrowserPermissionRequestProps extends KWebsiteIdentityProps {
  agent: string;
  title: string;
  description: string;
  origin: string;
  path: string;
  action: string;
  details?: ReactNode;
  state?: "request" | "manual" | "blocked" | "expired";
  onDecision: (decision: KBrowserPermissionDecision) => void;
  onTakeOver: () => void;
  /** Website confirmation is controlled by the consumer and starts closed. */
  websiteConfirmationOpen?: boolean;
  onWebsiteConfirmationChange?: (open: boolean) => void;
  onAllowWebsite?: () => void;
  labels?: KBrowserPermissionLabels;
}
/** Presentation only. The consumer binds decisions to a request and enforces policy. */
export function KBrowserPermissionRequest({
  agent,
  title,
  description,
  host,
  favicon,
  origin,
  path,
  action,
  details,
  state = "request",
  onDecision,
  onTakeOver,
  websiteConfirmationOpen = false,
  onWebsiteConfirmationChange,
  onAllowWebsite,
  labels,
}: KBrowserPermissionRequestProps) {
  const text = { ...defaultLabels, ...labels };
  const waiting = state === "request";
  const confirmationId = useId();
  const websiteOpener = useRef<HTMLButtonElement>(null);
  const websiteCancel = useRef<HTMLButtonElement>(null);
  const wasConfirming = useRef(false);
  useEffect(() => {
    if (websiteConfirmationOpen) websiteCancel.current?.focus();
    else if (wasConfirming.current) websiteOpener.current?.focus();
    wasConfirming.current = websiteConfirmationOpen;
  }, [websiteConfirmationOpen]);
  return (
    <KCard className="k-browser-permission">
      <header className="k-browser-permission__header">
        <span className="k-browser-permission__eyebrow">
          {text.agent} · {agent}
        </span>
        <KBadge
          variant={
            waiting ? "warning" : state === "manual" ? "info" : "outline"
          }
        >
          {waiting ? text.waiting : text[state]}
        </KBadge>
      </header>
      <div className="k-browser-permission__intro">
        <h2>{title}</h2>
        <p>{description}</p>
      </div>
      <div className="k-browser-permission__destination">
        <KWebsiteIdentity host={host} favicon={favicon} />
        <code>{path}</code>
        <p>{action}</p>
        <small>{text.scope}</small>
      </div>
      <KDisclosure title={text.details}>
        <dl className="k-browser-permission__details">
          <dt>{text.origin}</dt>
          <dd>
            <code>{origin}</code>
          </dd>
          <dt>{text.path}</dt>
          <dd>
            <code>{path}</code>
          </dd>
          <dt>{text.action}</dt>
          <dd>{action}</dd>
        </dl>
        {details}
      </KDisclosure>
      {waiting ? (
        <>
          <div className="k-browser-permission__actions">
            <KButton onClick={() => onDecision("allow-once")}>
              {text.once}
            </KButton>
            <KButton variant="secondary" onClick={() => onDecision("allow")}>
              {text.allow}
            </KButton>
            <KButton variant="secondary" onClick={() => onDecision("ask")}>
              {text.ask}
            </KButton>
            <KButton variant="ghost" onClick={() => onDecision("block")}>
              {text.block}
            </KButton>
          </div>
          {onAllowWebsite && onWebsiteConfirmationChange && (
            <KDisclosure title={text.advanced}>
              <p>{text.websiteScope}</p>
              <p>{text.manualLimit}</p>
              <KButton
                ref={websiteOpener}
                variant="secondary"
                aria-expanded={websiteConfirmationOpen}
                aria-controls={
                  websiteConfirmationOpen ? confirmationId : undefined
                }
                onClick={() => onWebsiteConfirmationChange(true)}
              >
                {text.website}
              </KButton>
              {websiteConfirmationOpen && (
                <div
                  id={confirmationId}
                  className="k-browser-permission__confirmation"
                  role="group"
                  aria-label={text.confirmation}
                >
                  <strong>{text.confirmation}</strong>
                  <code>{origin}</code>
                  <div className="k-browser-permission__actions">
                    <KButton
                      ref={websiteCancel}
                      variant="secondary"
                      onClick={() => onWebsiteConfirmationChange(false)}
                    >
                      {text.cancel}
                    </KButton>
                    <KButton onClick={onAllowWebsite}>{text.confirm}</KButton>
                  </div>
                </div>
              )}
            </KDisclosure>
          )}
        </>
      ) : (
        <p className="k-browser-permission__notice">
          {state === "manual" ? text.manualNote : text.stoppedNote}
        </p>
      )}
      <footer className="k-browser-permission__footer">
        <KButton
          variant={state === "manual" ? "primary" : "ghost"}
          onClick={onTakeOver}
        >
          {text.takeover}
        </KButton>
      </footer>
    </KCard>
  );
}

export interface KBrowserPermissionRule extends KWebsiteIdentityProps {
  id: string;
  origin: string;
  path: string;
  action: string;
  source: "baseline" | "custom";
  decision: KBrowserRuleDecision;
  status: "active" | "revoked";
  websiteWide?: boolean;
  details?: ReactNode;
}
export interface KBrowserPermissionListProps {
  agent: string;
  rules: readonly KBrowserPermissionRule[];
  onDecisionChange: (id: string, decision: KBrowserRuleDecision) => void;
  onRevoke: (id: string) => void;
  onReset: (id: string) => void;
  labels?: KBrowserPermissionLabels;
}
export function KBrowserPermissionList({
  agent,
  rules,
  onDecisionChange,
  onRevoke,
  onReset,
  labels,
}: KBrowserPermissionListProps) {
  const text = { ...defaultLabels, ...labels };
  return (
    <KCard className="k-browser-permission k-browser-permission-list">
      <header className="k-browser-permission__intro">
        <span className="k-browser-permission__eyebrow">
          {text.agent} · {agent}
        </span>
        <h2>{text.rules}</h2>
        <p>{text.rulesDescription}</p>
      </header>
      <p className="k-browser-permission__notice">{text.searchNote}</p>
      {rules.length === 0 ? (
        <div className="k-browser-permission-list__empty">
          <h3>{text.empty}</h3>
          <p>{text.emptyDescription}</p>
        </div>
      ) : (
        <ul className="k-browser-permission-list__rules">
          {rules.map((rule) => (
            <li key={rule.id} data-rule-id={rule.id}>
              <div className="k-browser-permission-list__identity">
                <KWebsiteIdentity host={rule.host} favicon={rule.favicon} />
                <KBadge
                  variant={
                    rule.status === "revoked"
                      ? "outline"
                      : rule.decision === "allow"
                        ? "success"
                        : rule.decision === "block"
                          ? "destructive"
                          : "warning"
                  }
                >
                  {rule.status === "revoked"
                    ? text.revoked
                    : rule.decision === "allow"
                      ? text.allowed
                      : rule.decision === "block"
                        ? text.blocked
                        : text.ask}
                </KBadge>
              </div>
              <div className="k-browser-permission-list__scope">
                <strong>{rule.action}</strong>
                <code>{rule.path}</code>
                <small>
                  {text[rule.source]} · {text[rule.status]}
                </small>
              </div>
              {rule.websiteWide && (
                <p className="k-browser-permission__notice">
                  {text.websiteScope} {text.manualLimit}
                </p>
              )}
              <div className="k-browser-permission-list__controls">
                <KSelect
                  label={`${text.ruleDecision} · ${rule.host} · ${rule.action}`}
                  value={rule.decision}
                  disabled={rule.status === "revoked"}
                  options={[
                    { value: "allow", label: text.allowed },
                    { value: "ask", label: text.ask },
                    { value: "block", label: text.block },
                  ]}
                  onValueChange={(value) =>
                    onDecisionChange(rule.id, value as KBrowserRuleDecision)
                  }
                />
                {rule.source === "baseline" ? (
                  <KButton variant="ghost" onClick={() => onReset(rule.id)}>
                    {text.reset}
                  </KButton>
                ) : (
                  <KButton
                    variant="ghost"
                    disabled={rule.status === "revoked"}
                    onClick={() => onRevoke(rule.id)}
                  >
                    {text.revoke}
                  </KButton>
                )}
              </div>
              <KDisclosure title={text.details}>
                <code>{rule.origin}</code>
                {rule.details}
              </KDisclosure>
            </li>
          ))}
        </ul>
      )}
    </KCard>
  );
}
