import assert from "node:assert/strict";
import test from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KBackButton } from "./dist/navigation/back-button.js";

test("back button shows the chevron only and names the destination", () => {
  const html = renderToStaticMarkup(
    createElement(KBackButton, { label: "Back to Portfolios" }),
  );
  assert.match(html, /aria-label="Back to Portfolios"/);
  assert.match(html, /k-back-button/);
  assert.match(html, /m15%2018-6-6%206-6/); // chevron-left path (mask URL)
  assert.doesNotMatch(html, />Back</);
});
