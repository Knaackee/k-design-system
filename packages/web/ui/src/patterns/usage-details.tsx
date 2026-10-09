import type { HTMLAttributes, ReactNode } from "react";

import { KBadge } from "../basic-components.js";

import { KProgress } from "../extended-components.js";

import { KDisclosure } from "../primitives/disclosure.js";

import { KText } from "../primitives/text.js";

export interface KUsageWindow {
  id: string;

  label: string;

  valueLabel: string;

  progress?: number;

  extraResetCount?: number;

  renewalLabel?: string;

  renewalExact?: string;
}

export interface KUsageValue {
  id: string;

  label: string;

  valueLabel: string;

  detail?: string;
}

export interface KUsageDetailsProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "title"
> {
  title: string;

  sourceLabel?: string;

  statusLabel: string;

  observedLabel?: string;

  windows?: readonly KUsageWindow[];

  balances?: readonly KUsageValue[];

  extraResets?: readonly KUsageValue[];

  extraResetsLabel?: string;

  emptyMessage?: string;

  notice?: ReactNode;
}

/** Read-only usage presentation. Providers, timestamps and freshness belong to the consumer. */

export function KUsageDetails({
  title,
  sourceLabel,
  statusLabel,
  observedLabel,
  windows = [],
  balances = [],
  extraResets = [],
  extraResetsLabel,
  emptyMessage,
  notice,
  className,
  ...props
}: KUsageDetailsProps) {
  return (
    <section
      className={["k-usage-details", className].filter(Boolean).join(" ")}
      aria-label={title}
      {...props}
    >
      <header className="k-usage-details__header">
        <div>
          <KText as="h3" variant="body" className="k-usage-details__title">
            {title}
          </KText>
          {sourceLabel && (
            <KText as="p" variant="caption" className="k-usage-details__muted">
              {sourceLabel}
            </KText>
          )}
        </div>

        <KBadge variant="outline">{statusLabel}</KBadge>
      </header>

      {windows.length > 0 && (
        <div className="k-usage-details__windows">
          {windows.map((item) => (
            <div key={item.id} className="k-usage-details__window">
              {item.progress !== undefined &&
              Number.isFinite(item.progress) &&
              item.progress >= 0 &&
              item.progress <= 100 ? (
                <KProgress
                  label={item.label}
                  value={item.progress}
                  valueLabel={
                    <span className="k-usage-details__progress-value">
                      {item.valueLabel}
                      {Number.isSafeInteger(item.extraResetCount) &&
                        item.extraResetCount! > 0 && (
                          <KBadge
                            variant="secondary"
                            title={`${item.extraResetCount} ${item.extraResetCount === 1 ? "zusätzlicher Reset" : "zusätzliche Resets"} vorhanden`}
                            aria-label={`${item.extraResetCount} ${item.extraResetCount === 1 ? "zusätzlicher Reset" : "zusätzliche Resets"} vorhanden`}
                          >
                            +{item.extraResetCount}
                          </KBadge>
                        )}
                    </span>
                  }
                />
              ) : (
                <div className="k-usage-details__row">
                  <KText variant="bodySmall">{item.label}</KText>
                  <strong>{item.valueLabel}</strong>
                </div>
              )}

              {item.renewalLabel && (
                <KText
                  as="p"
                  variant="caption"
                  className="k-usage-details__muted"
                >
                  {item.renewalLabel}
                  {item.renewalExact && ` · ${item.renewalExact}`}
                </KText>
              )}
            </div>
          ))}
        </div>
      )}

      {balances.length > 0 && (
        <dl className="k-usage-details__values">
          {balances.map((item) => (
            <div key={item.id} className="k-usage-details__value">
              <dt>{item.label}</dt>
              <dd>
                <strong>{item.valueLabel}</strong>
                {item.detail && (
                  <KText
                    as="p"
                    variant="caption"
                    className="k-usage-details__muted"
                  >
                    {item.detail}
                  </KText>
                )}
              </dd>
            </div>
          ))}
        </dl>
      )}

      {extraResets.length > 0 && (
        <KDisclosure
          className="k-usage-details__extras"
          title={extraResetsLabel ?? "Additional resets"}
        >
          <dl className="k-usage-details__values">
            {extraResets.map((item) => (
              <div key={item.id} className="k-usage-details__value">
                <dt>
                  {item.label}
                  {item.detail && (
                    <KText
                      as="p"
                      variant="caption"
                      className="k-usage-details__muted"
                    >
                      {item.detail}
                    </KText>
                  )}
                </dt>
                <dd>
                  <strong>{item.valueLabel}</strong>
                </dd>
              </div>
            ))}
          </dl>
        </KDisclosure>
      )}

      {!windows.length &&
        !balances.length &&
        !extraResets.length &&
        emptyMessage && (
          <KText as="p" variant="bodySmall" className="k-usage-details__muted">
            {emptyMessage}
          </KText>
        )}

      <footer className="k-usage-details__footer">
        {observedLabel && (
          <KText as="p" variant="caption" className="k-usage-details__muted">
            {observedLabel}
          </KText>
        )}
        {notice && (
          <KText as="p" variant="caption" className="k-usage-details__muted">
            {notice}
          </KText>
        )}
      </footer>
    </section>
  );
}
