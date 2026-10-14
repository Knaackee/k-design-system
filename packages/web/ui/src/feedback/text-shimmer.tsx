import type { CSSProperties } from "react";

/** Decorative activity on existing text; the consumer owns the status label. */
export function KTextShimmer({
  text,
  active = false,
  color,
  label,
}: {
  text: string;
  active?: boolean;
  color?: string;
  label?: string;
}) {
  return (
    <span
      className="k-text-shimmer"
      data-active={active || undefined}
      aria-label={label}
      style={
        color
          ? ({ "--k-text-shimmer-color": color } as CSSProperties)
          : undefined
      }
    >
      {text}
    </span>
  );
}
