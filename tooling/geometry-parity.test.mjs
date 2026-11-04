import assert from "node:assert/strict";
import test from "node:test";
import { compare, tolerance } from "./geometry-parity.mjs";

test("geometry parity compares only the declared axes within tolerance", () => {
  const flutter = {
    "phone@1": { button: { w: 63, h: 48 }, text: { w: 320, h: 48 } },
  };
  const web = {
    "phone@1": {
      button: { w: 63 + tolerance, h: 48 },
      text: { w: 200, h: 48 },
    },
  };
  assert.deepEqual(compare(flutter, web, { button: "wh", text: "h" }), []);
});

test("geometry parity reports differences and missing entries", () => {
  const flutter = {
    "phone@1": { button: { w: 63, h: 48 }, card: { w: 320, h: 112 } },
  };
  const web = { "phone@1": { button: { w: 63, h: 44 } } };
  assert.deepEqual(compare(flutter, web, { button: "wh", card: "h" }), [
    "phone@1 button height: Flutter 48.0 vs Web 44.0 (-4.0)",
    "phone@1 card: missing on Web",
  ]);
});
