import type { CSSProperties } from "react";
export interface KProgressDotsProps {
  count: number;
  activeIndex: number;
  label?: string;
  dotSize?: number;
  activeWidth?: number;
  gap?: number;
  className?: string;
  style?: CSSProperties;
}
/** Passive step progress; navigation remains owned by the consumer. */
export function KProgressDots({
  count,
  activeIndex,
  label = "Progress",
  dotSize = 6,
  activeWidth = 20,
  gap = 12,
  className,
  style,
}: KProgressDotsProps) {
  const total = Math.max(0, Math.floor(count));
  if (!total) return null;
  const current = Math.max(0, Math.min(total - 1, activeIndex));
  return (
    <div
      role="progressbar"
      aria-label={label}
      aria-valuemin={1}
      aria-valuemax={total}
      aria-valuenow={current + 1}
      className={["k-progress-dots", className].filter(Boolean).join(" ")}
      style={{ ...style, gap }}
    >
      {Array.from({ length: total }, (_, i) => (
        <span
          key={i}
          aria-hidden="true"
          data-active={i === current || undefined}
          style={{
            width: i === current ? activeWidth : dotSize,
            height: dotSize,
          }}
        />
      ))}
    </div>
  );
}
