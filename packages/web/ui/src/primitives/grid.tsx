import type { CSSProperties, HTMLAttributes } from "react";
import type { KLayoutGap } from "./layout.js";
export interface KGridProps extends HTMLAttributes<HTMLDivElement> {
  minColumnWidth?: number;
  /** Omit for automatic responsive columns. */
  columns?: number;
  gap?: KLayoutGap;
}
/** Equal-width columns derived from parent width, not viewport width. */
export function KGrid({
  minColumnWidth = 240,
  columns,
  gap = "section",
  className = "",
  style,
  ...props
}: KGridProps) {
  if (!Number.isFinite(minColumnWidth) || minColumnWidth <= 0)
    throw new RangeError("KGrid minColumnWidth must be positive and finite");
  if (columns !== undefined && (!Number.isInteger(columns) || columns < 1))
    throw new RangeError("KGrid columns must be a positive integer");
  return (
    <div
      {...props}
      className={`k-grid k-layout--gap-${gap} ${className}`}
      style={
        {
          ...style,
          ...(columns === undefined
            ? {}
            : { gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))` }),
          "--k-grid-min-column": `${minColumnWidth}px`,
        } as CSSProperties
      }
    />
  );
}
