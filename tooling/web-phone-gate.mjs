#!/usr/bin/env node
// Web phone gate (Decision 0010) — the Storybook twin of
// apps/widgetbook/test/phone_gate_test.dart.
//
// Renders every story of the built Storybook (apps/storybook/storybook-static)
// on phone viewports (360 and 393 CSS px) with a coarse primary pointer at
// text scales 1.0, 1.3 and 2.0, and fails when a story overflows the screen
// horizontally:
//
//   page-overflow   the document is wider than the viewport
//   offscreen       a visible element ends beyond the right edge and is not
//                   inside a horizontally scrolling or clipping container
//
// 3.0 is measured and reported, but does not fail the gate (see ADR 0010).
//
// Known findings: tooling/web-phone-gate.known.json lists stories that
// overflowed when the gate was introduced, each with the finding. They are
// reported as KNOWN and do not fail; a new story failing does, and so does a
// listed story that now passes (STALE: delete its entry). The list only
// shrinks. `--write-known` rewrites it from the current run (review the diff).
//
// Usage: node tooling/web-phone-gate.mjs [--filter <substring>] [--json]
// Requires `pnpm build:storybook` first. Writes build/web-phone-gate.txt.
import { createServer } from "node:http";
import { createRequire } from "node:module";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize, resolve } from "node:path";

const root = resolve(new URL("..", import.meta.url).pathname);
const staticDir = join(root, "apps/storybook/storybook-static");
const args = process.argv.slice(2);
const filter = args.includes("--filter")
  ? args[args.indexOf("--filter") + 1]
  : "";
const json = args.includes("--json");
const writeKnown = args.includes("--write-known");
const knownFile = join(root, "tooling/web-phone-gate.known.json");

export const phones = [
  { width: 360, height: 740 },
  { width: 393, height: 852 },
];
export const gatingScales = [1, 1.3, 2];
export const reportScales = [3];

// Stories that need a device, network or WebGL; mirrors `_headless` in the
// Flutter gate. Each entry needs a reason; the report still lists them.
export const headless = {
  maps: "map tiles and WebGL need a device",
  video: "media playback needs a device",
  browser: "embedded browser surface needs a device",
  presentation: "remote presentation images need network",
};

const types = {
  ".html": "text/html",
  ".js": "text/javascript",
  ".mjs": "text/javascript",
  ".css": "text/css",
  ".json": "application/json",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".woff2": "font/woff2",
  ".ttf": "font/ttf",
  ".riv": "application/octet-stream",
  ".wasm": "application/wasm",
};

function serve() {
  const server = createServer(async (request, response) => {
    const path = normalize(decodeURIComponent(request.url.split("?")[0]));
    const file = join(staticDir, path === "/" ? "index.html" : path);
    if (!file.startsWith(staticDir)) return response.writeHead(403).end();
    try {
      const body = await readFile(file);
      response.writeHead(200, {
        "content-type": types[extname(file)] ?? "application/octet-stream",
      });
      response.end(body);
    } catch {
      response.writeHead(404).end();
    }
  });
  return new Promise((done) =>
    server.listen(0, "127.0.0.1", () => done(server)),
  );
}

// Runs in the page. Returns overflow findings for the current story.
function measure() {
  const width = document.documentElement.clientWidth;
  const findings = [];
  if (document.documentElement.scrollWidth > width + 1)
    findings.push(
      `page-overflow ${document.documentElement.scrollWidth - width}px`,
    );
  const contained = (element) => {
    for (let node = element.parentElement; node; node = node.parentElement) {
      if (node === document.body) return false;
      const style = getComputedStyle(node);
      if (/(auto|scroll|hidden|clip)/.test(style.overflowX)) return true;
      if (style.position === "fixed") return false;
    }
    return false;
  };
  const describe = (element) =>
    element.tagName.toLowerCase() +
    (element.className && typeof element.className === "string"
      ? "." + element.className.trim().split(/\s+/).slice(0, 2).join(".")
      : "");
  for (const element of document.querySelectorAll("#storybook-root *")) {
    const rect = element.getBoundingClientRect();
    if (rect.width === 0 || rect.height === 0) continue;
    if (rect.right <= width + 1) continue;
    const style = getComputedStyle(element);
    if (style.visibility === "hidden" || style.position === "fixed") continue;
    if (contained(element)) continue;
    findings.push(
      `offscreen ${describe(element)} +${Math.round(rect.right - width)}px`,
    );
    if (findings.length >= 3) break;
  }
  return findings;
}

async function main() {
  const index = JSON.parse(
    await readFile(join(staticDir, "index.json"), "utf8"),
  );
  const stories = Object.values(index.entries).filter(
    (entry) =>
      entry.type === "story" &&
      (!filter || `${entry.title}/${entry.name}`.includes(filter)),
  );
  // Playwright is a machine tool, not a repo dependency; resolve it the way
  // CommonJS does (NODE_PATH / global install).
  const { chromium } = createRequire(import.meta.url)("playwright");
  const browser = await chromium.launch();
  const server = await serve();
  const base = `http://127.0.0.1:${server.address().port}`;
  const failures = [];
  const large = [];
  const skipped = [];

  const concurrency = Number(process.env.K_PHONE_GATE_WORKERS ?? 8);
  let done = 0;
  for (const phone of phones) {
    const context = await browser.newContext({
      viewport: phone,
      hasTouch: true,
      isMobile: true,
      deviceScaleFactor: 1,
    });
    const queue = [...stories];
    const check = async (page, story) => {
      const key = `${story.title}/${story.name}`;
      const reason = Object.entries(headless).find(([word]) =>
        key.toLowerCase().includes(word),
      );
      if (reason) {
        if (phone === phones[0]) skipped.push(`${key} (${reason[1]})`);
        return;
      }
      for (const scale of [...gatingScales, ...reportScales]) {
        const url = `${base}/iframe.html?id=${story.id}&viewMode=story&globals=textScale:${scale}`;
        let findings;
        try {
          await page.goto(url, { waitUntil: "load", timeout: 30000 });
          await page.waitForSelector("#storybook-root > *", { timeout: 10000 });
          await page.waitForTimeout(150);
          findings = await page.evaluate(measure);
        } catch (error) {
          if (phone === phones[0] && scale === 1)
            skipped.push(`${key} (${String(error).split("\n")[0]})`);
          return;
        }
        if (findings.length === 0) continue;
        const line = `${key} @ ${phone.width} text ${scale}x: ${findings.join("; ")}`;
        if (gatingScales.includes(scale)) {
          failures.push(line);
          return; // one finding per story is enough to act on
        }
        large.push(line);
      }
    };
    await Promise.all(
      Array.from({ length: concurrency }, async () => {
        const page = await context.newPage();
        for (let story; (story = queue.shift());) {
          await check(page, story);
          if (++done % 100 === 0)
            process.stderr.write(
              `  ${done}/${stories.length * phones.length}\n`,
            );
        }
        await page.close();
      }),
    );
    await context.close();
  }
  failures.sort();
  large.sort();
  skipped.sort();
  await browser.close();
  server.close();

  const known = JSON.parse(await readFile(knownFile, "utf8").catch(() => "{}"));
  const storyOf = (line) => line.slice(0, line.indexOf(" @ "));
  const failing = new Set(failures.map(storyOf));
  const fresh = failures.filter((line) => !(storyOf(line) in known));
  const listed = failures.filter((line) => storyOf(line) in known);
  const stale = filter
    ? []
    : Object.keys(known).filter((key) => !failing.has(key));
  if (writeKnown) {
    const next = Object.fromEntries(
      [...new Set(failures.map(storyOf))].sort().map((key) => [
        key,
        known[key] ??
          failures
            .find((line) => storyOf(line) === key)
            .split(": ")
            .slice(1)
            .join(": "),
      ]),
    );
    await writeFile(knownFile, JSON.stringify(next, null, 2) + "\n");
  }

  const report = [
    `Web phone gate: ${stories.length} stories, ${fresh.length} new overflow(s), ` +
      `${listed.length} known, ${stale.length} stale known entr${stale.length === 1 ? "y" : "ies"}, ` +
      `${large.length} at 3.0x (reported), ${skipped.length} skipped (not verified).`,
    ...fresh.map((line) => `  OVERFLOW ${line}`),
    ...stale.map(
      (key) =>
        `  STALE    ${key} passes now; remove it from web-phone-gate.known.json`,
    ),
    ...listed.map((line) => `  KNOWN    ${line}`),
    ...large.map((line) => `  LARGE    ${line}`),
    ...skipped.map((line) => `  skipped  ${line}`),
  ].join("\n");
  await mkdir(join(root, "build"), { recursive: true });
  await writeFile(join(root, "build/web-phone-gate.txt"), report + "\n");
  if (json)
    console.log(
      JSON.stringify({ fresh, stale, listed, large, skipped }, null, 2),
    );
  else console.log(report);
  process.exitCode = fresh.length || (stale.length && !writeKnown) ? 1 : 0;
}

await main();
