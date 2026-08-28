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

export function KCard({
  children,
  className,
  elevation = "none",
  tone = "raised",
  ...props
}: KCardProps) {
  const classes = ["k-card", className].filter(Boolean).join(" ");

  return (
    <KSurface
      as="article"
      className={classes}
      elevation={elevation}
      radius="card"
      tone={tone}
      {...props}
    >
      {children}
    </KSurface>
  );
}
