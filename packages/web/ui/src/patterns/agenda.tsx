import type { HTMLAttributes, ReactNode } from "react";
import { KText } from "../primitives/text.js";

export interface KAgendaItem {
  id: string;
  time: string;
  dateTime?: string;
  title: string;
  description?: ReactNode;
  transition?: ReactNode;
  state?: "upcoming" | "current" | "completed";
  action?: ReactNode;
}

export interface KAgendaProps extends HTMLAttributes<HTMLOListElement> {
  items: KAgendaItem[];
  label: string;
}

/** Compact read-only schedule; routing and time/status calculations belong to the host. */
export function KAgenda({ items, label, className, ...props }: KAgendaProps) {
  return (
    <ol
      {...props}
      aria-label={label}
      className={["k-agenda", className].filter(Boolean).join(" ")}
    >
      {items.map((item) => (
        <li
          key={item.id}
          className="k-agenda__item"
          data-state={item.state ?? "upcoming"}
          aria-current={item.state === "current" ? "step" : undefined}
        >
          <time className="k-agenda__time" dateTime={item.dateTime}>
            {item.time}
          </time>
          <div className="k-agenda__rail" aria-hidden="true">
            <span />
          </div>
          <div className="k-agenda__content">
            <KText variant="label">{item.title}</KText>
            {item.description && (
              <KText variant="bodySmall" className="k-agenda__detail">
                {item.description}
              </KText>
            )}
            {item.transition && (
              <div className="k-agenda__transition">{item.transition}</div>
            )}
            {item.action}
          </div>
        </li>
      ))}
    </ol>
  );
}
