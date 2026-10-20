import {
  useRef,
  useId,
  type FormEvent,
  type KeyboardEvent,
  type ReactNode,
} from "react";
import { KIconButton } from "../actions/icon-button.js";
import {
  KDictationAction,
  KDictationState,
} from "../forms/dictation-action.js";
import { KSelect } from "../forms/selection.js";
import type { KIconName } from "../primitives/icon.js";
import type { KChatAttachmentPart, KChatRunState } from "./types.js";
import { KAgentAttachment } from "./agent-parts.js";
import { KIcon } from "../primitives/icon.js";

export interface KChatComposerLabels {
  input: string;
  placeholder: string;
  send: string;
  stop: string;
  removeAttachment: string;
  attach: string;
  voice: string;
  stopVoice: string;
  processingVoice?: string;
  unavailableVoice?: string;
  errorVoice?: string;
  model: string;
  cancelVoice: string;
  sendVoice: string;
  call: string;
}

const defaultLabels: KChatComposerLabels = {
  input: "Message",
  placeholder: "Ask anything…",
  send: "Send message",
  stop: "Stop response",
  removeAttachment: "Remove attachment",
  attach: "Attach files",
  voice: "Start voice input",
  stopVoice: "Stop voice input",
  processingVoice: "Transcribing voice input",
  unavailableVoice: "Voice input unavailable",
  errorVoice: "Retry voice input",
  model: "Model",
  cancelVoice: "Discard recording",
  sendVoice: "Transcribe and send",
  call: "Start call",
};

export interface KChatComposerModel {
  value: string;
  label: string;
  icon?: KIconName;
  disabled?: boolean;
}

export interface KChatComposerProps {
  value: string;
  onValueChange: (value: string) => void;
  onSubmit: (value: string) => void;
  onStop?: () => void;
  runState?: KChatRunState;
  disabled?: boolean;
  /** Prevent submission independently from draft editing. */
  submitEnabled?: boolean;
  maxLength?: number;
  labels?: Partial<KChatComposerLabels>;
  leadingTools?: ReactNode;
  trailingTools?: ReactNode;
  attachments?: readonly KChatAttachmentPart[];
  onAttachmentActivate?: (attachment: KChatAttachmentPart) => void;
  onAttachmentRemove?: (attachment: KChatAttachmentPart) => void;
  onAttach?: () => void;
  onVoiceInput?: () => void;
  voiceActive?: boolean;
  voiceState?: KDictationState;
  voiceAudioLevel?: number;
  /** Opt-in inline capture. Host owns audio, draft preservation and async work. */
  voiceCapture?: {
    /** Actual normalized audio history, oldest first. Empty means silence. */
    samples: readonly number[];
    onCancel: () => void;
    onSend: () => void;
    error?: string;
  };
  onStartCall?: () => void;
  models?: readonly KChatComposerModel[];
  model?: string | null;
  onModelChange?: (model: string) => void;
}

export function KChatComposer({
  value,
  onValueChange,
  onSubmit,
  onStop,
  runState = "idle",
  disabled = false,
  submitEnabled = true,
  maxLength,
  labels: labelsInput,
  leadingTools,
  trailingTools,
  attachments = [],
  onAttachmentActivate,
  onAttachmentRemove,
  onAttach,
  onVoiceInput,
  voiceActive = false,
  voiceState,
  voiceAudioLevel,
  voiceCapture,
  onStartCall,
  models = [],
  model = null,
  onModelChange,
}: KChatComposerProps) {
  const labels = { ...defaultLabels, ...labelsInput };
  const dictationState =
    voiceState ??
    (voiceActive ? KDictationState.recording : KDictationState.ready);
  const recording = dictationState === KDictationState.recording;
  const capturing = Boolean(
    voiceCapture &&
    (recording ||
      dictationState === KDictationState.processing ||
      dictationState === KDictationState.error),
  );
  const inputId = useId();
  const captureSamples = voiceCapture?.samples.slice(-80) ?? [];
  const voiceLabel = {
    ready: labels.voice,
    recording: labels.stopVoice,
    processing: labels.processingVoice ?? "Transcribing voice input",
    unavailable: labels.unavailableVoice ?? "Voice input unavailable",
    error: labels.errorVoice ?? "Retry voice input",
  }[dictationState];
  const composing = useRef(false);
  const running = runState === "submitted" || runState === "streaming";
  const submit = (event?: FormEvent) => {
    event?.preventDefault();
    const trimmed = value.trim();
    if (!trimmed || disabled || !submitEnabled || running || capturing) return;
    onSubmit(trimmed);
  };
  const onKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key !== "Enter" || event.shiftKey || composing.current) return;
    event.preventDefault();
    submit();
  };
  return (
    <form className="k-chat-composer" onSubmit={submit}>
      {attachments.length ? (
        <div className="k-chat-composer__attachments">
          {attachments.map((attachment) => (
            <div key={attachment.id} className="k-chat-composer__attachment">
              <KAgentAttachment
                part={attachment}
                onActivate={() => onAttachmentActivate?.(attachment)}
              />
              {onAttachmentRemove ? (
                <KIconButton
                  icon="x"
                  label={`${labels.removeAttachment}: ${attachment.title}`}
                  onClick={() => onAttachmentRemove(attachment)}
                />
              ) : null}
            </div>
          ))}
        </div>
      ) : null}
      <div className="k-chat-composer__input">
        <div className="k-chat-composer__tools">
          {capturing ? (
            <KIconButton
              icon="x"
              label={labels.cancelVoice}
              onClick={voiceCapture!.onCancel}
            />
          ) : onAttach ? (
            <KIconButton
              icon={voiceCapture ? "plus" : "paperclip"}
              label={labels.attach}
              onClick={onAttach}
            />
          ) : null}
          {!capturing && leadingTools}
        </div>
        <label className="k-visually-hidden" htmlFor={inputId}>
          {labels.input}
        </label>
        {capturing ? (
          <div
            className="k-chat-composer__capture"
            aria-busy={dictationState === KDictationState.processing}
          >
            {recording ? (
              <>
                <span className="k-visually-hidden" role="status">
                  {labels.voice}
                </span>
                <svg
                  className="k-chat-composer__wave"
                  viewBox="0 0 480 40"
                  preserveAspectRatio="none"
                  aria-hidden="true"
                >
                  {Array.from({ length: 80 }, (_, index) => {
                    const sample = captureSamples[index] ?? 0;
                    // Display quiet speech on a decibel scale; audio stays unchanged.
                    const level =
                      Number.isFinite(sample) && sample > 0
                        ? Math.max(
                            0,
                            Math.min(
                              1,
                              (20 * Math.log10(Math.min(1, sample)) + 60) / 48,
                            ),
                          )
                        : 0;
                    return (
                      <line
                        key={index}
                        x1={index * 6 + 3}
                        x2={index * 6 + 3}
                        y1={20 - (1 + level * 17)}
                        y2={20 + (1 + level * 17)}
                      />
                    );
                  })}
                </svg>
              </>
            ) : (
              <span
                className="k-chat-composer__capture-status"
                role={
                  dictationState === KDictationState.error ? "alert" : "status"
                }
              >
                <KIcon
                  name={
                    dictationState === KDictationState.error
                      ? "circle-alert"
                      : "loader-circle"
                  }
                />
                {dictationState === KDictationState.error
                  ? (voiceCapture!.error ?? labels.errorVoice)
                  : labels.processingVoice}
              </span>
            )}
          </div>
        ) : (
          <textarea
            id={inputId}
            data-empty={value.length === 0}
            value={value}
            disabled={disabled}
            maxLength={maxLength}
            placeholder={labels.placeholder}
            rows={1}
            onChange={(event) => onValueChange(event.target.value)}
            onKeyDown={onKeyDown}
            onCompositionStart={() => {
              composing.current = true;
            }}
            onCompositionEnd={() => {
              composing.current = false;
            }}
          />
        )}
        <div className="k-chat-composer__tools">
          {!capturing && trailingTools}
          {capturing ? (
            <KIconButton
              icon={
                dictationState === KDictationState.error
                  ? "rotate-cw"
                  : "square"
              }
              label={
                dictationState === KDictationState.error
                  ? labels.errorVoice!
                  : labels.stopVoice
              }
              disabled={
                dictationState === KDictationState.processing || !onVoiceInput
              }
              onClick={onVoiceInput}
            />
          ) : onVoiceInput ? (
            <KDictationAction
              state={dictationState}
              label={voiceLabel}
              audioLevel={voiceAudioLevel}
              onPressed={disabled && !recording ? undefined : onVoiceInput}
            />
          ) : null}
          {capturing ? (
            <KIconButton
              icon="arrow-up"
              label={labels.sendVoice}
              variant="primary"
              disabled={!recording || disabled || !submitEnabled || running}
              onClick={voiceCapture!.onSend}
            />
          ) : running ? (
            <KIconButton
              icon="x"
              label={labels.stop}
              onClick={(event) => {
                // Stopping can synchronously replace this control with Submit.
                event.preventDefault();
                onStop?.();
              }}
            />
          ) : onStartCall && !value.trim() ? (
            <KIconButton
              icon="phone"
              label={labels.call}
              variant="primary"
              disabled={disabled}
              onClick={onStartCall}
            />
          ) : (
            <KIconButton
              icon="arrow-up"
              label={labels.send}
              variant="primary"
              disabled={!value.trim() || disabled || !submitEnabled}
              type="submit"
              onClick={() => undefined}
            />
          )}
        </div>
        {!capturing && models.length && onModelChange ? (
          <div className="k-chat-composer__model">
            <KSelect
              presentation="inline"
              options={models}
              value={model}
              onValueChange={onModelChange}
              label={labels.model}
              placeholder={labels.model}
            />
          </div>
        ) : null}
      </div>
    </form>
  );
}
