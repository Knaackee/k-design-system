import assert from "node:assert/strict";
import { readFile, readdir } from "node:fs/promises";
import { createRequire } from "node:module";
import { resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import test from "node:test";

const root = fileURLToPath(new URL("../", import.meta.url));
const source = JSON.parse(
  await readFile(resolve(root, "assets/icons/lucide/source.json"), "utf8"),
);
const require = createRequire(resolve(root, "packages/web/ui/package.json"));
const { iconToCubics, resampleIcon, buildPlan, allocOutputs, interpPolar } =
  await import(pathToFileURL(require.resolve("morphicons")).href);
const previousNames =
  `arrow-down arrow-left arrow-right arrow-up bell calendar check check-check chevron-down chevron-left chevron-right chevron-up circle-alert circle-check clock copy download ellipsis external-link eye eye-off file file-text folder funnel heart house image info link lock lock-open mail menu mic minus moon paperclip pause pen play plus refresh-cw search settings sliders-horizontal star sun trash triangle-alert upload user users x`.split(
    " ",
  );

const catalog = new Map(
  await Promise.all(
    source.icons.map(async (name) => {
      const svg = await readFile(
        resolve(root, `assets/icons/lucide/${name}.svg`),
        "utf8",
      );
      const nodes = [
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
      return [name, { svg: svg.trim(), nodes }];
    }),
  ),
);

test("pinned Lucide catalog is complete, unique and backward compatible", async () => {
  assert.equal(source.version, "1.46.0");
  assert.equal(source.icons.length, 1838);
  assert.equal(new Set(source.icons).size, 1838);
  const files = (await readdir(resolve(root, "assets/icons/lucide")))
    .filter((name) => name.endsWith(".svg"))
    .map((name) => name.slice(0, -4));
  assert.deepEqual(files.sort(), [...source.icons].sort());
  for (const name of previousNames) assert.ok(catalog.has(name), name);
});

test("Web and Flutter generated catalogs contain identical SVG geometry", async () => {
  const web = await readFile(
    resolve(root, "packages/web/ui/src/generated/icons.ts"),
    "utf8",
  );
  const webIcons = JSON.parse(
    web.match(/export const iconSvg = ([\s\S]*?) as const;/)[1],
  );
  assert.deepEqual(Object.keys(webIcons).sort(), [...source.icons].sort());
  const dart = await readFile(
    resolve(
      root,
      "packages/flutter/k_design_ui/lib/src/generated/k_icons.g.dart",
    ),
    "utf8",
  );
  const dartSvgs = [...dart.matchAll(/KIconName\.\w+: r'''([\s\S]*?)'''/g)].map(
    (match) => match[1],
  );
  const dartLabels = [...dart.matchAll(/KIconName\.(\w+): '([^']+)',/g)];
  assert.deepEqual(
    dartLabels.map((match) => match[2]).sort(),
    [...source.icons].sort(),
  );
  assert.equal(
    new Set(dartLabels.map((match) => match[1])).size,
    source.icons.length,
  );
  assert.equal(dartSvgs.length, source.icons.length);
  assert.deepEqual(
    dartSvgs.sort(),
    [...catalog.values()].map(({ svg }) => svg).sort(),
  );
  for (const [name, { svg }] of catalog)
    assert.equal(webIcons[name], svg, name);
});

test("every Lucide icon produces finite geometry and bidirectional morphs", () => {
  const anchor = resampleIcon(catalog.get("menu").nodes);
  for (const [name, { nodes }] of catalog) {
    const canonical = iconToCubics(nodes);
    const sampled = resampleIcon(nodes);
    assert.ok(canonical.length > 0, `${name}: canonical geometry`);
    assert.equal(sampled.length, canonical.length, name);
    for (const path of sampled) {
      assert.equal(path.pts.length, 128, name);
      assert.ok(path.pts.every(Number.isFinite), `${name}: sampled geometry`);
    }
    for (const [from, to] of [
      [anchor, sampled],
      [sampled, anchor],
    ]) {
      const plan = buildPlan(from, to);
      const output = allocOutputs(plan);
      assert.ok(output.length > 0, name);
      for (const progress of [0, 0.5, 1]) {
        interpPolar(plan, progress, output);
        assert.ok(
          output.every((path) => path.every(Number.isFinite)),
          `${name}: progress ${progress}`,
        );
      }
    }
  }
});
