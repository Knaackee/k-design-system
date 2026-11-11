import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

const css = readFileSync(
  new URL("../src/editors/markdown-editor-fullscreen.css", import.meta.url),
  "utf8",
);
const rules = [...css.matchAll(/([^{}]+)\{([^{}]*)\}/g)];

test("floating-button bottom clearance belongs to scrollable document content, never the viewport", () => {
  const clearanceRules = rules.filter(([, , body]) =>
    /padding-(?:block-end|bottom)\s*:\s*var\(--k-markdown-editor-expand-clearance\)/.test(
      body,
    ),
  );
  assert.ok(
    clearanceRules.length,
    "the final document line needs scrollable clearance",
  );
  const selectors = clearanceRules.flatMap(([, selector]) =>
    selector
      .replace(/\/\*[\s\S]*?\*\//g, "")
      .split(/,(?![^()]*\))/)
      .map((part) => part.trim()),
  );
  assert.equal(
    selectors.length,
    3,
    "source, preview and rich documents all need clearance",
  );
  for (const selector of selectors) {
    assert.match(
      selector,
      /(?:\.cm-content|\.k-markdown-editor-preview|:is\(\.k-markdown-editor-content,\s*\.ProseMirror\))$/,
    );
    assert.match(
      selector,
      /\[data-has-expand-action="true"\]/,
      "ordinary editors keep their existing padding",
    );
  }
  const floating = rules.find(
    ([, selector]) => selector.trim() === ".k-markdown-editor-expand-action",
  );
  assert.ok(floating);
  assert.match(floating[2], /position:\s*absolute/);
  assert.doesNotMatch(
    floating[2],
    /(?:padding|height|flex|order)\s*:/,
    "the floating action must not reserve a footer row",
  );
});
