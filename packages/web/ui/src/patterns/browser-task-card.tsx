import type { ReactNode } from "react";
import { KCard } from "../primitives/card.js";

export type KBrowserTaskCardProps = {
  title: ReactNode;
  description: ReactNode;
  preview: ReactNode;
  actions: ReactNode;
  className?: string;
};

/** Consumer owns session state and actions; the preview remains a 16:9 surface. */
export function KBrowserTaskCard({
  title,
  description,
  preview,
  actions,
  className = "",
}: KBrowserTaskCardProps) {
  return (
    <KCard className={`k-browser-task-card ${className}`}>
      <h2>{title}</h2>
      <p>{description}</p>
      <div className="k-browser-task-card__preview">{preview}</div>
      <div className="k-browser-task-card__actions">{actions}</div>
    </KCard>
  );
}
