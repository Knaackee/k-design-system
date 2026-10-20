import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KDictationState } from "../dist/forms/dictation-action.js";
import { KChatComposer } from "../dist/chat/composer.js";

const render = (props = {}) =>
  renderToStaticMarkup(
    h(KChatComposer, {
      value: "Draft",
      onValueChange() {},
      onSubmit() {},
      onAttach() {},
      onVoiceInput() {},
      ...props,
    }),
  );

test("waveform distinguishes quiet speech from silence without invalid geometry", () => {
  const html = render({
    voiceState: KDictationState.recording,
    voiceCapture: {
      samples: [0, 0.03, Number.NaN],
      onCancel() {},
      onSend() {},
    },
  });
  const tops = [...html.matchAll(/<line[^>]*y1="([^"]+)"/g)].map((match) =>
    Number(match[1]),
  );
  assert.equal(tops.length, 80);
  assert.equal(tops[0], 19);
  assert.ok(
    tops[1] < 10,
    "quiet speech should have a clearly visible amplitude",
  );
  assert.equal(tops[2], 19);
});

test("composer places microphone directly before primary Send and keeps attachments left", () => {
  const html = render();
  const labels = [...html.matchAll(/aria-label="([^"]+)"/g)].map(
    (match) => match[1],
  );
  assert.deepEqual(labels, [
    "Attach files",
    "Start voice input",
    "Send message",
  ]);
  assert.match(
    html,
    /aria-label="Send message"[^>]*class="[^"]*k-button--primary/,
  );
  assert.match(html, /type="submit"/);
});

test("optional voice is selected, disabled with composer, and remains next to Stop", () => {
  assert.match(render({ voiceActive: true }), /aria-pressed="true"/);
  const html = render({ disabled: true });
  assert.match(html, /aria-label="Start voice input"[^>]*disabled=""/);
  assert.doesNotMatch(render({ onVoiceInput: undefined }), /voice input/);
  const labels = [
    ...render({ runState: "streaming", onStop() {} }).matchAll(
      /aria-label="([^"]+)"/g,
    ),
  ].map((match) => match[1]);
  assert.deepEqual(labels.slice(-2), ["Start voice input", "Stop response"]);
});

test("active voice remains stoppable while the composer is disabled", () => {
  const html = render({ disabled: true, voiceActive: true });
  const stopVoice = html.match(
    /<button[^>]*aria-label="Stop voice input"[^>]*>/,
  )?.[0];
  assert.ok(stopVoice);
  assert.doesNotMatch(stopVoice, /disabled=/);
  assert.match(html, /<textarea[^>]*disabled=""/);
  assert.match(html, /aria-label="Send message"[^>]*disabled=""/);
});

test("composer renders the shared dictation action and explicit states", () => {
  const html = render({
    voiceState: KDictationState.recording,
    voiceAudioLevel: 0.5,
    disabled: true,
  });
  assert.match(html, /k-dictation-action/);
  assert.match(html, /k-dictation-wave/);
  assert.match(html, /aria-label="Stop voice input"/);
  assert.match(
    render({ voiceState: KDictationState.processing }),
    /aria-label="Transcribing voice input"[^>]*disabled=""/,
  );
  assert.match(
    render({ voiceState: KDictationState.error }),
    /aria-label="Retry voice input"/,
  );
});

test("inline recording replaces input and tools without requiring a text draft", () => {
  const html = render({
    value: "",
    voiceState: KDictationState.recording,
    voiceCapture: { samples: [0, 0.5, NaN, 9], onCancel() {}, onSend() {} },
  });
  assert.doesNotMatch(html, /<textarea/);
  assert.match(html, /k-chat-composer__wave/);
  assert.doesNotMatch(html, /NaN/);
  assert.doesNotMatch(html, /aria-label="Attach files"/);
  assert.match(html, /aria-label="Discard recording"/);
  assert.match(html, /aria-label="Stop voice input"/);
  const send = html.match(
    /<button[^>]*aria-label="Transcribe and send"[^>]*>/,
  )?.[0];
  assert.ok(send);
  assert.doesNotMatch(send, /disabled=/);
});

test("processing blocks repeated sends but remains cancellable; empty ready state offers call", () => {
  const capture = { samples: [], onCancel() {}, onSend() {} };
  const html = render({
    voiceState: KDictationState.processing,
    voiceCapture: capture,
  });
  assert.match(html, /aria-busy="true"/);
  assert.match(html, /aria-label="Transcribe and send"[^>]*disabled=""/);
  assert.doesNotMatch(
    html.match(/<button[^>]*aria-label="Discard recording"[^>]*>/)?.[0] ?? "",
    /disabled=/,
  );
  assert.match(
    render({ value: "", onStartCall() {}, voiceCapture: capture }),
    /aria-label="Start call"/,
  );
  assert.doesNotMatch(
    render({ value: "Draft", onStartCall() {}, voiceCapture: capture }),
    /aria-label="Start call"/,
  );
});
