import type { HTMLAttributes } from "react";

export type KLayoutGap = "control" | "action" | "section";
export type KLayoutAlign = "start" | "center" | "end" | "stretch";

export interface KStackProps extends HTMLAttributes<HTMLDivElement> {
  gap?: KLayoutGap;
  align?: KLayoutAlign;
}

export interface KInlineProps extends KStackProps {
  wrap?: boolean;
}

export function KStack({
  gap = "control",
  align = "start",
  className = "",
  ...props
}: KStackProps) {
  return (
    <div
      {...props}
      className={`k-layout k-stack k-layout--gap-${gap} k-layout--align-${align} ${className}`}
    />
  );
}

export function KInline({
  gap = "control",
  align = "start",
  wrap = false,
  className = "",
  ...props
}: KInlineProps) {
  if (wrap && align === "stretch") {
    throw new Error("KInline does not support wrap with stretch alignment");
  }
  return (
    <div
      {...props}
      className={`k-layout k-inline k-layout--gap-${gap} k-layout--align-${align} ${wrap ? "k-inline--wrap" : ""} ${className}`}
    />
  );
}

export interface KPageProps extends HTMLAttributes<HTMLElement> {
  /**
   * `content` (default): lists, details, dashboards (`--k-layout-page-width`).
   * `form`: sign-in and single forms (`--k-layout-form-width`), centred
   * vertically when shorter than the screen.
   */
  width?: "content" | "form";
}

/**
 * The scrolling body of a screen (Decision 0015): page gutter, safe areas, a
 * readable maximum width on tablets and desktops, and section spacing
 * between children. Mirrors `KPage` in Flutter.
 */
export function KPage({
  width = "content",
  className = "",
  children,
  ...props
}: KPageProps) {
  return (
    <main {...props} className={`k-page ${className}`} data-width={width}>
      <div className="k-layout k-stack k-layout--gap-section k-layout--align-stretch k-page__body">
        {children}
      </div>
    </main>
  );
}
