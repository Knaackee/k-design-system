import { useLayoutEffect, useRef, type ReactNode } from "react";
import { KIconButton } from "../actions/icon-button.js";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";

export type KCallBarProps = {
  name: ReactNode;
  status: string;
  duration: string;
  muted: boolean;
  /** Measured raw PCM microphone amplitude, normalized to 0..1. */
  microphoneLevel: number;
  onMutedChange: (muted: boolean) => void;
  muteDisabled?: boolean;
  className?: string;
  /** Expanded call view or compact strip; lifecycle remains consumer controlled. */
  expanded?: boolean;
  avatar?: ReactNode;
  /** Bounds of the chat character when opening a call. */
  avatarOrigin?: DOMRect | null;
  onExpandedChange?: (expanded: boolean) => void;
  onEndCall?: () => void;
  labels?: {
    region?: string;
    duration?: string;
    mute?: string;
    unmute?: string;
    minimize?: string;
    expand?: string;
    end?: string;
  };
};

/** Session lifecycle, elapsed time, and measured audio remain consumer owned. */
export function KCallBar({
  name,
  status,
  duration,
  muted,
  microphoneLevel,
  onMutedChange,
  muteDisabled,
  className,
  labels,
  expanded = false,
  avatar,
  avatarOrigin,
  onExpandedChange,
  onEndCall,
}: KCallBarProps) {
  const avatarRef = useRef<HTMLDivElement>(null);
  const previousBounds = useRef<DOMRect | null>(null);
  useLayoutEffect(() => {
    const element = avatarRef.current;
    if (!element) return;
    const to = element.getBoundingClientRect();
    const from = previousBounds.current ?? avatarOrigin;
    previousBounds.current = to;
    if (
      !expanded ||
      !from ||
      !to.width ||
      !to.height ||
      typeof element.animate !== "function" ||
      window.matchMedia?.("(prefers-reduced-motion: reduce)").matches
    )
      return;
    const animation = element.animate(
      [
        {
          transform: `translate(${from.x - to.x}px, ${from.y - to.y}px) scale(${from.width / to.width}, ${from.height / to.height})`,
        },
        { transform: "translate(0, 0) scale(1)" },
      ],
      { duration: 900, easing: "cubic-bezier(.22, 1, .36, 1)" },
    );
    return () => animation.cancel();
  }, [expanded]);
  const amplitude =
    muted || !Number.isFinite(microphoneLevel)
      ? 0
      : Math.max(0, Math.min(1, microphoneLevel));
  const level =
    amplitude === 0
      ? 0
      : Math.max(0, Math.min(1, (20 * Math.log10(amplitude) + 60) / 60));
  return (
    <div
      className={`k-call-bar ${className ?? ""}`}
      role="region"
      aria-label={labels?.region ?? "Call"}
      data-expanded={expanded}
      onClick={(event) => {
        if (
          !expanded &&
          onExpandedChange &&
          !(event.target as HTMLElement).closest("button")
        )
          onExpandedChange(true);
      }}
    >
      {expanded && onExpandedChange ? (
        <div className="k-call-bar__minimize">
          <KButton
            variant="ghost"
            aria-label={labels?.minimize ?? "Minimize call"}
            onClick={() => onExpandedChange(false)}
          >
            <KIcon name="chevron-down" color="currentColor" />
            {labels?.minimize ?? "Back to chat"}
          </KButton>
        </div>
      ) : null}
      {avatar ? (
        <div ref={avatarRef} className="k-call-bar__avatar" aria-hidden="true">
          {avatar}
        </div>
      ) : null}
      <div className="k-call-bar__identity">
        {onExpandedChange && !expanded ? (
          <button
            type="button"
            className="k-call-bar__expand"
            aria-label={labels?.expand ?? "Return to call"}
            onClick={() => onExpandedChange(true)}
          >
            <strong>{name}</strong>
            <span aria-live="polite">{status}</span>
            <span className="k-call-bar__expand-hint">
              {labels?.expand ?? "Return to call"}
            </span>
          </button>
        ) : (
          <>
            <strong>{name}</strong>
            <p aria-live="polite">{status}</p>
          </>
        )}
      </div>
      <span
        className="k-call-bar__waveform"
        data-muted={muted}
        aria-hidden="true"
      >
        {Array.from({ length: 25 }, (_, index) => (
          <span
            key={index}
            style={{
              height: `${3 + 21 * level * (0.3 + 0.7 * Math.abs(Math.sin(index * 1.7)))}px`,
            }}
          />
        ))}
      </span>
      <span
        className="k-call-bar__duration"
        role="timer"
        aria-label={labels?.duration ?? "Call duration"}
      >
        {duration}
      </span>
      <div className="k-call-bar__controls">
        <KIconButton
          icon={muted ? "mic-off" : "mic"}
          label={
            muted
              ? (labels?.unmute ?? "Unmute microphone")
              : (labels?.mute ?? "Mute microphone")
          }
          variant="ghost"
          aria-pressed={muted}
          disabled={muteDisabled}
          onClick={() => onMutedChange(!muted)}
        />
        {onEndCall ? (
          <KIconButton
            icon="phone-off"
            label={labels?.end ?? "End call"}
            className="k-call-bar__end"
            onClick={onEndCall}
          />
        ) : null}
      </div>
    </div>
  );
}
