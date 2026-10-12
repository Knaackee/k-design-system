import type { CSSProperties, ReactNode } from "react";

export type KAgentCursorState = "pointing" | "clicking";
export interface KAgentCursorProps {
  state?: KAgentCursorState;
  visible?: boolean;
  size?: number;
  avatar?: ReactNode;
  label?: string;
  glowEnabled?: boolean;
  /** Halo strength from 0 to 1. */
  glowIntensity?: number;
  glowColor?: string;
}

/** Decorative cursor. Its parent's origin is the arrow tip; the consumer owns position. */
export function KAgentCursor({
  state = "pointing",
  visible = true,
  size = 32,
  avatar,
  label,
  glowEnabled = true,
  glowIntensity = 1,
  glowColor,
}: KAgentCursorProps) {
  if (!visible) return null;
  return (
    <span
      className="k-agent-cursor"
      aria-hidden="true"
      data-state={state}
      data-glow={glowEnabled && glowIntensity > 0 ? "enabled" : "disabled"}
      style={
        {
          "--k-agent-cursor-size": `${size}px`,
          "--k-agent-cursor-glow-intensity": Math.max(
            0,
            Math.min(1, glowIntensity),
          ),
          ...(glowColor ? { "--k-agent-cursor-glow": glowColor } : {}),
        } as CSSProperties
      }
    >
      <svg
        className="k-agent-cursor__arrow"
        width={size}
        height={size}
        viewBox="0 0 32 32"
        overflow="visible"
        focusable="false"
      >
        {state === "clicking" && (
          <circle className="k-agent-cursor__ring" cx="0" cy="0" r="8" />
        )}
        <path d="M1 .4 Q-.5 -.5 .4 1 L9 27 Q10 29 11 27 L15.5 16.5 Q15.8 15.8 16.5 15.5 L27 11 Q29 10 27 9 Z" />
      </svg>
      {(avatar != null || label) && (
        <span className="k-agent-cursor__companion">
          {avatar}
          {label && <span className="k-agent-cursor__label">{label}</span>}
        </span>
      )}
    </span>
  );
}
