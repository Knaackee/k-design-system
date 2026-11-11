import { createContext, useContext, useEffect } from "react";
import type { CSSProperties, HTMLAttributes, ReactNode } from "react";

import { KMenuButton, type KMenuAction } from "../actions/menu-button.js";
import { KText } from "./text.js";

import {
  KSurface,
  type KSurfaceElevation,
  type KSurfaceTone,
} from "./surface.js";

/**
 * Animated border that conveys a state, never decoration (one per screen):
 * `pulse` needs input, `spin` work in progress, `aurora` AI input active,
 * `flame` critical, `dashed` drop zone or draft, `shimmer` loading,
 * `success` a one-time confirmation. Static under reduced motion.
 */
export type KCardBorder =
  | "none"
  | "pulse"
  | "spin"
  | "aurora"
  | "flame"
  | "dashed"
  | "shimmer"
  | "success";

export interface KCardProps extends Omit<HTMLAttributes<HTMLElement>, "title"> {
  children?: ReactNode;
  elevation?: KSurfaceElevation;
  tone?: KSurfaceTone;
  /** Header: leading visual, title, description and a "…" menu at the end. */
  leading?: ReactNode;
  title?: ReactNode;
  description?: ReactNode;
  /** Card actions in a "…" menu at the top end. */
  menu?: readonly KMenuAction[];
  menuLabel?: string;
  /** Footer actions, e.g. KButtons. */
  actions?: ReactNode;
  border?: KCardBorder;
  /** Overrides `component.cardBorder.color` (single-colour effects). */
  borderColor?: string;
  /** Overrides the gradient colours of `aurora` and `flame`. */
  borderColors?: readonly string[];
  /** One animation cycle in milliseconds; overrides the effect's token. */
  borderDuration?: number;
}

// Decision 0010: cards must not contain cards.
const KCardDepth = createContext(false);

export function KCard({
  children,
  className,
  elevation = "none",
  tone = "raised",
  leading,
  title,
  description,
  menu,
  menuLabel = "More actions",
  actions,
  border = "none",
  borderColor,
  borderColors,
  borderDuration,
  style,
  ...props
}: KCardProps) {
  const classes = [
    "k-card",
    border !== "none" ? `k-card--border k-card--border-${border}` : "",
    title || description || leading || menu?.length || actions
      ? "k-card--structured"
      : "",
    className,
  ]
    .filter(Boolean)
    .join(" ");
  const borderStyle: Record<string, string> = {};
  if (borderColor) borderStyle["--k-card-border-color"] = borderColor;
  if (borderDuration)
    borderStyle["--k-card-border-duration"] = `${borderDuration}ms`;
  if (borderColors?.length) {
    const ring = [...borderColors, borderColors[0]].join(", ");
    borderStyle["--k-card-border-gradient"] = ring;
  }
  const header =
    title || description || leading || menu?.length ? (
      <div className="k-card__header">
        {leading ? <div className="k-card__leading">{leading}</div> : null}
        <div className="k-card__heading">
          {title ? (
            <KText as="div" variant="label" className="k-card__title">
              {title}
            </KText>
          ) : null}
          {description ? (
            <KText as="div" variant="caption" className="k-card__description">
              {description}
            </KText>
          ) : null}
        </div>
        {menu?.length ? (
          <KMenuButton
            overflow
            label={menuLabel}
            actions={menu}
            align="end"
            triggerClassName="k-card__menu"
          />
        ) : null}
      </div>
    ) : null;
  const nested = useContext(KCardDepth);
  useEffect(() => {
    if (nested)
      console.error(
        "Nested KCard (Decision 0010): a card must not contain another card. Use separators, a grouped list or a KStack section inside the card, or make it a sibling card.",
      );
  }, [nested]);

  return (
    <KSurface
      as="article"
      className={classes}
      elevation={elevation}
      radius="card"
      tone={tone}
      data-nested-card={nested ? "" : undefined}
      style={{ ...(style as CSSProperties), ...borderStyle } as CSSProperties}
      {...props}
    >
      <KCardDepth.Provider value>
        {header}
        {children}
        {actions ? <div className="k-card__actions">{actions}</div> : null}
      </KCardDepth.Provider>
    </KSurface>
  );
}
