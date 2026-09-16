import { readFile, mkdir, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
const root = fileURLToPath(new URL("../", import.meta.url));
const source = JSON.parse(
  await readFile(path.join(root, "assets/icons/lucide/source.json"), "utf8"),
);
const icons = {};
for (const name of source.icons) {
  icons[name] = (
    await readFile(path.join(root, `assets/icons/lucide/${name}.svg`), "utf8")
  ).trim();
}
const banner = "// Generated from assets/icons/lucide; do not edit.\n";
const web =
  banner +
  "export const iconSvg = " +
  JSON.stringify(icons, null, 2) +
  " as const;\nexport type KIconName = keyof typeof iconSvg;\nexport const kIconNames = Object.keys(iconSvg) as KIconName[];\n";
const dartNames = Object.fromEntries(
  source.icons.map((name) => [
    name,
    name.replace(/-([a-z])/g, (_, c) => c.toUpperCase()),
  ]),
);
const dart =
  banner +
  "enum KIconName { " +
  Object.values(dartNames).join(", ") +
  " }\n\nconst kIconSvg = <KIconName, String>{\n" +
  Object.entries(icons)
    .map(([name, svg]) => `  KIconName.${dartNames[name]}: r'''${svg}''',`)
    .join("\n") +
  "\n};\n";
const license = await readFile(
  path.join(root, "assets/icons/lucide/LICENSE"),
  "utf8",
);
for (const [relative, content] of [
  ["packages/web/ui/src/assets/icons/LICENSE", license],
  ["packages/flutter/k_design_ui/LICENSE.lucide", license],
  ["packages/web/ui/src/generated/icons.ts", web],
  ["packages/flutter/k_design_ui/lib/src/generated/k_icons.g.dart", dart],
]) {
  const target = path.join(root, relative);
  if (process.argv.includes("--check")) {
    if ((await readFile(target, "utf8").catch(() => "")) !== content)
      throw new Error(`Generated icon drift: ${relative}`);
  } else {
    await mkdir(path.dirname(target), { recursive: true });
    await writeFile(target, content);
  }
}
