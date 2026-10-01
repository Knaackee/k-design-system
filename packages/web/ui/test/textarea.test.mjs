import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KField } from "../dist/forms/field.js";
import { KTextarea } from "../dist/forms/textarea.js";

test("textarea preserves native form data and accessible field state", () => {
  const html = renderToStaticMarkup(
    h(
      KField,
      { label: "Notes", required: true, errorText: "Check the notes." },
      h(KTextarea, {
        name: "notes",
        defaultValue: "Roof\nWalls",
        maxLength: 240,
      }),
    ),
  );
  assert.match(html, /<textarea[^>]*name="notes"/);
  assert.match(html, /required=""/);
  assert.match(html, /aria-invalid="true"/);
  const description = html.match(/aria-describedby="([^"]+)"/)[1];
  assert.ok(html.includes(`id="${description}"`));
  assert.match(html, /rows="4"/);
  assert.match(html, /maxLength="240"/);
  assert.match(html, /Roof\nWalls<\/textarea>/);
  const locked = renderToStaticMarkup(
    h(KTextarea, { readOnly: true, disabled: true, rows: 2 }),
  );
  assert.match(locked, /readOnly=""/);
  assert.match(locked, /disabled=""/);
  assert.match(locked, /rows="2"/);
});
