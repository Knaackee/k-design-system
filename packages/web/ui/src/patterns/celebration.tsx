import type { CSSProperties, HTMLAttributes, ReactNode } from "react";

export interface KCelebrationProps extends HTMLAttributes<HTMLDivElement> {
  children: ReactNode;
  /** Play once when mounted active; remount to replay deliberately. */
  active?: boolean;
  durationMs?: number;
  particleCount?: number;
  colors?: readonly string[];
}

/** Decorative, non-blocking success accent around consumer-owned content. */
export function KCelebration({
  children,
  active = false,
  durationMs = 1100,
  particleCount = 24,
  colors = [
    "var(--k-color-action-primary-background)",
    "var(--k-color-border-focus)",
    "var(--k-color-text-muted)",
  ],
  className = "",
  style,
  ...props
}: KCelebrationProps) {
  const count = Math.max(0, Math.min(60, Math.floor(particleCount)));
  return (
    <div
      {...props}
      className={`k-celebration ${className}`}
      data-active={active}
      style={
        {
          ...style,
          "--k-celebration-duration": `${Math.max(0, durationMs)}ms`,
        } as CSSProperties
      }
    >
      {active && (
        <div className="k-celebration__particles" aria-hidden="true">
          {Array.from({ length: count }, (_, index) => {
            const angle = index * 2.39996;
            const radius = 76 + (index % 5) * 20;
            return (
              <span
                key={index}
                style={
                  {
                    "--particle-x": `${Math.cos(angle) * radius}px`,
                    "--particle-y": `${Math.sin(angle) * radius - 28}px`,
                    "--particle-turn": `${index % 2 ? 210 : -180}deg`,
                    background: colors[index % colors.length] || "currentColor",
                    animationDelay: `${(index % 4) * 25}ms`,
                  } as CSSProperties
                }
              />
            );
          })}
        </div>
      )}
      <div className="k-celebration__content">{children}</div>
    </div>
  );
}
