// Regenerate with: node tooling/animated-icon-reference.mjs
// Expected geometry comes from the pinned upstream implementation, never Dart.
import { createRequire } from "node:module";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { fileURLToPath, pathToFileURL } from "node:url";
import { dirname, resolve } from "node:path";
import { format } from "prettier";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const require = createRequire(resolve(root, "packages/web/ui/package.json"));
const { resampleIcon, buildPlan, allocOutputs, interpPolar, Spring } =
  await import(pathToFileURL(require.resolve("morphicons")).href);

async function catalog(name) {
  const svg = await readFile(
    resolve(root, `assets/icons/lucide/${name}.svg`),
    "utf8",
  );
  return [
    ...svg.matchAll(
      /<(path|line|circle|ellipse|rect|polyline|polygon)\b([^>]*)/g,
    ),
  ].map(([, tag, attrs]) => [
    tag,
    Object.fromEntries(
      [...attrs.matchAll(/([\w-]+)="([^"]*)"/g)].map(([, key, value]) => [
        key,
        value,
      ]),
    ),
  ]);
}

const icons = Object.fromEntries(
  await Promise.all(
    [
      "arrow-right",
      "arrow-down",
      "plus",
      "x",
      "menu",
      "sun",
      "moon",
      "play",
      "pause",
    ].map(async (name) => [name, await catalog(name)]),
  ),
);

const transitions = [
  ["arrow-right", "arrow-down"],
  ["plus", "x"],
  ["menu", "x"],
  ["sun", "moon"],
  ["play", "pause"],
].map(([from, to]) => {
  const plan = buildPlan(resampleIcon(icons[from]), resampleIcon(icons[to]));
  const output = allocOutputs(plan);
  return {
    from,
    to,
    frames: [0, 0.25, 0.5, 0.75, 1].map((t) => {
      interpPolar(plan, t, output);
      return {
        t,
        points: output.map((path) =>
          Array.from(path, (v) => Number(v.toFixed(9))),
        ),
      };
    }),
  };
});
const spring = new Spring();
spring.config(300, 14);
spring.start();
const steps = [0, 1 / 120, 1 / 60, 1 / 30, 0.05, 0.1, 1 / 60, 1 / 60, 0.1];
const springFrames = steps.map((dt, index) => {
  if (index === 5) spring.start();
  const settled = spring.step(dt);
  return { dt, restart: index === 5, x: spring.x, v: spring.v, settled };
});
const fixture = {
  source: "morphicons@1.7.1",
  sourceCommit: "38d2a7221633a453eeafebd872ee3649b9274b22",
  coordinateTolerance: 0.00000002,
  icons,
  transitions,
  springFrames,
};
const output = resolve(
  root,
  "packages/flutter/k_design_ui/test/fixtures/animated_icon_reference.json",
);
await mkdir(dirname(output), { recursive: true });
await writeFile(
  output,
  await format(JSON.stringify(fixture), { parser: "json" }),
);
console.log(`Wrote ${output}`);
