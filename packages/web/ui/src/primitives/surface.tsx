import { createElement, type HTMLAttributes, type ReactNode } from "react";

export type KSurfaceTone = "canvas" | "raised" | "subtle" | "overlay";
export type KSurfaceBorder = "none" | "default" | "strong";
export type KSurfaceRadius =
  | "none"
  | "small"
  | "medium"
  | "large"
  | "extraLarge"
  | "card"
  | "overlay"
  | "full";
export type KSurfaceElevation = "none" | "low" | "medium" | "overlay";
export type KSurfaceElement = "div" | "section" | "article" | "aside";

export interface KSurfaceProps extends HTMLAttributes<HTMLElement> {
  as?: KSurfaceElement;
  border?: KSurfaceBorder;
  children: ReactNode;
  elevation?: KSurfaceElevation;
  radius?: KSurfaceRadius;
  tone?: KSurfaceTone;
}

const radiusClasses: Record<KSurfaceRadius, string> = {
  none: "none",
  small: "small",
  medium: "medium",
  large: "large",
  extraLarge: "extra-large",
  card: "card",
  overlay: "overlay",
  full: "full",
};

export function KSurface({
  as = "div",
  border = "default",
  children,
  className,
  elevation = "none",
  radius = "medium",
  tone = "raised",
  ...props
}: KSurfaceProps) {
  const classes = [
    "k-surface",
    `k-surface--tone-${tone}`,
    `k-surface--border-${border}`,
    `k-surface--radius-${radiusClasses[radius]}`,
    `k-surface--elevation-${elevation}`,
    className,
  ]
    .filter(Boolean)
    .join(" ");

  return createElement(
    as,
    {
      ...props,
      className: classes,
      "data-border": border,
      "data-elevation": elevation,
      "data-radius": radius,
      "data-tone": tone,
    },
    children,
  );
}
