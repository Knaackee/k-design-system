import { readFile, readdir, mkdir, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";
const root = fileURLToPath(new URL("../", import.meta.url));
const catalog = {};
for (const name of (await readdir(path.join(root, "locales")))
  .filter((n) => n.endsWith(".json"))
  .sort()) {
  catalog[name.slice(0, -5)] = JSON.parse(
    await readFile(path.join(root, "locales", name), "utf8"),
  );
}
const keys = Object.keys(catalog.en.messages).sort();
for (const [tag, data] of Object.entries(catalog)) {
  if (
    JSON.stringify(Object.keys(data.messages).sort()) !== JSON.stringify(keys)
  )
    throw Error(`Message keys differ: ${tag}`);
  if (
    data.months.length !== 12 ||
    data.weekdays.length !== 7 ||
    ![0, 1, 2, 3, 4, 5, 6].includes(data.firstDay)
  )
    throw Error(`Invalid calendar: ${tag}`);
  for (const [key, text] of Object.entries(data.messages)) {
    if (typeof text !== "string" || !text.trim())
      throw Error(`Empty message: ${tag}.${key}`);
    if ((text.match(/\{label\}/g) || []).length !== (key === "remove" ? 1 : 0))
      throw Error(`Invalid placeholder: ${tag}.${key}`);
  }
}
const banner = "// Generated from locales/*.json; do not edit.\n";
const web =
  banner +
  "export const kLocaleCatalog = " +
  JSON.stringify(catalog, null, 2) +
  " as const;\n";
function dart(value) {
  if (typeof value === "string")
    return (
      "'" +
      value
        .replaceAll("\\", "\\\\")
        .replaceAll("'", "\\'")
        .replaceAll("$", "\\$") +
      "'"
    );
  if (Array.isArray(value)) return "[" + value.map(dart).join(", ") + "]";
  if (typeof value === "object")
    return (
      "{\n" +
      Object.entries(value)
        .map(([k, v]) => dart(k) + ": " + dart(v) + ",")
        .join("\n") +
      "\n}"
    );
  return String(value);
}
for (const [relative, content] of [
  ["packages/web/ui/src/generated/locales.ts", web],
  [
    "packages/flutter/k_design_ui/lib/src/generated/locales.dart",
    banner +
      "const kLocaleCatalog = <String, Map<String, dynamic>>" +
      dart(catalog) +
      ";\n",
  ],
]) {
  const target = path.join(root, relative);
  if (process.argv.includes("--check")) {
    if ((await readFile(target, "utf8").catch(() => "")) !== content)
      throw Error(`Generated locale drift: ${relative}`);
  } else {
    await mkdir(path.dirname(target), { recursive: true });
    await writeFile(target, content);
  }
}
