import type { CSSProperties } from "react";
import { KIconButton } from "../actions/icon-button.js";

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
}

/** Presentation only. Consumers own recording, permission and transcription. */
export function KDictationAction({
  state,
  label,
  onPressed,
}: KDictationActionProps) {
  const icon = {
    ready: "mic",
    recording: "square",
    processing: "loader-circle",
    unavailable: "mic-off",
    error: "circle-alert",
  } as const;
  return (
    <KIconButton
      className="k-dictation-action"
      data-dictation-state={state}
      label={label}
      icon={icon[state]}
      variant={state === KDictationState.recording ? "primary" : "ghost"}
      disabled={
        !onPressed ||
        state === KDictationState.processing ||
        state === KDictationState.unavailable
      }
      aria-pressed={state === KDictationState.recording}
      loading={state === KDictationState.processing}
      onClick={onPressed}
    />
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
