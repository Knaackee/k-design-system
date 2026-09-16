import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import {
  flattenTokens,
  resolveToken,
  resolvedSemantic,
  resolvedVariant,
} from "./generate-tokens.mjs";

test("rejects tokens without a DTCG type", () => {
  assert.throws(
    () => flattenTokens({ broken: { $value: "#fff" } }),
    /missing \$type/,
  );
});

test("flattens nested DTCG token paths", () => {
  const tokens = flattenTokens({
    color: { text: { $type: "color", $value: "#000000" } },
  });
  assert.deepEqual(tokens.get("color.text"), {
    type: "color",
    value: "#000000",
  });
});

test("rejects unknown and circular references", () => {
  assert.throws(
    () =>
      resolveToken(
        "a",
        new Map([["a", { type: "color", value: "{missing}" }]]),
      ),
    /Unknown token reference/,
  );
  assert.throws(
    () =>
      resolveToken(
        "a",
        new Map([
          ["a", { type: "color", value: "{b}" }],
          ["b", { type: "color", value: "{a}" }],
        ]),
      ),
    /Circular token reference/,
  );
});

test("rejects theme keys and types outside the semantic contract", () => {
  const semantic = new Map([
    ["color.text", { type: "color", value: "#000000" }],
  ]);
  assert.throws(
    () =>
      resolvedSemantic(
        new Map(),
        semantic,
        new Map([["color.extra", { type: "color", value: "#ffffff" }]]),
      ),
    /Unknown theme override/,
  );
  assert.throws(
    () =>
      resolvedSemantic(
        new Map(),
        semantic,
        new Map([
          [
            "color.text",
            { type: "dimension", value: { value: 1, unit: "px" } },
          ],
        ]),
      ),
    /expected color/,
  );
});

test("resolves only the semantic fields changed by a runtime variant", () => {
  const foundation = new Map([
    [
      "size.control.sm",
      { type: "dimension", value: { value: 32, unit: "px" } },
    ],
  ]);
  const semantic = new Map([
    ["size.control", { type: "dimension", value: { value: 36, unit: "px" } }],
    ["color.text", { type: "color", value: "#000000" }],
  ]);
  const variant = new Map([
    ["size.control", { type: "dimension", value: "{size.control.sm}" }],
  ]);

  assert.deepEqual(
    [...resolvedVariant(foundation, semantic, variant)],
    [["size.control", { type: "dimension", value: { value: 32, unit: "px" } }]],
  );
});

test("emits runtime modes in a higher cascade layer than brand themes", async () => {
  const css = await readFile(
    new URL("../packages/web/tokens/src/generated/tokens.css", import.meta.url),
    "utf8",
  );

  assert.match(css, /@layer k-design-theme, k-design-mode;/);
  assert.ok(
    css.indexOf("@layer k-design-theme {") <
      css.indexOf("@layer k-design-mode {"),
  );
  assert.match(css, /\[data-density="dense"\][\s\S]*--k-size-control: 32px/);
});

test("generates transparent DTCG colors for Flutter", async () => {
  const dart = await readFile(
    new URL(
      "../packages/flutter/k_design_tokens/lib/src/generated/k_design_tokens.g.dart",
      import.meta.url,
    ),
    "utf8",
  );

  assert.match(dart, /colorActionGhostBackground: Color\(0x00000000\)/);
});

test("bundles the shared Inter family for Flutter consumers", async () => {
  const dart = await readFile(
    new URL(
      "../packages/flutter/k_design_tokens/lib/src/generated/k_design_tokens.g.dart",
      import.meta.url,
    ),
    "utf8",
  );

  assert.match(dart, /fontFamily: "packages\/k_design_tokens\/Inter"/);
});

test("semantic text pairs meet WCAG AA contrast", async () => {
  const themes = JSON.parse(
    await readFile(
      new URL("../dist/tokens.flat.json", import.meta.url),
      "utf8",
    ),
  );
  const roleGroups = [
    "color.brand.primary",
    "color.brand.secondary",
    "color.status.info",
    "color.status.success",
    "color.status.warning",
    "color.status.error",
  ];

  for (const [themeName, theme] of Object.entries(themes)) {
    if (themeName === "variants") continue;
    assert.ok(
      contrast(
        theme["color.text.primary"].value,
        theme["color.surface.canvas"].value,
      ) >= 4.5,
      `${themeName} primary text must meet 4.5:1`,
    );
    for (const role of roleGroups) {
      assert.ok(
        contrast(
          theme[`${role}.foreground`].value,
          theme[`${role}.background`].value,
        ) >= 4.5,
        `${themeName} ${role} text must meet 4.5:1`,
      );
    }
  }
});

test("projects DTCG shadow tokens to CSS and Flutter", async () => {
  const css = await readFile(
    new URL("../packages/web/tokens/src/generated/tokens.css", import.meta.url),
    "utf8",
  );
  const dart = await readFile(
    new URL(
      "../packages/flutter/k_design_tokens/lib/src/generated/k_design_tokens.g.dart",
      import.meta.url,
    ),
    "utf8",
  );

  assert.match(css, /--k-elevation-low: 0px 1px 2px 0px #[a-f\d]{8}/i);
  assert.match(
    dart,
    /final List<BoxShadow> elevationLow;[\s\S]*BoxShadow\(color: Color\(0x[\dA-F]{8}\)/,
  );
});

test("density owns the complete composition rhythm without presentation", async () => {
  const flat = JSON.parse(
    await readFile(
      new URL("../dist/tokens.flat.json", import.meta.url),
      "utf8",
    ),
  );
  for (const [mode, values] of Object.entries({
    densityDense: [4, 8, 8, 12, 16, 32],
    densityStandard: [8, 16, 12, 16, 32, 36],
    densitySpacious: [12, 24, 16, 24, 48, 44],
  })) {
    const keys = [
      "space.controlGap",
      "space.contentActionGap",
      "space.controlInsetInline",
      "space.cardPadding",
      "space.layoutSectionGap",
      "size.control",
    ];
    assert.deepEqual(
      keys.map((key) => flat.variants[mode][key]?.value.value),
      values,
    );
  }
  assert.ok(
    Object.keys(flat.variants).every((key) => !key.startsWith("presentation")),
  );
});

function contrast(first, second) {
  const [lighter, darker] = [luminance(first), luminance(second)].sort(
    (a, b) => b - a,
  );
  return (lighter + 0.05) / (darker + 0.05);
}

function luminance(hex) {
  const channels = hex
    .slice(1, 7)
    .match(/.{2}/g)
    .map((value) => Number.parseInt(value, 16) / 255)
    .map((value) =>
      value <= 0.04045 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4,
    );
  return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
}
