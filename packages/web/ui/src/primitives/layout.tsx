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
