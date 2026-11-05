import assert from "node:assert/strict";
import test from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KRadioGroup } from "./dist/forms/radio-group.js";

test("segmented selection preserves native radio form and disabled semantics", () => {
  const html = renderToStaticMarkup(
    createElement(KRadioGroup, {
      label: "Status",
      appearance: "segmented",
      name: "status",
      value: "active",
      required: true,
      onValueChange: () => {},
      items: [
        { value: "draft", label: "Draft" },
        { value: "active", label: "Active" },
        { value: "archived", label: "Archived", disabled: true },
      ],
    }),
  );
  assert.match(html, /data-appearance="segmented"/);
  assert.equal((html.match(/type="radio"/g) ?? []).length, 3);
  assert.equal((html.match(/name="status"/g) ?? []).length, 3);
  assert.equal((html.match(/checked=""/g) ?? []).length, 1);
  assert.match(html, /checked=""[^>]*value="active"/);
  assert.match(html, /disabled=""[^>]*value="archived"/);
  assert.match(html, /<legend>Status<\/legend>/);
});

test("default appearance and read-only groups remain unchanged", () => {
  const html = renderToStaticMarkup(
    createElement(KRadioGroup, {
      label: "Status",
      value: null,
      items: [{ value: "draft", label: "Draft" }],
    }),
  );
  assert.match(html, /data-appearance="radio"/);
  assert.match(html, /<fieldset[^>]*disabled=""/);
  assert.doesNotMatch(html, /checked=""/);
});
