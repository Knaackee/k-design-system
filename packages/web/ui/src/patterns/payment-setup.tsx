import { useId, type HTMLAttributes, type ReactNode } from "react";
import { KBadge } from "../basic-components.js";
import { KButton } from "../primitives/button.js";
import { KCard } from "../primitives/card.js";
import { KDisclosure } from "../primitives/disclosure.js";
import { KIcon, type KIconName } from "../primitives/icon.js";
import { KInline, KStack } from "../primitives/layout.js";
import { KText } from "../primitives/text.js";

export type KPaymentSetupState =
  "connected" | "action-required" | "pending" | "needs-correction" | "ready";

export interface KPaymentSetupStep {
  id: string;
  label: string;
  description: string;
  state: "complete" | "current" | "waiting" | "attention";
}

export interface KPaymentSetupAction {
  label: string;
  onAction: () => void;
  icon?: KIconName;
  loading?: boolean;
  disabled?: boolean;
}

export interface KPaymentSetupProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "title"
> {
  state: KPaymentSetupState;
  providerName: string;
  providerIcon?: ReactNode;
  connectionLabel: string;
  environmentLabel?: string;
  statusLabel: string;
  title: ReactNode;
  description: ReactNode;
  note?: ReactNode;
  steps?: readonly KPaymentSetupStep[];
  stepsLabel?: string;
  primaryAction?: KPaymentSetupAction;
  secondaryAction?: KPaymentSetupAction;
  help?: { title: string; content: ReactNode };
}

const stateIcon: Record<KPaymentSetupState, KIconName> = {
  connected: "link",
  "action-required": "clipboard-list",
  pending: "clock-3",
  "needs-correction": "shield-alert",
  ready: "shield-check",
};

/** Presentation only. The host owns Stripe, verification, copy, steps and every action.
 * Coarse readiness phases must describe real progress, never duplicate provider form steps.
 */
export function KPaymentSetup({
  state,
  providerName,
  providerIcon,
  connectionLabel,
  environmentLabel,
  statusLabel,
  title,
  description,
  note,
  steps,
  stepsLabel = "Setup progress",
  primaryAction,
  secondaryAction,
  help,
  className,
  ...props
}: KPaymentSetupProps) {
  const titleId = useId();
  return (
    <KCard
      {...props}
      className={["k-payment-setup", className].filter(Boolean).join(" ")}
      data-state={state}
      aria-labelledby={titleId}
    >
      <KStack gap="section" align="stretch">
        <header className="k-payment-setup__header">
          <KInline
            gap="control"
            align="center"
            className="k-payment-setup__provider"
          >
            <span className="k-payment-setup__provider-icon" aria-hidden="true">
              {providerIcon ?? <KIcon name="credit-card" size={22} />}
            </span>
            <KStack gap="control" className="k-payment-setup__identity">
              <KText variant="heading5" as="span">
                {providerName}
              </KText>
              <KInline gap="control" align="center">
                <KIcon
                  name="check"
                  size={14}
                  className="k-payment-setup__connected"
                />
                <KText variant="caption" className="k-payment-setup__muted">
                  {connectionLabel}
                </KText>
              </KInline>
            </KStack>
          </KInline>
          {environmentLabel ? (
            <KBadge variant="outline">{environmentLabel}</KBadge>
          ) : null}
        </header>

        <div
          className="k-payment-setup__status"
          key={state}
          role="status"
          aria-live="polite"
          aria-atomic="true"
        >
          <span className="k-payment-setup__status-icon" aria-hidden="true">
            <KIcon name={stateIcon[state]} size={28} />
          </span>
          <KStack
            gap="control"
            align="stretch"
            className="k-payment-setup__copy"
          >
            <KText variant="label" className="k-payment-setup__status-label">
              {statusLabel}
            </KText>
            <KText as="h2" variant="heading3" id={titleId}>
              {title}
            </KText>
            <KText variant="body" className="k-payment-setup__muted">
              {description}
            </KText>
          </KStack>
        </div>

        {steps?.length ? (
          <ol className="k-payment-setup__steps" aria-label={stepsLabel}>
            {steps.map((step, index) => (
              <li
                key={step.id}
                className="k-payment-setup__step"
                data-step-state={step.state}
                aria-current={
                  step.state === "current" || step.state === "attention"
                    ? "step"
                    : undefined
                }
              >
                <span
                  className="k-payment-setup__step-marker"
                  aria-hidden="true"
                >
                  {step.state === "complete" ? (
                    <KIcon name="check" size={16} />
                  ) : step.state === "attention" ? (
                    <KIcon name="circle-alert" size={16} />
                  ) : (
                    index + 1
                  )}
                </span>
                <KStack
                  gap="control"
                  align="stretch"
                  className="k-payment-setup__step-copy"
                >
                  <KText variant="label">{step.label}</KText>
                  <KText variant="caption" className="k-payment-setup__muted">
                    {step.description}
                  </KText>
                </KStack>
              </li>
            ))}
          </ol>
        ) : null}

        {primaryAction || secondaryAction || note ? (
          <KStack
            gap="control"
            align="stretch"
            className="k-payment-setup__footer"
          >
            {primaryAction || secondaryAction ? (
              <KInline gap="action" wrap className="k-payment-setup__actions">
                {primaryAction ? (
                  <KButton
                    onClick={primaryAction.onAction}
                    loading={primaryAction.loading}
                    disabled={primaryAction.disabled}
                  >
                    {primaryAction.label}
                    {primaryAction.icon ? (
                      <KIcon name={primaryAction.icon} size={16} />
                    ) : null}
                  </KButton>
                ) : null}
                {secondaryAction ? (
                  <KButton
                    variant="ghost"
                    onClick={secondaryAction.onAction}
                    loading={secondaryAction.loading}
                    disabled={secondaryAction.disabled}
                  >
                    {secondaryAction.icon ? (
                      <KIcon name={secondaryAction.icon} size={16} />
                    ) : null}
                    {secondaryAction.label}
                  </KButton>
                ) : null}
              </KInline>
            ) : null}
            {note ? (
              <KText variant="caption" className="k-payment-setup__muted">
                {note}
              </KText>
            ) : null}
          </KStack>
        ) : null}

        {help ? (
          <KDisclosure
            title={help.title}
            leadingIcon={<KIcon name="flask-conical" size={16} />}
          >
            {help.content}
          </KDisclosure>
        ) : null}
      </KStack>
    </KCard>
  );
}
