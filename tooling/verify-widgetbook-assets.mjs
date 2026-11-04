import { readFile, stat } from "node:fs/promises";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

// A successful Dart compilation does not prove that the served gallery includes
// its fonts. Missing manifests silently produce fallback typography in Flutter.
const root = fileURLToPath(new URL("../", import.meta.url));
const output = resolve(root, process.argv[2] ?? "apps/widgetbook/build/web");
const manifest = JSON.parse(
  await readFile(resolve(output, "assets/FontManifest.json"), "utf8"),
);
if (
  !manifest.some(({ family }) => family === "packages/k_design_tokens/Inter")
) {
  throw new Error(
    "Widgetbook font manifest is missing the K Design System Inter family.",
  );
}
for (const { family, fonts } of manifest) {
  for (const { asset } of fonts) {
    const info = await stat(resolve(output, "assets", asset));
    if (!info.isFile() || info.size === 0)
      throw new Error(`Missing font asset: ${family}: ${asset}`);
  }
}
console.log(
  `Widgetbook: ${manifest.length} font families verified, including packaged Inter.`,
);
