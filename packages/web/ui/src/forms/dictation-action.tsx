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
