import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { kAdaptiveAttributes, resolveKAdaptive } from "./dist/adaptive.js";

const phone = { width: 393, coarsePointer: true };

test("motion defaults to apple and follows an app override", () => {
  assert.equal(resolveKAdaptive(phone).motion, "apple");
  assert.equal(
    resolveKAdaptive(phone, { motion: "expressive" }).motion,
    "expressive",
  );
});

test("the system reduce-motion setting wins over an app style", () => {
  assert.equal(
    resolveKAdaptive({ ...phone, reduceMotion: true }, { motion: "expressive" })
      .motion,
    "reduced",
  );
});

test("the resolved style is published as data-motion", () => {
  assert.equal(
    kAdaptiveAttributes(resolveKAdaptive(phone))["data-motion"],
    "apple",
  );
});

test("every motion mode defines every role with a spring easing", async () => {
  const css = await readFile(
    new URL("../tokens/src/generated/tokens.css", import.meta.url),
    "utf8",
  );
  for (const mode of ["apple", "expressive", "reduced"]) {
    const block = css.split(`[data-motion="${mode}"] {`)[1].split("}")[0];
    for (const role of [
      "feedback",
      "control",
      "enter",
      "exit",
      "page",
      "attention",
    ]) {
      assert.match(block, new RegExp(`--k-motion-${role}-easing: linear\\(`));
      assert.match(block, new RegExp(`--k-motion-${role}-settle: \\d+ms`));
    }
  }
  const reduced = css.split('[data-motion="reduced"] {')[1].split("}")[0];
  assert.doesNotMatch(reduced, /-distance: 1;/);
});
