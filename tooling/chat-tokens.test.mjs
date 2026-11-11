import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { flattenTokens, resolvedSemantic } from "./generate-tokens.mjs";

const read = async (path) =>
  readFile(new URL(`../${path}`, import.meta.url), "utf8");
const json = async (path) => JSON.parse(await read(path));
const expected = {
  iconStroke: [1.25, 1.25, 1.25],
  "column.maxWidth": [720, 720, 720],
  "column.gutter": [16, 24, 32],
  "turn.gap": [16, 24, 32],
  "block.gap": [8, 12, 16],
  "meta.gap": [4, 8, 12],
  "bubble.paddingInline": [8, 12, 16],
  "bubble.paddingBlock": [6, 10, 12],
  "bubble.maxWidth": [0.8, 0.75, 0.7],
  "disclosure.minHeight": [24, 28, 32],
  "card.padding": [12, 16, 24],
  "card.headerHeight": [32, 36, 44],
  "card.actionGap": [8, 16, 24],
  "option.minHeight": [32, 36, 44],
  "option.gap": [4, 8, 8],
  "option.paddingInline": [8, 12, 16],
  "attachment.height": [32, 36, 44],
  "code.headerHeight": [28, 32, 36],
  "code.padding": [8, 12, 16],
  "composer.padding": [12, 16, 20],
  "composer.overhang": [12, 24, 32],
  "composer.minHeight": [88, 112, 136],
  "composer.bottomGap": [12, 16, 24],
  "composer.radius": [18, 18, 18],
  "panel.width": [360, 400, 440],
  "panel.rowHeight": [32, 36, 44],
  "home.sectionGap": [16, 32, 48],
  "home.rowHeight": [32, 40, 48],
};

test("chat tokens resolve the specification in every density", async () => {
  const foundation = flattenTokens(await json("tokens/foundation.tokens.json"));
  const semantic = flattenTokens(await json("tokens/semantic.tokens.json"));
  assert.equal(
    [...semantic.keys()].filter((name) => name.startsWith("component.chat."))
      .length,
    Object.keys(expected).length,
  );
  for (const [index, density] of ["dense", "standard", "spacious"].entries()) {
    const overrides = flattenTokens(
      await json(`tokens/modes/density.${density}.tokens.json`),
    );
    const resolved = resolvedSemantic(foundation, semantic, overrides);
    for (const [name, values] of Object.entries(expected)) {
      const token = resolved.get(`component.chat.${name}`);
      const ratio = name === "bubble.maxWidth" || name === "iconStroke";
      assert.equal(token.type, ratio ? "number" : "dimension");
      assert.deepEqual(
        token.value,
        ratio ? values[index] : { value: values[index], unit: "px" },
        `${density}: ${name}`,
      );
    }
  }
});

test("Web chat aliases stay live across density and consumer overrides", async () => {
  const css = await read("packages/web/tokens/src/generated/tokens.css");
  for (const [name, target] of Object.entries({
    "card-padding": "space-card-padding",
    "card-header-height": "size-control",
    "card-action-gap": "space-content-action-gap",
    "option-min-height": "size-control",
    "option-padding-inline": "space-control-inset-inline",
    "attachment-height": "size-control",
    "home-section-gap": "space-layout-section-gap",
    "panel-row-height": "size-control",
  })) {
    const declarations = css.match(
      new RegExp(`--k-component-chat-${name}: ([^;]+);`, "g"),
    );
    assert.equal(declarations.length, 4, name);
    assert.ok(
      declarations.every((line) => line.endsWith(`var(--k-${target});`)),
      name,
    );
  }
  for (const [index, density] of ["dense", "standard", "spacious"].entries()) {
    const block = css.match(
      new RegExp(`\\[data-density="${density}"\\] \\{([^}]+)\\}`),
    )[1];
    assert.match(
      block,
      new RegExp(
        `--k-component-chat-bubble-max-width: ${[0.8, 0.75, 0.7][index]};`,
      ),
    );
    assert.doesNotMatch(block, /--k-component-chat-column-max-width:/);
  }
});
