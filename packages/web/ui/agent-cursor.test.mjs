import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KAgentCursor } from "./dist/feedback/agent-cursor.js";

test("hidden cursor omits its companion", () => {
  assert.equal(
    renderToStaticMarkup(
      createElement(KAgentCursor, {
        visible: false,
        avatar: createElement("span", null, "Avatar"),
        label: "Agent",
      }),
    ),
    "",
  );
});
test("cursor excludes decorative content and passes input through", async () => {
  const html = renderToStaticMarkup(
    createElement(KAgentCursor, {
      state: "clicking",
      avatar: createElement("span", null, "Avatar"),
      label: "Agent",
    }),
  );
  assert.match(html, /aria-hidden="true"/);
  assert.match(html, /k-agent-cursor__ring/);
  assert.match(html, /Avatar/);
  assert.match(html, /Agent/);
  const css = await readFile(
    new URL("./src/agent-cursor.css", import.meta.url),
    "utf8",
  );
  assert.match(css, /pointer-events: none/);
  assert.doesNotMatch(css, /\b(?:animation|transition):/);
});

test("consumer glow controls disable and configure the halo", () => {
  const render = (props) =>
    renderToStaticMarkup(createElement(KAgentCursor, props));
  assert.match(render({ glowEnabled: false }), /data-glow="disabled"/);
  assert.match(render({ glowIntensity: 0 }), /data-glow="disabled"/);
  const customized = render({ glowIntensity: 0.4, glowColor: "#ff00aa" });
  assert.match(customized, /data-glow="enabled"/);
  assert.match(customized, /--k-agent-cursor-glow-intensity:0.4/);
  assert.match(customized, /--k-agent-cursor-glow:#ff00aa/);
  assert.match(
    render({ glowIntensity: 5 }),
    /--k-agent-cursor-glow-intensity:1/,
  );
});
