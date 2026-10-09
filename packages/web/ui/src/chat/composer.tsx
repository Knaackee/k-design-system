import {
  useRef,
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
  models = [],
  model = null,
  onModelChange,
}: KChatComposerProps) {
  const labels = { ...defaultLabels, ...labelsInput };
  const dictationState =
    voiceState ??
    (voiceActive ? KDictationState.recording : KDictationState.ready);
  const recording = dictationState === KDictationState.recording;
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
    if (!trimmed || disabled || running) return;
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
          {onAttach ? (
            <KIconButton
              icon="paperclip"
              label={labels.attach}
              onClick={onAttach}
            />
          ) : null}
          {leadingTools}
        </div>
        <label className="k-visually-hidden" htmlFor="k-chat-composer-input">
          {labels.input}
        </label>
        <textarea
          id="k-chat-composer-input"
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
        <div className="k-chat-composer__tools">
          {trailingTools}
          {onVoiceInput ? (
            <KDictationAction
              state={dictationState}
              label={voiceLabel}
              audioLevel={voiceAudioLevel}
              onPressed={disabled && !recording ? undefined : onVoiceInput}
            />
          ) : null}
          {running ? (
            <KIconButton
              icon="x"
              label={labels.stop}
              onClick={(event) => {
                // Stopping can synchronously replace this control with Submit.
                event.preventDefault();
                onStop?.();
              }}
            />
          ) : (
            <KIconButton
              icon="arrow-up"
              label={labels.send}
              variant="primary"
              disabled={!value.trim() || disabled}
              type="submit"
              onClick={() => undefined}
            />
          )}
        </div>
        {models.length && onModelChange ? (
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
