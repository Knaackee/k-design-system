import assert from "node:assert/strict";
import test from "node:test";
import { createElement as h, useContext } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { KIcon, readIconStroke } from "../dist/primitives/icon.js";
import {
  KChatIconProvider,
  KIconStrokeTokenContext,
} from "../dist/internal/icon-token-context.js";

test("chat selects its stroke token without affecting sibling icons", () => {
  const Probe = () => h("span", null, useContext(KIconStrokeTokenContext));
  const html = renderToStaticMarkup(
    h("div", null, h(KChatIconProvider, null, h(Probe)), h(Probe)),
  );
  assert.equal(
    html,
    "<div><span>--k-component-chat-icon-stroke</span><span>--k-size-icon-stroke</span></div>",
  );
});

test("stroke reader preserves style values and reads the scoped chat token", () => {
  const previousDocument = globalThis.document;
  const previousStyle = globalThis.getComputedStyle;
  globalThis.document = { documentElement: {} };
  globalThis.getComputedStyle = () => ({
    getPropertyValue: (name) =>
      ({
        "--k-size-icon-stroke": "1.75",
        "--k-component-chat-icon-stroke": "1.25",
      })[name] ?? "",
  });
  try {
    assert.equal(readIconStroke(), 1.75);
    assert.equal(readIconStroke("--k-component-chat-icon-stroke"), 1.25);
    assert.equal(readIconStroke("--missing"), 1.5);
  } finally {
    if (previousDocument === undefined) delete globalThis.document;
    else globalThis.document = previousDocument;
    if (previousStyle === undefined) delete globalThis.getComputedStyle;
    else globalThis.getComputedStyle = previousStyle;
  }
});

test("explicit strokeWidth keeps its grid-unit semantics inside chat", () => {
  const html = renderToStaticMarkup(
    h(KChatIconProvider, null, h(KIcon, { name: "check", strokeWidth: 0.9 })),
  );
  assert.match(decodeURIComponent(html), /stroke-width="0.9"/);
  const fallback = renderToStaticMarkup(h(KIcon, { name: "check", size: 16 }));
  assert.match(decodeURIComponent(fallback), /stroke-width="2.25"/);
});
