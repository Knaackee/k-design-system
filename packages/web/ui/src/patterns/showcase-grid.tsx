import type { CSSProperties, HTMLAttributes, ReactNode } from "react";

export interface KShowcaseGridItem {
  id: string;
  content: ReactNode;
}

export interface KShowcaseGridProps extends HTMLAttributes<HTMLDivElement> {
  /** Decorative previews. Interactive descendants are intentionally inert. */
  items: readonly KShowcaseGridItem[];
  /** Foreground content remains accessible and interactive. */
  children?: ReactNode;
  columns?: number;
  compactColumns?: number;
  tilt?: number;
  gap?: CSSProperties["gap"];
  animate?: boolean;
  durationMs?: number;
  staggerMs?: number;
  edgeFade?: boolean;
  loop?: boolean;
  loopDurationMs?: number;
}

/** A decorative, once-entering wall of arbitrary previews, with an optional foreground. */
export function KShowcaseGrid({
  items,
  children,
  columns = 4,
  compactColumns = 2,
  tilt = -8,
  gap = "var(--k-space-layout-section-gap)",
  animate = true,
  durationMs = 900,
  staggerMs = 90,
  edgeFade = true,
  loop = false,
  loopDurationMs = 45000,
  className = "",
  style,
  ...props
}: KShowcaseGridProps) {
  const count = (value: number) =>
    Math.max(1, Math.min(12, Math.round(value) || 1));
  const milliseconds = (value: number, fallback: number) =>
    Number.isFinite(value) ? Math.max(0, value) : fallback;
  const variables = {
    "--k-showcase-columns": count(columns),
    "--k-showcase-compact-columns": count(compactColumns),
    "--k-showcase-tilt": `${Number.isFinite(tilt) ? tilt : -8}deg`,
    "--k-showcase-gap": typeof gap === "number" ? `${gap}px` : gap,
    "--k-showcase-duration": `${milliseconds(durationMs, 900)}ms`,
    "--k-showcase-loop-duration": `${Math.max(1000, milliseconds(loopDurationMs, 45000))}ms`,
    ...style,
  } as CSSProperties;

  return (
    <div
      {...props}
      className={`k-showcase-grid ${className}`}
      style={variables}
    >
      <div
        className="k-showcase-grid__backdrop"
        aria-hidden="true"
        inert
        data-fade={edgeFade}
        data-loop={loop}
      >
        <div
          className="k-showcase-grid__plane"
          data-animate={animate}
          data-loop={loop}
        >
          <div className="k-showcase-grid__track">
            {Array.from({ length: loop ? 2 : 1 }, (_, copy) => (
              <div className="k-showcase-grid__group" key={copy}>
                {items.map((item, index) => (
                  <div
                    className="k-showcase-grid__item"
                    key={item.id}
                    style={
                      {
                        "--k-showcase-delay": `${Math.min(index, 11) * milliseconds(staggerMs, 90)}ms`,
                      } as CSSProperties
                    }
                  >
                    {item.content}
                  </div>
                ))}
              </div>
            ))}
          </div>
        </div>
      </div>
      {children != null && (
        <div className="k-showcase-grid__foreground">{children}</div>
      )}
    </div>
  );
}
