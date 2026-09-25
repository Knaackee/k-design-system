import { readFile, mkdir, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { createHash } from "node:crypto";
const root = fileURLToPath(new URL("../", import.meta.url));
const source = JSON.parse(
  await readFile(path.join(root, "assets/icons/lucide/source.json"), "utf8"),
);
const icons = {};
if (new Set(source.icons).size !== source.icons.length)
  throw new Error("Duplicate Lucide icon names");
for (const name of source.icons) {
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(name))
    throw new Error(`Invalid Lucide icon name: ${name}`);
  icons[name] = (
    await readFile(path.join(root, `assets/icons/lucide/${name}.svg`), "utf8")
  ).trim();
}
if (source.catalogSha256) {
  const digest = createHash("sha256")
    .update(JSON.stringify(icons))
    .digest("hex");
  if (digest !== source.catalogSha256)
    throw new Error("Lucide catalog digest mismatch; review the source import");
}
const banner = "// Generated from assets/icons/lucide; do not edit.\n";
const web =
  banner +
  "export const iconSvg = " +
  JSON.stringify(icons, null, 2) +
  " as const;\nexport type KIconName = keyof typeof iconSvg;\nexport const kIconNames = Object.keys(iconSvg) as KIconName[];\n";
// Preserve existing names; escape Dart keywords and enum/Object members.
const dartReserved = new Set(
  `abstract as assert async augment await base break case catch class const continue covariant default deferred do dynamic else enum export extends extension external factory false final finally for Function get hide if implements import in interface is late library mixin native new null of on operator part required rethrow return sealed set show static super switch sync this throw true try type typedef var void when while with yield name index values hashCode runtimeType noSuchMethod toString`.split(
    /\s+/,
  ),
);
const dartNames = Object.fromEntries(
  source.icons.map((name) => [
    name,
    (() => {
      const identifier = name.replace(/-([a-z0-9])/g, (_, c) =>
        c.toUpperCase(),
      );
      return dartReserved.has(identifier) || /^[0-9]/.test(identifier)
        ? `icon${identifier[0].toUpperCase()}${identifier.slice(1)}`
        : identifier;
    })(),
  ]),
);
if (new Set(Object.values(dartNames)).size !== source.icons.length)
  throw new Error("Lucide names collide after Dart conversion");
const dart =
  banner +
  "enum KIconName { " +
  Object.values(dartNames).join(", ") +
  " }\n\nconst kIconLabels = <KIconName, String>{\n" +
  source.icons
    .map((name) => `  KIconName.${dartNames[name]}: '${name}',`)
    .join("\n") +
  "\n};\n\nconst kIconSvg = <KIconName, String>{\n" +
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
