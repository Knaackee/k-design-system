import { useId, useState, type ReactNode } from "react";

import { KButton } from "../primitives/button.js";

import { KIcon } from "../primitives/icon.js";

/** Editing surface with a persistent desktop preview; hosts own state and save semantics. */

export function KBookingPageLayout({
  children,
  preview,
  previewTitle = "Vorschau",
  previewAction,
  previewHelp,
}: {
  children: ReactNode;
  preview: ReactNode;
  previewTitle?: string;
  previewAction?: ReactNode;
  previewHelp?: string;
}) {
  return (
    <div className="k-booking-page-layout">
      <div className="k-booking-page-main">{children}</div>
      <aside className="k-booking-page-aside">
        <div className="k-booking-page-preview-heading">
          <strong>{previewTitle}</strong>
          {previewAction}
        </div>
        <div className="k-booking-page-phone">{preview}</div>
        {previewHelp && <p className="k-booking-page-help">{previewHelp}</p>}
      </aside>
    </div>
  );
}

export function KBookingPageSection({
  title,
  subtitle,
  children,
  open,
  defaultOpen = false,
  onOpenChange,
  className = "",
}: {
  title: string;
  subtitle?: string;
  children: ReactNode;
  open?: boolean;
  defaultOpen?: boolean;
  onOpenChange?: (open: boolean) => void;
  className?: string;
}) {
  const [local, setLocal] = useState(defaultOpen);
  const expanded = open ?? local;
  const id = useId();

  return (
    <section className={`k-booking-page-section ${className}`}>
      <button
        type="button"
        className="k-booking-page-section-trigger"
        aria-expanded={expanded}
        aria-controls={id}
        onClick={() => {
          setLocal(!expanded);
          onOpenChange?.(!expanded);
        }}
      >
        <span>
          <strong>{title}</strong>
          {subtitle && <small>{subtitle}</small>}
        </span>
        <KIcon name={expanded ? "chevron-down" : "chevron-right"} size={18} />
      </button>
      <div
        id={id}
        hidden={!expanded}
        className="k-booking-page-section-content"
      >
        {children}
      </div>
    </section>
  );
}

export function KBookingPageCard({
  children,
  className = "",
}: {
  children: ReactNode;
  className?: string;
}) {
  return <div className={`k-booking-page-card ${className}`}>{children}</div>;
}

export function KBookingPageStatus({
  online,
  url,
  thumbnail,
  children,
  addressAction,
}: {
  online: boolean;
  url: string;
  thumbnail?: ReactNode;
  children: ReactNode;
  addressAction?: ReactNode;
}) {
  return (
    <KBookingPageCard className="k-booking-page-status">
      {thumbnail && (
        <div className="k-booking-page-status-thumb">{thumbnail}</div>
      )}
      <div className="k-booking-page-status-copy">
        <strong>
          <span className="k-booking-page-status-dot" data-online={online} />
          {online ? "Online" : "Offline"}
        </strong>
        <div className="k-booking-page-url">
          <KIcon name="link" size={15} />
          <span title={url}>{url}</span>
        </div>
        {addressAction}
      </div>
      <div className="k-booking-page-status-actions">{children}</div>
    </KBookingPageCard>
  );
}

export interface KBookingThemeChoice {
  id: string;
  label: string;
  image: string;
}

export function KBookingThemePicker({
  options,
  value,
  onChange,
  disabled = false,
}: {
  options: readonly KBookingThemeChoice[];
  value: string;
  onChange: (value: string) => void;
  disabled?: boolean;
}) {
  const [expanded, setExpanded] = useState(false);
  const selected = options.find((o) => o.id === value);
  const first = options.slice(0, 4);
  if (selected && !first.some((o) => o.id === value)) first[3] = selected;
  const visible = expanded ? options : first;

  return (
    <div>
      <div className="k-booking-theme-picker" role="group" aria-label="Design">
        {visible.map((option) => (
          <button
            type="button"
            key={option.id}
            aria-pressed={option.id === value}
            disabled={disabled}
            onClick={() => onChange(option.id)}
          >
            <img src={option.image} alt="" loading="lazy" />
            <span>{option.label}</span>
          </button>
        ))}
      </div>
      {options.length > 4 && (
        <KButton variant="ghost" onClick={() => setExpanded(!expanded)}>
          {expanded
            ? "Weniger Designs"
            : `Alle ${options.length} Designs ansehen`}
        </KButton>
      )}
    </div>
  );
}

export function KBookingFlowChoice({
  value,
  onChange,
  disabled = false,
}: {
  value: string;
  onChange: (value: "guided" | "free") => void;
  disabled?: boolean;
}) {
  return (
    <div
      className="k-booking-flow-choice"
      role="group"
      aria-label="Buchungsablauf"
    >
      {(["guided", "free"] as const).map((mode) => (
        <button
          key={mode}
          type="button"
          disabled={disabled}
          aria-pressed={value === mode}
          onClick={() => onChange(mode)}
        >
          <span className="k-booking-flow-diagram" aria-hidden="true">
            {mode === "guided" ? (
              <>
                <KIcon name="square" />
                <KIcon name="arrow-right" size={15} />
                <KIcon name="square" />
                <KIcon name="arrow-right" size={15} />
                <KIcon name="square" />
              </>
            ) : (
              <>
                <KIcon name="layout-grid" size={36} />
                <KIcon name="arrow-right" size={18} />
                <KIcon name="shopping-cart" size={32} />
              </>
            )}
          </span>
          <strong>{mode === "guided" ? "Geführt" : "Freie Auswahl"}</strong>
          <small>
            {mode === "guided"
              ? "Kategorien nacheinander, Schritt für Schritt."
              : "Beliebig wechseln, alles gemeinsam buchen."}
          </small>
        </button>
      ))}
    </div>
  );
}
