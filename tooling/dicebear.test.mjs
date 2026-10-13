import test from "node:test";
import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { pathToFileURL } from "node:url";
import {
  kDiceBearStyleIds,
  loadKDiceBearStyle,
  getKDiceBearOptions,
} from "../packages/web/ui/src/data-display/dicebear-catalog.ts";
const require = createRequire(
  new URL("../packages/web/ui/package.json", import.meta.url),
);
const { Avatar } = await import(
  pathToFileURL(require.resolve("@dicebear/core")).href
);

test("approved catalogue renders all 57 styles with distributable license metadata", async () => {
  assert.equal(kDiceBearStyleIds.length, 57);
  assert.equal(new Set(kDiceBearStyleIds).size, 57);
  const counts = {};
  for (const id of kDiceBearStyleIds) {
    assert.doesNotMatch(id, /^(avataaars|bottts)/);
    const style = await loadKDiceBearStyle(id);
    const license = style.meta().license().name();
    counts[license] = (counts[license] ?? 0) + 1;
    assert.match(
      new Avatar(style, {
        seed: "catalogue-test",
        idRandomization: false,
      }).toString(),
      /<svg\b/,
    );
    assert.ok(style.meta().creator().name());
    assert.ok(style.meta().source().url());
    assert.ok(style.meta().license().url());
    if (license === "CC BY 4.0" || license === "MIT")
      assert.ok(style.meta().license().text());
    assert.strictEqual(await loadKDiceBearStyle(id), style);
  }
  assert.deepEqual(counts, { "CC BY 4.0": 14, "CC0 1.0": 42, MIT: 1 });
});

test("individual mouth, hair and eye choices alter the avatar independently", async () => {
  const style = await loadKDiceBearStyle("adventurer");
  const descriptor = getKDiceBearOptions(style);
  for (const part of ["mouth", "hair", "eyes"]) {
    const key = `${part}Variant`;
    const choices = descriptor[key].values;
    assert.ok(choices.length > 1);
    const render = (choice) =>
      new Avatar(style, {
        seed: "same-person",
        idRandomization: false,
        [key]: [choice],
        [`${part}Probability`]: 100,
      }).toString();
    assert.notEqual(render(choices[0]), render(choices[1]), part);
  }
});

test("animated catalogue exposes original DiceBear timelines and speed variants", async () => {
  const { kDiceBearAnimatedStyleIds } =
    await import("../packages/web/ui/src/generated/dicebear-motion-styles.ts");
  assert.equal(kDiceBearAnimatedStyleIds.length, 19);
  for (const id of kDiceBearAnimatedStyleIds) {
    const style = await loadKDiceBearStyle(id);
    const render = (variant) =>
      new Avatar(style, {
        seed: "K Design System",
        idRandomization: false,
        animationVariant: [variant],
      }).toString();
    assert.match(render("medium"), /@keyframes/, id);
    assert.doesNotMatch(render("none"), /@keyframes/, id);
    assert.notEqual(render("fastest"), render("slowest"), id);
  }
});

test("seed and options are deterministic, configurable and reject excluded styles", async () => {
  const style = await loadKDiceBearStyle("adventurer");
  const render = (seed, options = {}) =>
    new Avatar(style, { ...options, seed, idRandomization: false }).toDataUri();
  assert.equal(render("Ada"), render("Ada"));
  assert.notEqual(render("Ada"), render("Grace"));
  assert.notEqual(
    render("Ada"),
    render("Ada", { scale: 0.65, hairColor: ["#ff0000"] }),
  );
  await assert.rejects(
    loadKDiceBearStyle("avataaars"),
    /Unsupported DiceBear style/,
  );
  await assert.rejects(
    loadKDiceBearStyle("toString"),
    /Unsupported DiceBear style/,
  );
});
