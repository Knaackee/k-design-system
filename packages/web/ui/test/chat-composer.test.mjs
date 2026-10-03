import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
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
