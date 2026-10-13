import assert from "node:assert/strict";
import { mkdir, readFile, readdir, writeFile } from "node:fs/promises";
import { createRequire } from "node:module";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { kDiceBearStyleIds } from "../packages/web/ui/src/data-display/dicebear-catalog.ts";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const require = createRequire(
  pathToFileURL(path.join(root, "packages/web/ui/package.json")),
);
const stylesPackage = JSON.parse(
  await readFile(
    path.join(
      path.dirname(require.resolve("@dicebear/styles/adventurer.json")),
      "..",
      "package.json",
    ),
    "utf8",
  ),
);
assert.equal(
  stylesPackage.version,
  "10.6.0",
  "Flutter style assets must be generated from @dicebear/styles 10.6.0",
);

const stylesRoot = path.dirname(
  require.resolve("@dicebear/styles/adventurer.json"),
);
const packageRoot = path.resolve(stylesRoot, "..");
const { Avatar, OptionsDescriptor, Style } = await import(
  pathToFileURL(require.resolve("@dicebear/core")).href
);

export const styleIds = [...kDiceBearStyleIds];

const assetsDirectory = path.join(
  root,
  "packages/flutter/k_design_ui/assets/dicebear",
);
const stylesDirectory = path.join(assetsDirectory, "styles");
const catalogPath = path.join(
  root,
  "packages/flutter/k_design_ui/lib/src/data_display/k_dicebear_catalog.g.dart",
);
const fixturePath = path.join(
  root,
  "packages/flutter/k_design_ui/test/fixtures/dicebear-svg-parity.json",
);
const check = process.argv.includes("--check");

async function emit(file, contents) {
  if (check) {
    assert.equal(
      await readFile(file, "utf8"),
      contents,
      `${path.relative(root, file)} is stale; run pnpm generate`,
    );
    return;
  }
  await mkdir(path.dirname(file), { recursive: true });
  await writeFile(file, contents);
}

const definitions = new Map();
for (const id of styleIds) {
  const source = await readFile(
    path.join(packageRoot, "src", `${id}.json`),
    "utf8",
  );
  definitions.set(id, source);
  await emit(path.join(stylesDirectory, `${id}.json`), source);
}

if (check) {
  const generatedStyleFiles = (await readdir(stylesDirectory))
    .filter((name) => name.endsWith(".json"))
    .sort();
  assert.deepEqual(
    generatedStyleFiles,
    styleIds.map((id) => `${id}.json`).sort(),
    "Flutter DiceBear style assets contain unapproved or missing definitions",
  );
}

await emit(
  path.join(assetsDirectory, "LICENSE.md"),
  await readFile(path.join(packageRoot, "LICENSE.md"), "utf8"),
);

const dartIds = styleIds.map((id) => `  '${id}',`).join("\n");
const animatedIds = styleIds.filter(
  (id) => JSON.parse(definitions.get(id)).components?.animation,
);
const dartAnimatedIds = animatedIds.map((id) => `  '${id}',`).join("\n");
await emit(
  path.join(root, "packages/web/ui/src/generated/dicebear-motion-styles.ts"),
  `// GENERATED FILE. DO NOT EDIT.\n// Source: tooling/generate-dicebear-flutter.mjs\nexport const kDiceBearAnimatedStyleIds = ${JSON.stringify(animatedIds)} as const;\n`,
);
const dartPaths = styleIds
  .map(
    (id) =>
      `  '${id}': 'packages/k_design_ui/assets/dicebear/styles/${id}.json',`,
  )
  .join("\n");
await emit(
  catalogPath,
  `// GENERATED FILE. DO NOT EDIT.\n// Source: tooling/generate-dicebear-flutter.mjs\n\nconst List<String> kDiceBearStyleIds = [\n${dartIds}\n];\n\nconst List<String> kDiceBearAnimatedStyleIds = [\n${dartAnimatedIds}\n];\n\nconst Map<String, String> kDiceBearStyleAssetPaths = {\n${dartPaths}\n};\n`,
);

const seed = "K Design System";
const defaults = {};
for (const [id, source] of definitions) {
  defaults[id] = new Avatar(new Style(JSON.parse(source)), {
    seed,
    idRandomization: false,
  }).toString();
}

const adventurer = new Style(JSON.parse(definitions.get("adventurer")));
const descriptor = new OptionsDescriptor(adventurer).toJSON();
const variants = {};
for (const part of ["mouth", "hair", "eyes"]) {
  const option = `${part}Variant`;
  const choices = descriptor[option].values.slice(0, 2);
  variants[part] = {
    choices,
    svgs: choices.map((choice) =>
      new Avatar(adventurer, {
        seed: "same-person",
        idRandomization: false,
        [option]: [choice],
        [`${part}Probability`]: 100,
      }).toString(),
    ),
  };
}

await emit(
  fixturePath,
  `${JSON.stringify({ seed, defaults, adventurerVariants: variants })}\n`,
);

console.log(
  `${check ? "Verified" : "Generated"} ${styleIds.length} Flutter DiceBear styles and SVG parity fixtures.`,
);
