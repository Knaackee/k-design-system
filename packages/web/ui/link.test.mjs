import assert from "node:assert/strict";
import test from "node:test";
import { readFileSync } from "node:fs";
import { createElement as h } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KLink } from "./dist/primitives/link.js";

test("subtle links preserve navigation semantics and keep defaults unchanged", () => {
  const subtle = renderToStaticMarkup(
    h(
      KLink,
      {
        href: "https://example.com",
        appearance: "subtle",
        target: "_blank",
        rel: "noopener noreferrer",
      },
      "Verified source",
    ),
  );
  assert.match(subtle, /k-link--subtle/);
  assert.match(subtle, /href="https:\/\/example.com"/);
  assert.match(subtle, /target="_blank"/);
  assert.match(subtle, /rel="noopener noreferrer"/);
  assert.doesNotMatch(
    renderToStaticMarkup(h(KLink, { href: "#default" }, "Default")),
    /k-link--subtle/,
  );
  const css = readFileSync(new URL("src/link.css", import.meta.url), "utf8");
  assert.match(
    css,
    /\.k-link--subtle\s*\{[^}]*color: var\(--k-color-text-muted\)[^}]*text-decoration: none/s,
  );
  assert.match(css, /\.k-link--subtle:hover\s*\{[^}]*text-decoration: none/s);
  assert.match(css, /overflow-wrap: anywhere/);
});
