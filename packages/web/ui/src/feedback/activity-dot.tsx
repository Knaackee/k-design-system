import type { CSSProperties, HTMLAttributes } from "react";

export type KActivityDotState = "idle" | "working" | "question" | "error";
export type KActivityDotAnimation = "auto" | "none" | "spin" | "pulse";

type ActivityDotStyle = CSSProperties & {
  "--k-activity-dot-size"?: string;
  "--k-activity-dot-core-size"?: string;
  "--k-activity-dot-ring-width"?: string;
  "--k-activity-dot-color"?: string;
  "--k-activity-dot-ring-color"?: string;
  "--k-activity-dot-ring-track-color"?: string;
  "--k-activity-dot-animation-duration"?: string;
  "--k-activity-dot-animation-timing"?: string;
  "--k-activity-dot-animation-iteration-count"?: string | number;
};

export interface KActivityDotProps extends Omit<
  HTMLAttributes<HTMLSpanElement>,
  "children" | "color"
> {
  state?: KActivityDotState;
  /** Adds an accessible name. Omit for a decorative indicator. */
  label?: string;
  /** Any CSS size value, including a design token variable. */
  size?: string;
  coreSize?: string;
  ringWidth?: string;
  dotColor?: string;
  ringColor?: string;
  ringTrackColor?: string;
  animation?: KActivityDotAnimation;
  animationDuration?: string;
  animationTimingFunction?: string;
  animationIterationCount?: number | "infinite";
  /** Stops motion independently of the operating-system preference. */
  reducedMotion?: boolean;
}

const stateAnimation: Record<KActivityDotState, KActivityDotAnimation> = {
  idle: "none",
  working: "spin",
  question: "pulse",
  error: "none",
};

/** Compact state marker with consumer-controlled color and motion. */
export function KActivityDot({
  state = "idle",
  label,
  size,
  coreSize,
  ringWidth,
  dotColor,
  ringColor,
  ringTrackColor,
  animation = "auto",
  animationDuration,
  animationTimingFunction,
  animationIterationCount,
  reducedMotion = false,
  className,
  style,
  ...props
}: KActivityDotProps) {
  const resolvedAnimation =
    reducedMotion || animation === "none"
      ? "none"
      : animation === "auto"
        ? stateAnimation[state]
        : animation;
  const activityStyle: ActivityDotStyle = {
    "--k-activity-dot-size": size,
    "--k-activity-dot-core-size": coreSize,
    "--k-activity-dot-ring-width": ringWidth,
    "--k-activity-dot-color": dotColor,
    "--k-activity-dot-ring-color": ringColor,
    "--k-activity-dot-ring-track-color": ringTrackColor,
    "--k-activity-dot-animation-duration": animationDuration,
    "--k-activity-dot-animation-timing": animationTimingFunction,
    "--k-activity-dot-animation-iteration-count": animationIterationCount,
    ...style,
  };

  return (
    <span
      {...props}
      className={["k-activity-dot", className].filter(Boolean).join(" ")}
      data-state={state}
      data-animation={resolvedAnimation}
      role={label ? "img" : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
      style={activityStyle}
    >
      <span className="k-activity-dot__ring" aria-hidden="true" />
      <span className="k-activity-dot__core" aria-hidden="true" />
    </span>
  );
}
