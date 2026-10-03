import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KInput } from "../dist/forms/input.js";
import { KTextarea } from "../dist/forms/textarea.js";
import {
  KDictationAction,
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
