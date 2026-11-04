import { useId, type ReactNode, type CSSProperties } from "react";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";
import { KStack, KInline } from "../primitives/layout.js";
import { KText } from "../primitives/text.js";

export interface KPlanPrice {
  /** Formatted by the consumer, including currency. No implicit price calculation. */
  amount: string;
  period?: string;
  billingNote?: string;
  /** Optional equivalent price; the actual billed amount stays prominent. */
  equivalent?: string;
}
export interface KPlan {
  id: string;
  name: string;
  description?: string;
  badge?: string;
  artwork?: ReactNode;
  features: readonly string[];
  prices: Readonly<Record<string, KPlanPrice | undefined>>;
  disabled?: boolean;
  emphasis?: "neutral" | "accent";
}
export interface KPlanCardProps {
  plan: KPlan;
  price?: KPlanPrice;
  selected?: boolean;
  /** Omit to render a static, single-plan card. */
  onSelect?: (id: string) => void;
  name?: string;
  unavailableLabel: string;
}

export function KPlanCard({
  plan,
  price,
  selected = false,
  onSelect,
  name,
  unavailableLabel,
}: KPlanCardProps) {
  const id = useId();
  const disabled = plan.disabled || !price;
  return (
    <div
      className="k-plan-card"
      data-selected={selected}
      data-disabled={disabled}
      data-emphasis={plan.emphasis ?? "neutral"}
    >
      {onSelect && (
        <input
          className="k-plan-card__radio"
          type="radio"
          id={id}
          name={name}
          value={plan.id}
          checked={selected}
          disabled={disabled}
          onChange={() => onSelect(plan.id)}
          aria-label={plan.name}
          aria-describedby={`${id}-summary`}
        />
      )}
      <div className="k-plan-card__content" id={`${id}-summary`}>
        <KStack gap="action" align="stretch">
          <KInline
            gap="control"
            className="k-plan-card__heading"
            align="center"
          >
            <KText variant="heading4" as="span">
              {plan.name}
            </KText>
            {plan.badge && (
              <KText variant="caption" className="k-plan-card__badge">
                {plan.badge}
              </KText>
            )}
          </KInline>
          {plan.artwork && (
            <div className="k-plan-card__artwork" aria-hidden="true">
              {plan.artwork}
            </div>
          )}
          <KStack gap="control" align="stretch">
            <div className="k-plan-card__price">
              <KText as="span" variant="heading1">
                {price?.amount ?? unavailableLabel}
              </KText>
              {price?.period && (
                <KText
                  as="span"
                  variant="bodySmall"
                  className="k-plan-picker__muted"
                >
                  {price.period}
                </KText>
              )}
            </div>
            {price?.billingNote && (
              <KText variant="bodySmall" className="k-plan-picker__muted">
                {price.billingNote}
              </KText>
            )}
            {price?.equivalent && (
              <KText variant="bodySmall" className="k-plan-picker__muted">
                {price.equivalent}
              </KText>
            )}
            {plan.description && (
              <KText variant="bodySmall" className="k-plan-picker__muted">
                {plan.description}
              </KText>
            )}
          </KStack>
        </KStack>
        <ul className="k-plan-card__features">
          {plan.features.map((feature, index) => (
            <li key={index}>
              <KIcon name="check" size={20} strokeWidth={1.5} />
              <KText as="span" variant="bodySmall">
                {feature}
              </KText>
            </li>
          ))}
        </ul>
      </div>
      {onSelect && (
        <label className="k-plan-card__hit" htmlFor={id}>
          <span className="k-plan-picker__sr">{plan.name}</span>
        </label>
      )}
    </div>
  );
}

export type KPlanPickerLayout =
  "cards" | "stacked" | "compact" | "focused" | "comparison";
export interface KPlanComparisonRow {
  id: string;
  label: string;
  /** Display text keyed by plan id; no inferred or invented inclusions. */
  values: Readonly<Record<string, string>>;
}

export interface KPlanPickerProps {
  plans: readonly KPlan[];
  value: string | null;
  onValueChange: (id: string) => void;
  intervals: readonly { id: string; label: string }[];
  interval: string;
  onIntervalChange: (id: string) => void;
  label: string;
  intervalLabel: string;
  unavailableLabel: string;
  actionLabel: string;
  onContinue: (selection: { planId: string; intervalId: string }) => void;
  /** Disable only the final action while keeping choices editable. */
  actionDisabled?: boolean;
  loading?: boolean;
  disabled?: boolean;
  note?: ReactNode;
  layout?: KPlanPickerLayout;
  comparison?: { label: string; rows: readonly KPlanComparisonRow[] };
  /** Decorative/product preview supplied by the consumer; no generated claims. */
  intro?: ReactNode;
  stickyAction?: boolean;
  /** Mobile may show a compact selector and only the selected plan's details. */
  mobileLayout?: "focused" | "stacked";
  className?: string;
  style?: CSSProperties;
}

/** Controlled presentation. The host owns purchase, pricing, translations and persistence. */
export function KPlanPicker({
  plans,
  value,
  onValueChange,
  intervals,
  interval,
  onIntervalChange,
  label,
  intervalLabel,
  unavailableLabel,
  actionLabel,
  onContinue,
  actionDisabled = false,
  loading = false,
  disabled = false,
  note,
  layout = "cards",
  comparison,
  intro,
  stickyAction = false,
  mobileLayout = "focused",
  className = "",
  style,
}: KPlanPickerProps) {
  const group = useId();
  const selected = plans.find((plan) => plan.id === value);
  const ready =
    intervals.some((option) => option.id === interval) &&
    selected &&
    !selected.disabled &&
    selected.prices[interval];
  return (
    <KStack
      gap="section"
      align="stretch"
      className={`k-plan-picker ${className}`}
      style={style}
      data-layout={layout}
      data-sticky-action={stickyAction}
      data-mobile-layout={mobileLayout}
      data-single={plans.length === 1}
    >
      {intro && <div className="k-plan-picker__intro">{intro}</div>}
      {intervals.length > 1 && (
        <PlanSwitch
          className="k-plan-picker__intervals"
          label={intervalLabel}
          options={intervals}
          value={interval}
          onChange={onIntervalChange}
          disabled={disabled || loading}
        />
      )}
      {plans.length > 1 &&
        (layout === "focused" ||
          (mobileLayout === "focused" && layout === "cards")) && (
          <PlanSwitch
            className="k-plan-picker__mobile-options"
            label={label}
            options={plans.map((plan) => ({
              id: plan.id,
              label: plan.name,
              disabled: plan.disabled || !plan.prices[interval],
            }))}
            value={value}
            onChange={onValueChange}
            disabled={disabled || loading}
          />
        )}
      <fieldset
        className="k-plan-picker__grid"
        disabled={disabled || loading}
        style={
          {
            "--k-plan-columns": Math.min(3, Math.max(1, plans.length)),
          } as CSSProperties
        }
      >
        <legend className="k-plan-picker__sr">{label}</legend>
        {plans.map((plan) => (
          <KPlanCard
            key={plan.id}
            plan={plan}
            price={plan.prices[interval]}
            selected={value === plan.id}
            onSelect={plans.length > 1 ? onValueChange : undefined}
            name={group}
            unavailableLabel={unavailableLabel}
          />
        ))}
      </fieldset>
      {layout === "compact" && selected && (
        <KStack
          gap="control"
          align="stretch"
          className="k-plan-picker__detail"
          key={selected.id}
        >
          <KText variant="heading4">{selected.name}</KText>
          <ul className="k-plan-card__features">
            {selected.features.map((feature, index) => (
              <li key={index}>
                <KIcon name="check" size={20} strokeWidth={1.5} />
                <KText as="span" variant="bodySmall">
                  {feature}
                </KText>
              </li>
            ))}
          </ul>
        </KStack>
      )}
      {layout === "comparison" && comparison && (
        <div
          className="k-plan-picker__comparison"
          role="region"
          aria-label={comparison.label}
          tabIndex={0}
        >
          <table>
            <caption>{comparison.label}</caption>
            <thead>
              <tr>
                <th scope="col">
                  <span className="k-plan-picker__sr">{comparison.label}</span>
                </th>
                {plans.map((plan) => (
                  <th
                    scope="col"
                    key={plan.id}
                    data-selected={plan.id === value}
                  >
                    {plan.name}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {comparison.rows.map((row) => (
                <tr key={row.id}>
                  <th scope="row">{row.label}</th>
                  {plans.map((plan) => (
                    <td key={plan.id} data-selected={plan.id === value}>
                      {row.values[plan.id] ?? "\u2014"}
                    </td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <KStack gap="control" align="stretch" className="k-plan-picker__footer">
        <KButton
          loading={loading}
          disabled={disabled || actionDisabled || !ready}
          onClick={() => {
            if (ready && selected && !actionDisabled)
              onContinue({ planId: selected.id, intervalId: interval });
          }}
        >
          {actionLabel}
          <KIcon name="arrow-right" strokeWidth={1.5} />
        </KButton>
        {note && (
          <KText variant="bodySmall" className="k-plan-picker__muted">
            {note}
          </KText>
        )}
      </KStack>
    </KStack>
  );
}

/** Radio semantics keep keyboard selection predictable for both switch styles. */
function PlanSwitch({
  className,
  label,
  options,
  value,
  onChange,
  disabled,
}: {
  className: string;
  label: string;
  options: readonly { id: string; label: string; disabled?: boolean }[];
  value: string | null;
  onChange: (id: string) => void;
  disabled: boolean;
}) {
  const name = useId();
  return (
    <fieldset className={`k-plan-switch ${className}`} disabled={disabled}>
      <legend className="k-plan-picker__sr">{label}</legend>
      {options.map((option) => (
        <label className="k-plan-switch__option" key={option.id}>
          <input
            type="radio"
            name={name}
            value={option.id}
            checked={value === option.id}
            disabled={option.disabled}
            onChange={() => onChange(option.id)}
          />
          <span>{option.label}</span>
        </label>
      ))}
    </fieldset>
  );
}
