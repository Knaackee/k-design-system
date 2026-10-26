import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import test from "node:test";
import { DARK_MAP_TOKENS, createMapStyle } from "./dist/maps/index.js";

const require = createRequire(import.meta.url);
const mapLibreRequire = createRequire(
  require.resolve("maplibre-gl/package.json"),
);
const { validateStyleMin } = mapLibreRequire(
  "@maplibre/maplibre-gl-style-spec",
);

const validationMessages = (style) =>
  validateStyleMin(style).map((error) => error.message);

test("creates valid MapLibre styles for the light and dark token sets", () => {
  assert.deepEqual(validationMessages(createMapStyle()), []);
  assert.deepEqual(
    validationMessages(createMapStyle({ tokens: DARK_MAP_TOKENS })),
    [],
  );
});

test("keeps valid styles at every configurable numeric boundary", () => {
  const minimums = {
    roadWidthScale: 0.6,
    casingScale: 0,
    labelScale: 0.8,
    haloWidth: 0,
    buildingMinZoom: 12,
    poiMinZoom: 13,
    poiMaxRank: 1,
    poiDotScale: 0.5,
    roadLabelMinZoom: 11,
  };
  const maximums = {
    roadWidthScale: 1.6,
    casingScale: 2,
    labelScale: 1.4,
    haloWidth: 3,
    buildingMinZoom: 17,
    poiMinZoom: 18,
    poiMaxRank: 40,
    poiDotScale: 2,
    roadLabelMinZoom: 17,
  };

  assert.deepEqual(
    validationMessages(createMapStyle({ settings: minimums })),
    [],
  );
  assert.deepEqual(
    validationMessages(createMapStyle({ settings: maximums })),
    [],
  );
});

test("applies source, token, and setting overrides without mutating defaults", () => {
  const style = createMapStyle({
    tokens: { background: "#010203" },
    settings: { lang: "en", showPois: false },
    sources: {
      tiles: "https://example.test/tiles.json",
      glyphs: "https://example.test/fonts/{fontstack}/{range}.pbf",
    },
  });

  assert.equal(style.sources.openmaptiles.type, "vector");
  assert.equal(
    style.sources.openmaptiles.url,
    "https://example.test/tiles.json",
  );
  assert.equal(
    style.glyphs,
    "https://example.test/fonts/{fontstack}/{range}.pbf",
  );
  assert.equal(style.layers[0].paint["background-color"], "#010203");
  assert.equal(style.metadata["kds:settings"].lang, "en");
  assert.equal(
    style.layers.find((layer) => layer.id === "poi-dot").layout.visibility,
    "none",
  );
});

test("keeps the Flutter parity fixture synchronized with the Web builder", () => {
  const generator = fileURLToPath(
    new URL(
      "../../flutter/k_design_ui/tool/generate_map_style_fixtures.mjs",
      import.meta.url,
    ),
  );
  execFileSync(process.execPath, [generator, "--check"], { stdio: "pipe" });
});
