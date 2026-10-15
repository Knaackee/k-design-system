import type { CSSProperties } from "react";
import { KButton } from "../primitives/button.js";
import { KIcon } from "../primitives/icon.js";

export enum KDictationState {
  ready = "ready",
  recording = "recording",
  processing = "processing",
  unavailable = "unavailable",
  error = "error",
}

export interface KDictationActionProps {
  state: KDictationState;
  label: string;
  onPressed?: () => void;
  /** Genuine consumer audio level, normalized to 0..1. No audio is sampled here. */
  audioLevel?: number;
  /** Render the visible label beside the state icon or recording wave. */
  showLabel?: boolean;
}

/** Presentation only. Consumers own recording, permission and transcription. */
export function KDictationAction({
  state,
  label,
  onPressed,
  audioLevel,
  showLabel = false,
}: KDictationActionProps) {
  const icon = {
    ready: "mic",
    recording: "square",
    processing: "loader-circle",
    unavailable: "mic-off",
    error: "circle-alert",
  } as const;
  const level =
    audioLevel === undefined
      ? undefined
      : Number.isFinite(audioLevel)
        ? Math.min(1, Math.max(0, audioLevel))
        : 0;
  return (
    <span aria-busy={state === KDictationState.processing || undefined}>
      <KButton
        className={`${showLabel ? "" : "k-icon-button "}k-dictation-action`}
        data-dictation-state={state}
        data-audio-level={level === undefined ? undefined : "provided"}
        aria-label={label}
        title={label}
        variant={
          state === KDictationState.recording
            ? "primary"
            : showLabel
              ? "secondary"
              : "ghost"
        }
        disabled={
          !onPressed ||
          state === KDictationState.processing ||
          state === KDictationState.unavailable
        }
        aria-pressed={state === KDictationState.recording}
        onClick={onPressed}
      >
        {state === KDictationState.recording ? (
          <span className="k-dictation-wave" aria-hidden="true">
            {[0.45, 0.75, 1, 0.75, 0.45].map((weight, index) => (
              <span
                key={index}
                style={{
                  transform: `scaleY(${weight * (level === undefined ? 1 : 0.3 + 0.7 * level)})`,
                }}
              />
            ))}
          </span>
        ) : (
          <KIcon name={icon[state]} color="currentColor" />
        )}
        {showLabel && <span>{label}</span>}
      </KButton>
    </span>
  );
}

/** Visual only; never inserts text or becomes a keyboard/semantic stop. */
export function KDictationAnchor({ state }: { state: KDictationState }) {
  if (
    state !== KDictationState.recording &&
    state !== KDictationState.processing
  )
    return null;
  return (
    <span
      className="k-dictation-anchor"
      data-dictation-state={state}
      aria-hidden="true"
    >
      {[0, 1, 2].map((index) => (
        <span
          key={index}
          style={{ "--k-dictation-dot-index": index } as CSSProperties}
        />
      ))}
    </span>
  );
}

/** For editor decoration APIs that require a DOM node. */
export function createKDictationAnchor(
  state: KDictationState,
  ownerDocument: Document = document,
): HTMLElement {
  const anchor = ownerDocument.createElement("span");
  anchor.className = "k-dictation-anchor";
  anchor.dataset.dictationState = state;
  anchor.setAttribute("aria-hidden", "true");
  anchor.contentEditable = "false";
  for (let index = 0; index < 3; index++) {
    const dot = ownerDocument.createElement("span");
    dot.style.setProperty("--k-dictation-dot-index", String(index));
    anchor.append(dot);
  }
  return anchor;
}
