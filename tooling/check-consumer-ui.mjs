import { readFileSync, readdirSync } from "node:fs";
import { resolve, extname, join } from "node:path";
import { pathToFileURL } from "node:url";

export function findings(source, extension) {
  const rules =
    extension === ".dart"
      ? [
          [
            "native-control",
            /\b(?:Checkbox|Radio|RadioListTile|CheckboxListTile|DropdownButton|DropdownButtonFormField|CupertinoSwitch|Switch|TextField|ElevatedButton|TextButton|OutlinedButton)\s*(?:<[^>]+>)?\s*\(/g,
          ],
          [
            "raw-spacing",
            /\b(?:EdgeInsets\.(?:all|symmetric|only)|SizedBox)\s*\([^)]*\b[1-9]\d*(?:\.\d+)?\b/g,
          ],
        ]
      : [
          ["native-control", /<(?:input|select|textarea|button)\b/g],
          [
            "upstream-import",
            /(?:from\s*|import\s*)['"](?:@radix-ui\/|@mui\/|antd|cmdk)/g,
          ],
          [
            "raw-spacing",
            /\b(?:gap|padding|margin)(?:-[\w-]+)?\s*:\s*[^;\n}]*\b[1-9]\d*(?:\.\d+)?(?:px|rem)\b/g,
          ],
        ];
  return rules.flatMap(([rule, regex]) =>
    [...source.matchAll(regex)].map((m) => ({
      rule,
      line: source.slice(0, m.index).split("\n").length,
    })),
  );
}

function scan(path) {
  const entries = readdirSync(path, { withFileTypes: true });
  return entries.flatMap((entry) => {
    if (
      entry.isSymbolicLink() ||
      ["node_modules", ".git", ".dart_tool", "build", "dist"].includes(
        entry.name,
      )
    )
      return [];
    const file = join(path, entry.name);
    if (entry.isDirectory()) return scan(file);
    const extension = extname(file);
    if (![".tsx", ".jsx", ".dart", ".css"].includes(extension)) return [];
    return findings(readFileSync(file, "utf8"), extension).map((f) => ({
      file,
      ...f,
    }));
  });
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href
) {
  const roots = process.argv.slice(2);
  if (!roots.length) {
    console.error(
      "Usage: node check-consumer-ui.mjs <consumer-source-directory> [...]",
    );
    process.exitCode = 2;
  } else {
    const results = roots.flatMap((root) => scan(resolve(root)));
    for (const f of results) console.log(`${f.file}:${f.line} ${f.rule}`);
    console.log(
      `${results.length} findings requiring review (heuristic scanner).`,
    );
    process.exitCode = results.length ? 1 : 0;
  }
}
