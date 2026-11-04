import type { ReactNode } from "react";
import { KButton, KIcon, type KIconName } from "@k-design-system/ui";
export function Row({
  title,
  value,
  icon,
  iconSize = 17,
  description,
  onClick,
  danger = false,
  selected = false,
}: {
  title: string;
  value?: string;
  icon?: KIconName;
  iconSize?: number;
  description?: string;
  onClick: () => void;
  danger?: boolean;
  selected?: boolean;
}) {
  return (
    <KButton
      fullWidth
      variant="ghost"
      className={`sg-row${danger ? " sg-danger" : ""}${danger && !icon ? " sg-row-centered" : ""}`}
      onClick={onClick}
      aria-pressed={selected || undefined}
    >
      <span className="sg-row-layout">
        {icon && (
          <span
            className="sg-icon"
            data-icon={icon}
            data-plain={danger || undefined}
          >
            <KIcon name={icon} size={iconSize} strokeWidth={1.75} />
          </span>
        )}
        <span className="sg-copy">
          <span>{title}</span>
          {description && <small>{description}</small>}
        </span>
        {value && <span className="sg-value">{value}</span>}
        {!danger && (
          <KIcon
            className="sg-chevron"
            name={selected ? "check" : "chevron-right"}
            size={20}
          />
        )}
      </span>
    </KButton>
  );
}
export function Group({
  title,
  footer,
  children,
}: {
  title: string;
  footer?: string;
  children: ReactNode;
}) {
  return (
    <section className="sg-group">
      {title && <h2>{title}</h2>}
      <div className="sg-group-body">{children}</div>
      {footer && <p>{footer}</p>}
    </section>
  );
}
