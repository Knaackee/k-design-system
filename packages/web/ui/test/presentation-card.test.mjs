import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KPresentationCard } from "../dist/chat/presentations.js";

test("standard cards retain full text and an accessible compact action", () => {
  const html = renderToStaticMarkup(
    createElement(KPresentationCard, {
      title: "Backend issue",
      description: "25 events · Active today",
      action: { label: "Open issue", onClick() {} },
    }),
  );
  assert.match(html, /<h3>Backend issue<\/h3>/);
  assert.match(html, /25 events · Active today/);
  assert.match(html, /aria-label="Open issue"/);
  assert.match(html, /title="Open issue"/);
  assert.match(html, /k-icon-button/);
});

test("cover cards retain their visible action label", () => {
  const html = renderToStaticMarkup(
    createElement(KPresentationCard, {
      title: "Cover",
      variant: "cover",
      action: { label: "Discover", onClick() {} },
    }),
  );
  assert.match(html, /Discover/);
  assert.doesNotMatch(html, /k-icon-button/);
});
