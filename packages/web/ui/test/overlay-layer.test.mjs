import assert from "node:assert/strict";
import { test } from "node:test";
import { createElement } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import {
  OverlayLayerContext,
  resolveOverlayLayer,
  useOverlayLayer,
} from "../dist/overlays/overlay-layer.js";

test("explicit owner layers are preserved and every nested backdrop clears its parent", () => {
  assert.equal(resolveOverlayLayer(), 3010);
  assert.equal(resolveOverlayLayer(undefined, 3060), 3060);
  assert.equal(resolveOverlayLayer(3060, 4000), 4000);
  const fullscreen = resolveOverlayLayer(3060);
  const link = resolveOverlayLayer(fullscreen);
  assert.equal(fullscreen, 3090);
  assert.equal(link, 3120);
  assert.ok(fullscreen - 10 > 3060);
  assert.ok(link - 10 > fullscreen);
  assert.equal(
    resolveOverlayLayer(3060),
    fullscreen,
    "siblings do not consume global layer numbers",
  );
});

function NestedLayer({ label, children, explicit }) {
  const layer = useOverlayLayer(explicit);
  return createElement(
    OverlayLayerContext.Provider,
    { value: layer },
    createElement(
      "section",
      { "data-owner": label, "data-layer": layer },
      children,
    ),
  );
}

test("React ownership carries an explicit job layer through fullscreen and nested link surfaces", () => {
  const html = renderToStaticMarkup(
    createElement(
      NestedLayer,
      { label: "job", explicit: 3060 },
      createElement(
        NestedLayer,
        { label: "fullscreen" },
        createElement(NestedLayer, { label: "link" }),
      ),
    ),
  );
  assert.match(html, /data-owner="job" data-layer="3060"/);
  assert.match(html, /data-owner="fullscreen" data-layer="3090"/);
  assert.match(html, /data-owner="link" data-layer="3120"/);
});

test("collapsed editor ownership returns nested actions to the original job layer", () => {
  const html = renderToStaticMarkup(
    createElement(
      OverlayLayerContext.Provider,
      { value: 3060 },
      createElement(NestedLayer, { label: "inline-link" }),
    ),
  );
  assert.match(html, /data-owner="inline-link" data-layer="3090"/);
});
