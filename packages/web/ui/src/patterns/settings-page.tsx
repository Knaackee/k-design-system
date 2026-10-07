import type { HTMLAttributes, ReactNode } from "react";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";

export interface KSettingsPageProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "title"
> {
  navigation: ReactNode;
  breadcrumb?: ReactNode;
  children: ReactNode;
  detailVisible?: boolean;
  onBack?: () => void;
  backLabel?: string;
  eyebrow?: ReactNode;
  title?: ReactNode;
  description?: ReactNode;
  wide?: boolean;
}

/** Responsive settings shell. Consumers retain routing, state and navigation content. */
export function KSettingsPage({
  navigation,
  breadcrumb,
  children,
  detailVisible = false,
  onBack,
  backLabel = "Settings",
  eyebrow,
  title,
  description,
  wide = false,
  className,
  ...props
}: KSettingsPageProps) {
  return (
    <section
      className={["k-settings-page", className].filter(Boolean).join(" ")}
      data-detail-visible={detailVisible || undefined}
      {...props}
    >
      <div className="k-settings-page__layout">
        <div className="k-settings-page__navigation">{navigation}</div>
        <section
          className="k-settings-page__detail"
          aria-label="Settings content"
          tabIndex={0}
        >
          <div
            className="k-settings-page__content"
            data-wide={wide || undefined}
          >
            {onBack ? (
              <div className="k-settings-page__back-slot">
                <KButton
                  className="k-settings-page__back"
                  variant="ghost"
                  onClick={onBack}
                >
                  <KIcon name="arrow-left" size={16} />
                  {backLabel}
                </KButton>
              </div>
            ) : null}
            {breadcrumb}
            {eyebrow || title || description ? (
              <header className="k-settings-page__header">
                {eyebrow ? (
                  <div className="k-settings-page__eyebrow">{eyebrow}</div>
                ) : null}
                {title ? <h1>{title}</h1> : null}
                {description ? <p>{description}</p> : null}
              </header>
            ) : null}
            <div className="k-settings-page__body">{children}</div>
          </div>
        </section>
      </div>
    </section>
  );
}

export interface KSettingsSectionProps extends Omit<
  HTMLAttributes<HTMLElement>,
  "title"
> {
  title: ReactNode;
  description?: ReactNode;
  children: ReactNode;
}

export function KSettingsSection({
  title,
  description,
  children,
  className,
  ...props
}: KSettingsSectionProps) {
  return (
    <section
      className={["k-settings-section", className].filter(Boolean).join(" ")}
      {...props}
    >
      <header className="k-settings-section__header">
        <h2>{title}</h2>
        {description ? <p>{description}</p> : null}
      </header>
      <div className="k-settings-section__body">{children}</div>
    </section>
  );
}

export interface KSettingsRowProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  "title"
> {
  title: ReactNode;
  description?: ReactNode;
  control: ReactNode;
  layout?: KSettingsRowLayout;
}

export type KSettingsRowLayout = "auto" | "compact" | "fullWidth";

export function KSettingsRow({
  title,
  description,
  control,
  layout = "auto",
  className,
  ...props
}: KSettingsRowProps) {
  return (
    <div
      className={["k-settings-row", className].filter(Boolean).join(" ")}
      data-layout={layout === "fullWidth" ? "full-width" : layout}
      {...props}
    >
      <div className="k-settings-row__layout">
        <div className="k-settings-row__copy">
          <div className="k-settings-row__title">{title}</div>
          {description ? (
            <div className="k-settings-row__description">{description}</div>
          ) : null}
        </div>
        <div className="k-settings-row__control">{control}</div>
      </div>
    </div>
  );
}
