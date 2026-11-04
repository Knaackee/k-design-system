#!/usr/bin/env node
// Decision 0010 rule gate. Static, deliberately conservative heuristics that
// catch the recurring design faults before human gallery review:
//
//   nested-card       a KCard (Flutter/React) inside another KCard
//   centered-leading  a Row/flex row that centres a leading icon against a
//                     multi-line text block (use KLeading / .k-leading)
//   icon-size         KIcon sizes outside 12 (control glyph), 16/20/24 (text),
//                     32/48 (display: empty states, markers)
//   raw-spacing       numeric EdgeInsets / SizedBox gaps instead of tokens
//   tiny-type         font sizes below 11 px
//
// Usage: node tooling/check-ui-rules.mjs [paths...] [--json]
// Without paths it checks the library packages. Exit code 1 on findings.
// Suppress a reviewed exception on the line itself or the line above with
//   // k-ui-rules-ignore <rule>: <reason>
import { readFile, readdir, stat } from "node:fs/promises";
import { extname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(new URL("..", import.meta.url).pathname);
const args = process.argv.slice(2);
const json = args.includes("--json");
const targets = args.filter((a) => !a.startsWith("--"));
const defaults = [
  "packages/flutter/k_design_ui/lib",
  "packages/web/ui/src",
  "apps/widgetbook/lib",
  "apps/storybook/src",
  "examples",
];
const skip =
  /(^|\/)(generated|node_modules|dist|test|stories)(\/|$)|\.g\.dart$|\.test\./;

async function* files(path) {
  const info = await stat(path);
  if (info.isFile()) return yield path;
  for (const entry of await readdir(path)) {
    const full = join(path, entry);
    if (skip.test(relative(root, full))) continue;
    yield* files(full);
  }
}

const matchParen = (s, open) => {
  let depth = 0;
  for (let i = open; i < s.length; i++) {
    if (s[i] === "(") depth++;
    else if (s[i] === ")" && --depth === 0) return i;
  }
  return s.length;
};
const lineOf = (s, index) => s.slice(0, index).split("\n").length;

function ignored(lines, line, rule) {
  const re = new RegExp(`k-ui-rules-ignore\\s+${rule}\\b`);
  return re.test(lines[line - 1] ?? "") || re.test(lines[line - 2] ?? "");
}

export function checkDart(source, { library = true } = {}) {
  const out = [];
  // nested-card: KCard( ... KCard( within the same call expression.
  for (const m of source.matchAll(/\bKCard\(/g)) {
    const end = matchParen(source, m.index + 5);
    const inner = source.slice(m.index + 6, end).search(/\bKCard\(/);
    if (inner >= 0)
      out.push(["nested-card", lineOf(source, m.index + 6 + inner)]);
  }
  // centered-leading: Row(center) whose children contain a KIcon and a
  // Column (a multi-line text block).
  for (const m of source.matchAll(/\bRow\(/g)) {
    const end = matchParen(source, m.index + 3);
    const body = source.slice(m.index, end);
    const own = body.replace(
      /\b(Row|Column)\((?:[^()]|\([^()]*\))*\)/gs,
      (x, k, o) => (o === 0 ? x : ""),
    );
    const centered =
      /crossAxisAlignment:\s*CrossAxisAlignment\.center/.test(own) ||
      !/crossAxisAlignment:/.test(body.slice(0, body.indexOf("children:")));
    // Only a bare leading icon counts; media tiles/avatars at least two
    // lines tall may centre (they are not text-sized glyphs).
    const children = body.slice(body.indexOf("children:"));
    const leadingIcon =
      /^children:\s*\[\s*(?:if\s*\([^)]*\)\s*(?:\.\.\.\[\s*)?)?(?:const\s+)?KIcon\(/.test(
        children,
      );
    if (centered && leadingIcon && /\bColumn\(/.test(body))
      out.push(["centered-leading", lineOf(source, m.index)]);
  }
  for (const m of source.matchAll(/\bKIcon\([^)]*?\bsize:\s*([0-9.]+)/gs)) {
    if (![12, 16, 20, 24, 32, 48].includes(Number(m[1])))
      out.push(["icon-size", lineOf(source, m.index)]);
  }
  // Literal numeric insets (arithmetic on tokens such as `gap * 2` is allowed).
  // Library code must use tokens; gallery/consumer frames may use literals
  // only on the 4 px grid.
  const grid = new Set([2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64]);
  for (const m of source.matchAll(
    /EdgeInsets\.(?:all|only|symmetric|fromLTRB)\(([^()]*)\)/g,
  )) {
    const literals = m[1]
      .split(",")
      .map((part) => part.replace(/^\s*\w+\s*:/, "").trim())
      .flatMap((value) =>
        [
          ...value.matchAll(
            /(?:^|[?:]\s*)([1-9][0-9]*(?:\.[0-9]+)?)(?=\s*$|\s*:)/g,
          ),
        ].map((n) => Number(n[1])),
      );
    if (literals.some((n) => library || !grid.has(n)))
      out.push(["raw-spacing", lineOf(source, m.index)]);
  }
  for (const m of source.matchAll(/fontSize:\s*([0-9]+(?:\.[0-9]+)?)\b/g))
    if (Number(m[1]) < 11) out.push(["tiny-type", lineOf(source, m.index)]);
  return out;
}

export function checkWeb(source, ext) {
  const out = [];
  if (ext === ".tsx") {
    for (const m of source.matchAll(/<KIcon\b[^>]*?size=\{([0-9.]+)\}/gs))
      if (![12, 16, 20, 24, 32, 48].includes(Number(m[1])))
        out.push(["icon-size", lineOf(source, m.index)]);
    // nested-card in one JSX tree: <KCard ...> ... <KCard
    const re = /<KCard\b|<\/KCard>/g;
    let depth = 0;
    for (const m of source.matchAll(re)) {
      if (m[0] === "</KCard>") depth = Math.max(0, depth - 1);
      else {
        const selfClosing = /^<KCard\b[^>]*\/>/s.test(source.slice(m.index));
        if (depth > 0) out.push(["nested-card", lineOf(source, m.index)]);
        if (!selfClosing) depth++;
      }
    }
  }
  if (ext === ".css") {
    for (const m of source.matchAll(/font-size:\s*([0-9.]+)px/g))
      if (Number(m[1]) < 11) out.push(["tiny-type", lineOf(source, m.index)]);
    for (const m of source.matchAll(/\.k-card[^{,]*\s\.k-card\b[^{]*\{/g))
      out.push(["nested-card", lineOf(source, m.index)]);
  }
  return out;
}

async function main() {
  const findings = [];
  for (const target of targets.length ? targets : defaults) {
    for await (const file of files(resolve(root, target))) {
      const ext = extname(file);
      if (![".dart", ".tsx", ".css"].includes(ext)) continue;
      const source = await readFile(file, "utf8");
      const lines = source.split("\n");
      const library = relative(root, file).startsWith("packages/");
      const found =
        ext === ".dart"
          ? checkDart(source, { library })
          : checkWeb(source, ext);
      for (const [rule, line] of found)
        if (!ignored(lines, line, rule))
          findings.push({ rule, file: relative(root, file), line });
    }
  }

  if (json) console.log(JSON.stringify(findings, null, 2));
  else {
    for (const f of findings) console.log(`${f.file}:${f.line}  ${f.rule}`);
    const counts = Object.entries(
      findings.reduce((a, f) => ((a[f.rule] = (a[f.rule] ?? 0) + 1), a), {}),
    );
    console.log(
      findings.length
        ? `\n${findings.length} finding(s): ${counts.map(([r, n]) => `${r} ${n}`).join(", ")}`
        : "UI rule check passed.",
    );
  }
  process.exitCode = findings.length ? 1 : 0;
}

if (
  process.argv[1] &&
  resolve(process.argv[1]) === fileURLToPath(import.meta.url)
)
  await main();
