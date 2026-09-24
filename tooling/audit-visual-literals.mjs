import { readFile, readdir, writeFile } from "node:fs/promises";
import { dirname, extname, relative, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const baselinePath = resolve(root, "tooling/visual-literals-baseline.json");
const sourceRoots = [
  resolve(root, "packages/web/ui/src"),
  resolve(root, "packages/flutter/k_design_ui/lib/src"),
];

const rules = {
  css: [
    ["color", /#[0-9a-f]{3,8}\b|(?:rgb|hsl)a?\([^)]*\)/gi],
    [
      "appearance",
      /(?:border-radius|box-shadow|opacity|font-size|outline(?:-width|-offset)?|border(?:-(?:top|right|bottom|left|inline-start|inline-end|block-start|block-end))?(?:-width)?)\s*:\s*[^;}]*\d[^;}]*[;}]/gi,
    ],
    [
      "dimension",
      /(?:gap|row-gap|column-gap|padding(?:-(?:top|right|bottom|left|inline|inline-start|inline-end|block|block-start|block-end))?|margin(?:-(?:top|right|bottom|left|inline|inline-start|inline-end|block|block-start|block-end))?|(?:min-|max-)?(?:width|height)|inset(?:-(?:inline|block|inline-start|inline-end|block-start|block-end))?|top|right|bottom|left)\s*:\s*[^;}]*\b\d+(?:\.\d+)?(?:px|rem|em)\b[^;}]*[;}]/gi,
    ],
    [
      "motion",
      /(?:animation|transition)[^;}]*\b\d+(?:\.\d+)?(?:ms|s)\b[^;}]*[;}]/gi,
    ],
  ],
  dart: [
    [
      "color",
      /\bColor\(0x[0-9a-f]+\)|\bColors\.(?:white|black|red|green|blue|amber|grey)\b/gi,
    ],
    [
      "radius",
      /\b(?:BorderRadius|Radius)\.circular\(\s*(?!0(?:\.0)?\b)\d+(?:\.\d+)?/g,
    ],
    [
      "opacity",
      /\b(?:opacity|alpha)\s*:\s*(?!0(?:\.0)?\b|1(?:\.0)?\b)\.??\d+(?:\.\d+)?/g,
    ],
    ["type", /\bfontSize\s*:\s*(?!0(?:\.0)?\b)\d+(?:\.\d+)?/g],
    ["motion", /\bDuration\(\s*milliseconds\s*:\s*(?!0\b)\d+/g],
    [
      "dimension",
      /\b(?:width|height|minWidth|minHeight|maxWidth|maxHeight|horizontal|vertical|top|right|bottom|left|dimension|strokeWidth|blurRadius|spreadRadius)\s*:\s*(?!0(?:\.0)?\b)\d+(?:\.\d+)?/g,
    ],
    ["spacing", /\bEdgeInsets\.all\(\s*(?!0(?:\.0)?\b)\d+(?:\.\d+)?/g],
  ],
};

const normalizeLine = (line) => line.trim().replace(/\s+/g, " ");

const hasRawAppearanceValue = (declaration) => {
  if (/^\s*border[^:]*:\s*var\(/i.test(declaration)) return false;
  const withoutAliases = declaration.replace(/var\([^)]*\)/g, "");
  if (/-?(?:\d+\.?\d*|\.\d+)(?:px|rem|em|%)/i.test(withoutAliases)) {
    return true;
  }
  const opacity = withoutAliases.match(
    /opacity\s*:\s*(-?(?:\d+\.?\d*|\.\d+))/i,
  );
  return opacity != null && ![0, 1].includes(Number(opacity[1]));
};

const hasRawDimensionValue = (declaration) => {
  const withoutAliases = declaration
    .replace(/var\([^)]*\)/g, "")
    .replace(/env\([^)]*\)/g, "");
  return /(?:^|[^\d.])-?(?!0(?:\.0+)?(?:px|rem|em)\b)\d+(?:\.\d+)?(?:px|rem|em)\b/i.test(
    withoutAliases,
  );
};

export function auditSource(source, extension, path = "fixture") {
  const candidates = [];
  const sourceLines = source.split(/\r?\n/);
  const applicable = rules[extension === ".css" ? "css" : "dart"] ?? [];
  for (const [rule, expression] of applicable) {
    for (const match of source.matchAll(expression)) {
      if (rule === "appearance" && !hasRawAppearanceValue(match[0])) continue;
      const line = source.slice(0, match.index).split(/\r?\n/).length;
      const sourceLine = normalizeLine(sourceLines[line - 1] ?? match[0]);
      if (sourceLine.startsWith("@media")) continue;
      if (
        extension === ".css" &&
        rule === "dimension" &&
        !hasRawDimensionValue(match[0])
      ) {
        continue;
      }
      candidates.push({
        path,
        rule,
        line,
        source: sourceLine,
      });
    }
  }
  return candidates;
}

async function walk(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const path = resolve(directory, entry.name);
    if (entry.isDirectory()) {
      if (entry.name !== "generated") files.push(...(await walk(path)));
    } else if ([".css", ".dart"].includes(extname(entry.name))) {
      files.push(path);
    }
  }
  return files;
}

function signature(candidate) {
  return `${candidate.path}|${candidate.rule}|${candidate.source}`;
}

function summarize(candidates) {
  const entries = new Map();
  for (const candidate of candidates) {
    const key = signature(candidate);
    entries.set(key, (entries.get(key) ?? 0) + 1);
  }
  return Object.fromEntries(
    [...entries].sort(([a], [b]) => a.localeCompare(b)),
  );
}

async function collect() {
  const candidates = [];
  for (const directory of sourceRoots) {
    for (const path of await walk(directory)) {
      const source = await readFile(path, "utf8");
      const repoPath = relative(root, path).replaceAll("\\", "/");
      candidates.push(...auditSource(source, extname(path), repoPath));
    }
  }
  return candidates;
}

async function main() {
  const currentCandidates = await collect();
  const current = summarize(currentCandidates);
  if (process.argv.includes("--write-baseline")) {
    await writeFile(
      baselinePath,
      `${JSON.stringify({ version: 1, entries: current }, null, 2)}\n`,
    );
    console.log(
      `Recorded ${Object.keys(current).length} visual-literal exceptions.`,
    );
    return;
  }

  const baseline = JSON.parse(await readFile(baselinePath, "utf8"));
  const allowedCount = (key) => {
    const entry = baseline.entries[key];
    return typeof entry === "number" ? entry : (entry?.count ?? 0);
  };
  const additions = Object.entries(current).filter(
    ([key, count]) => count > allowedCount(key),
  );
  if (additions.length === 0) {
    console.log("Visual-literal audit passed.");
    return;
  }

  console.error("Unapproved visual literals found:");
  for (const [key, count] of additions) {
    console.error(`- ${key} (+${count - allowedCount(key)})`);
  }
  console.error(
    "Use an existing token, add an approved token, or review and update the baseline deliberately.",
  );
  process.exitCode = 1;
}

if (import.meta.url === pathToFileURL(process.argv[1] ?? "").href) await main();
