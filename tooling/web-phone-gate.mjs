#!/usr/bin/env node
// Web phone gate (Decision 0010) — the Storybook twin of
// apps/widgetbook/test/gates/phone_gate.dart (`pnpm gate:phone-flutter`).
//
// Renders every story of the built Storybook (apps/storybook/storybook-static)
// on phone viewports (360 and 393 CSS px) with a coarse primary pointer at
// text scales 1.0, 1.3, 2.0 and 3.0 (the body/control cap), and fails when a
// story overflows the screen horizontally:
//
//   page-overflow   the document is wider than the viewport
//   offscreen       a visible element ends beyond the right edge and is not
//                   inside a horizontally scrolling or clipping container
//
// A story that does not load (timeout, crash) is retried once and then fails
// the gate: an unverified story is not a passed one. Only stories that need a
// device or network (`headless`) are skipped, and the report lists them.
//
// Usage: node tooling/web-phone-gate.mjs [--filter <a|b|id>] [--json]
// Requires `pnpm build:storybook` first. Writes build/web-phone-gate.txt.
import { createServer } from "node:http";
import { createRequire } from "node:module";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("..", import.meta.url));
const staticDir = join(root, "apps/storybook/storybook-static");
const args = process.argv.slice(2);
const filter = args.includes("--filter")
  ? args[args.indexOf("--filter") + 1]
  : "";
const json = args.includes("--json");

export const phones = [
  { width: 360, height: 740 },
  { width: 393, height: 852 },
];
export const scales = [1, 1.3, 2, 3];

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
      (!filter ||
        filter
          .split("|")
          .some(
            (part) =>
              `${entry.title}/${entry.name}`.includes(part) ||
              entry.id === part,
          )),
  );
  // Playwright is a machine tool, not a repo dependency; resolve it the way
  // CommonJS does (NODE_PATH / global install).
  const { chromium } = createRequire(import.meta.url)("playwright");
  // Linux Chromium follows the machine's font hinting; with full hinting
  // (GitHub runners) glyph advances round to whole pixels and labels grow
  // 1-4 px wider than Flutter. Unhinted text matches Flutter and is the
  // same on every machine.
  const browser = await chromium.launch({
    args: ["--font-render-hinting=none"],
  });
  const server = await serve();
  const base = `http://127.0.0.1:${server.address().port}`;
  const failures = [];
  const unloaded = [];
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
    // Phones draw overlay scrollbars that take no width. Headless Chromium
    // reserves a classic one, which scroll locks (sheets, dialogs) then
    // compensate with padding and report as overflow.
    await context.addInitScript(() => {
      addEventListener("DOMContentLoaded", () => {
        const style = document.createElement("style");
        style.textContent = "html { scrollbar-width: none; }";
        document.head.append(style);
      });
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
      // Load once per phone, then step the text scale in place the way the
      // Storybook decorator applies it (setKTextScale: `--k-text-scale` and
      // `data-text-large`). One load instead of one per scale keeps the gate
      // at a quarter of the time; layout reacts to the CSS change exactly as
      // to an in-app text size setting.
      const url = `${base}/iframe.html?id=${story.id}&viewMode=story&globals=textScale:1`;
      let loaded = false;
      let lastError;
      for (let attempt = 0; attempt < 2 && !loaded; attempt++) {
        try {
          // DOM ready, not "load": a story that requests a blocked remote asset
          // never fires "load", but renders.
          await page.goto(url, {
            waitUntil: "domcontentloaded",
            timeout: 45000,
          });
          await page.waitForSelector("#storybook-root > *", {
            timeout: 15000,
          });
          loaded = true;
        } catch (error) {
          lastError = error;
        }
      }
      if (!loaded) {
        unloaded.push(
          `${key} @ ${phone.width}: ${String(lastError).split("\n")[0]}`,
        );
        return;
      }
      for (const scale of scales) {
        await page.evaluate(async (scale) => {
          const root = document.documentElement;
          root.style.setProperty("--k-text-scale", String(scale));
          root.toggleAttribute("data-text-large", scale >= 1.3);
          // Force style and layout, then give ResizeObserver-driven updates
          // a turn. Timers, not animation frames: pages that are not in
          // front get no frames in headless Chromium.
          void document.body.offsetHeight;
          await new Promise((done) => setTimeout(done, 60));
          void document.body.offsetHeight;
        }, scale);
        let result = await page.evaluate(measure);
        if (result.length) {
          // Confirm after transitions and late layout settle; a loaded CI
          // runner must not turn a mid-animation frame into a failure.
          await page.waitForTimeout(400);
          result = await page.evaluate(measure);
        }
        if (result.length === 0) continue;
        failures.push(
          `${key} @ ${phone.width} text ${scale}x: ${result.join("; ")}`,
        );
        return; // one finding per story is enough to act on
      }
    };
    await Promise.all(
      Array.from({ length: concurrency }, async () => {
        for (let story; (story = queue.shift());) {
          // A fresh page per story: timers, pending navigations and history
          // changes of one story never reach the next.
          const page = await context.newPage();
          await check(page, story);
          await page.close();
          if (++done % 100 === 0)
            process.stderr.write(
              `  ${done}/${stories.length * phones.length}\n`,
            );
        }
      }),
    );
    await context.close();
  }
  failures.sort();
  unloaded.sort();
  skipped.sort();
  await browser.close();
  server.close();

  const report = [
    `Web phone gate: ${stories.length} stories, ${failures.length} overflow(s), ` +
      `${unloaded.length} not loaded, ${skipped.length} skipped (need a device or network).`,
    ...failures.map((line) => `  OVERFLOW ${line}`),
    ...unloaded.map((line) => `  NOLOAD   ${line}`),
    ...skipped.map((line) => `  skipped  ${line}`),
  ].join("\n");
  await mkdir(join(root, "build"), { recursive: true });
  await writeFile(join(root, "build/web-phone-gate.txt"), report + "\n");
  if (json)
    console.log(JSON.stringify({ failures, unloaded, skipped }, null, 2));
  else console.log(report);
  process.exitCode = failures.length || unloaded.length ? 1 : 0;
}

await main();
