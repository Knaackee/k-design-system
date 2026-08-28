import test from "node:test";
import assert from "node:assert/strict";
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
