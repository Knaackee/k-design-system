import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KInput } from "../dist/forms/input.js";
import { KTextarea } from "../dist/forms/textarea.js";
import {
  KDictationAction,
  KDictationAnchor,
  KDictationState,
} from "../dist/forms/dictation-action.js";

const action = (state = KDictationState.ready) =>
  h(KDictationAction, {
    state,
    label: "Dictate notes",
    onPressed: () => undefined,
  });

test("dictation has accessible states and never submits a form", () => {
  for (const state of Object.values(KDictationState)) {
    const html = renderToStaticMarkup(action(state));
    assert.match(html, /type="button"/);
    assert.match(html, /aria-label="Dictate notes"/);
    assert.equal(
      /disabled=""/.test(html),
      ["processing", "unavailable"].includes(state),
    );
    assert.equal(/aria-pressed="true"/.test(html), state === "recording");
    if (state === "processing") assert.match(html, /aria-busy="true"/);
  }
});

test("input clear and dictation coexist; protected inputs remove the action", () => {
  const html = renderToStaticMarkup(
    h(KInput, {
      defaultValue: "Roof",
      clearable: true,
      clearLabel: "Clear title",
      trailingAction: action(),
    }),
  );
  assert.match(html, /aria-label="Clear title"/);
  assert.match(html, /aria-label="Dictate notes"/);
  assert.match(html, /data-trailing-action="true"/);
  for (const lock of [
    { disabled: true },
    { readOnly: true },
    { type: "password" },
  ]) {
    assert.doesNotMatch(
      renderToStaticMarkup(h(KInput, { ...lock, trailingAction: action() })),
      /Dictate notes/,
    );
  }
});

test("textarea keeps form attributes and gates the bottom action", () => {
  const html = renderToStaticMarkup(
    h(KTextarea, { name: "notes", rows: 3, trailingAction: action() }),
  );
  assert.match(html, /name="notes"/);
  assert.match(html, /rows="3"/);
  assert.match(html, /k-textarea-trailing-action/);
  for (const lock of [{ disabled: true }, { readOnly: true }]) {
    assert.doesNotMatch(
      renderToStaticMarkup(h(KTextarea, { ...lock, trailingAction: action() })),
      /Dictate notes/,
    );
  }
});

test("saved-caret feedback is decorative and never becomes input text", () => {
  for (const state of Object.values(KDictationState)) {
    const active = state === "recording" || state === "processing";
    for (const Field of [KInput, KTextarea]) {
      const html = renderToStaticMarkup(
        h(Field, {
          defaultValue: "Keep this",
          dictationState: state,
          dictationOffset: 4,
        }),
      );
      assert.equal(html.includes('class="k-dictation-anchor"'), active);
      assert.match(html, /Keep this/);
      assert.doesNotMatch(html, /dictationOffset=|dictationState=/);
      if (active) assert.match(html, /aria-hidden="true"/);
    }
  }
  const html = renderToStaticMarkup(
    h(KDictationAnchor, { state: KDictationState.recording }),
  );
  assert.equal((html.match(/--k-dictation-dot-index:/g) ?? []).length, 3);
  assert.doesNotMatch(html, /role=|tabindex=/);
});
test("protected text removes saved-caret feedback", () => {
  for (const lock of [
    { disabled: true },
    { readOnly: true },
    { type: "password" },
  ]) {
    assert.doesNotMatch(
      renderToStaticMarkup(
        h(KInput, { ...lock, dictationState: KDictationState.recording }),
      ),
      /k-dictation-anchor/,
    );
  }
  for (const lock of [{ disabled: true }, { readOnly: true }]) {
    assert.doesNotMatch(
      renderToStaticMarkup(
        h(KTextarea, { ...lock, dictationState: KDictationState.processing }),
      ),
      /k-dictation-anchor/,
    );
  }
});

test("recording wave uses only supplied level and clamps its range", () => {
  const render = (audioLevel) =>
    renderToStaticMarkup(
      h(KDictationAction, {
        state: KDictationState.recording,
        label: "Stop dictation",
        onPressed() {},
        audioLevel,
      }),
    );
  const low = render(0);
  const high = render(1);
  assert.match(high, /k-dictation-wave/);
  assert.match(high, /scaleY\(1\)/);
  assert.match(low, /scaleY\(0.3\)/);
  assert.equal(render(-3), low);
  assert.equal(render(3), high);
  assert.equal(render(NaN), low);
  assert.doesNotMatch(render(undefined), /data-audio-level=/);
});

test("dictation can render its label without icon-button sizing", () => {
  const html = renderToStaticMarkup(
    h(KDictationAction, {
      state: KDictationState.recording,
      label: "Stop recording",
      showLabel: true,
      onPressed() {},
    }),
  );
  assert.match(html, />Stop recording</);
  assert.doesNotMatch(html, /k-icon-button/);
  assert.match(html, /k-dictation-wave/);
  const idle = renderToStaticMarkup(
    h(KDictationAction, {
      state: KDictationState.ready,
      label: "Record voice",
      showLabel: true,
      onPressed() {},
    }),
  );
  assert.match(idle, /k-button--secondary/);
});
