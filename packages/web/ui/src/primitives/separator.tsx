import type { HTMLAttributes } from "react";
export interface KSeparatorProps extends Omit<
  HTMLAttributes<HTMLDivElement>,
  "children"
> {
  orientation?: "horizontal" | "vertical";
  /** Horizontal fills available width; vertical defaults to 24px. */
  length?: number;
}
/** Decorative separation; semantic grouping belongs to surrounding content. */
export function KSeparator({
  orientation = "horizontal",
  length,
  className = "",
  style,
  ...props
}: KSeparatorProps) {
  if (length !== undefined && (!Number.isFinite(length) || length < 0))
    throw new RangeError("KSeparator length must be nonnegative and finite");
  return (
    <div
      {...props}
      aria-hidden="true"
      className={`k-separator k-separator--${orientation} ${className}`}
      style={{
        ...style,
        ...(orientation === "horizontal"
          ? { width: length ?? "100%" }
          : { height: length ?? 24 }),
      }}
    />
  );
}
