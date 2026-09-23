import { readFile, writeFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
const root = new URL("../", import.meta.url);
const items = JSON.parse(
  await readFile(new URL("assets/emoji/catalog.json", root), "utf8"),
);
const json = JSON.stringify(items);
const outputs = {
  "packages/web/ui/src/generated/emoji.ts": `// Generated from assets/emoji/catalog.json; do not edit.\nexport const kEmojiCatalog = ${json};\n`,
  "packages/flutter/k_design_ui/lib/src/generated/k_emoji.g.dart": `// Generated from assets/emoji/catalog.json; do not edit.\nimport 'dart:convert';\nfinal List<Map<String, dynamic>> kEmojiCatalog = (jsonDecode(r'''${json}''') as List).cast<Map<String, dynamic>>();\n`,
};
for (const [file, content] of Object.entries(outputs)) {
  const target = new URL(file, root);
  if (process.argv.includes("--check")) {
    if ((await readFile(target, "utf8").catch(() => "")) !== content)
      throw new Error(`Emoji catalog drift: ${file}`);
  } else await writeFile(target, content);
}
const compiled = spawnSync(
  process.platform === "win32" ? "dart.bat" : "dart",
  [
    "run",
    "tooling/compile_emoji.dart",
    ...(process.argv.includes("--check") ? ["--check"] : []),
  ],
  { cwd: root, stdio: "inherit", shell: process.platform === "win32" },
);
if (compiled.error) throw compiled.error;
if (compiled.status !== 0) process.exit(compiled.status ?? 1);
