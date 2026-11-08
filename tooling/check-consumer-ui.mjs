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
          // Decision 0015: appearance comes from the style; apps do not set it.
          ["icon-stroke", /\bKIcon\s*\([^)]*\bstrokeWidth\s*:/gs],
          [
            "appearance-override",
            /\bKAdaptiveOverrides\s*\([^)]*\b(?:style|density|typeScale|motion)\s*:/gs,
          ],
          // A card with a chevron is a hand-built list row: use KListItem.
          [
            "hand-built-row",
            /\bKCard\s*\((?:(?!\bKCard\s*\()[\s\S]){0,600}?KIconName\.chevronRight/g,
          ],
          // A control in a row's trailing slot: only it responds. Use menu:,
          // switchValue: or onPressed: (on/off settings always a switch).
          [
            "split-row",
            /\bKListItem\s*\((?:(?!\bKListItem\s*\()[\s\S]){0,600}?\btrailing\s*:\s*(?:const\s+)?K(?:IconButton|MenuButton|Switch|Checkbox|Button)\s*\(/g,
          ],
          // Steps use KOnboarding: footer fixed at the bottom on every step.
          ["hand-built-steps", /\bKProgressDots\s*\(/g],
          // Menu and history buttons belong in KPageHeader(leading:), which
          // puts them at the start of the phone top bar.
          [
            "content-nav-button",
            /(?<!\bleading\s*:\s*(?:const\s+)?)\bKIconButton\s*\((?:(?!\bKIconButton\s*\()[\s\S]){0,300}?KIconName\.(?:menu|panelLeft|panelLeftOpen|history)\b/g,
          ],
          // The shell's top bar covers the status bar itself; a SafeArea
          // around it leaves a second band above the bar.
          [
            "safe-area-shell",
            /\bSafeArea\s*\((?:(?!\bSafeArea\s*\()[\s\S]){0,200}?\bKAppShell\s*\(/g,
          ],
          // Content refreshes on its own and by pulling (KPage(onRefresh:)),
          // not from a refresh button.
          [
            "refresh-button",
            /\bK(?:Icon)?Button\s*\((?:(?!\bK(?:Icon)?Button\s*\()[\s\S]){0,300}?KIconName\.refresh(?:Cw|Ccw)?\b/g,
          ],
          // Pages scroll in KPage (gutter, safe areas, readable width).
          [
            "bare-page",
            /\bbody\s*:\s*(?:const\s+)?SingleChildScrollView\s*\(/g,
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
          // Decision 0015: appearance comes from the style; apps do not set it.
          ["icon-stroke", /<KIcon\b[^>]*\bstrokeWidth=/gs],
          [
            "appearance-override",
            /\bdata-(?:style|density|type-scale|motion)=|\boverrides\s*[:=]\s*\{?\s*\{[^}]*\b(?:style|density|typeScale|motion)\s*:/g,
          ],
          [
            "split-row",
            /<KListItem\b[^>]*\btrailing=\{\s*<K(?:IconButton|MenuButton|Switch|Checkbox|Button)\b/gs,
          ],
          ["hand-built-steps", /<KProgressDots\b/g],
          [
            "content-nav-button",
            /(?<!\bleading=\{\s*)<KIconButton\b[^>]*\bicon="(?:menu|panel-left|panel-left-open|history)"/gs,
          ],
          [
            "refresh-button",
            /<K(?:Icon)?Button\b[^>]*\bicon="refresh(?:-cw|-ccw)?"/gs,
          ],
          // A card with a chevron is a hand-built list row: use KListItem.
          [
            "hand-built-row",
            /<KCard\b(?:(?!<\/KCard>)[\s\S]){0,800}?chevron-right/g,
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
