import { createContext, useContext, useEffect } from "react";
import type { HTMLAttributes, ReactNode } from "react";

import {
  KSurface,
  type KSurfaceElevation,
  type KSurfaceTone,
} from "./surface.js";

export interface KCardProps extends HTMLAttributes<HTMLElement> {
  children: ReactNode;
  elevation?: KSurfaceElevation;
  tone?: KSurfaceTone;
}

// Decision 0010: cards must not contain cards.
const KCardDepth = createContext(false);

export function KCard({
  children,
  className,
  elevation = "none",
  tone = "raised",
  ...props
}: KCardProps) {
  const classes = ["k-card", className].filter(Boolean).join(" ");
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
      {...props}
    >
      <KCardDepth.Provider value>{children}</KCardDepth.Provider>
    </KSurface>
  );
}
