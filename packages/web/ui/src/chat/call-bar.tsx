import type { ReactNode } from "react";
import { KIconButton } from "../actions/icon-button.js";

export type KCallBarProps = {
  name: ReactNode;
  status: string;
  duration: string;
  muted: boolean;
  /** Measured microphone amplitude, normalized to 0..1. */
  microphoneLevel: number;
  onMutedChange: (muted: boolean) => void;
  muteDisabled?: boolean;
  className?: string;
  labels?: {
    region?: string;
    duration?: string;
    mute?: string;
    unmute?: string;
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
}: KCallBarProps) {
  const level =
    muted || !Number.isFinite(microphoneLevel)
      ? 0
      : Math.max(0, Math.min(1, microphoneLevel));
  return (
    <div
      className={`k-call-bar ${className ?? ""}`}
      role="region"
      aria-label={labels?.region ?? "Call"}
    >
      <div className="k-call-bar__identity">
        <strong>{name}</strong>
        <p aria-live="polite">{status}</p>
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
    </div>
  );
}
