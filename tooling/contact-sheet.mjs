#!/usr/bin/env node
// Visual review sheet: renders a Storybook story at phone, tablet and desktop
// sizes for each style preset and writes one PNG per style next to --out.
// Usage: node tooling/contact-sheet.mjs --story <id> --out <dir> [--styles apple,linear]
import { createRequire } from "node:module";
import { createServer } from "node:http";
import { mkdir, readFile } from "node:fs/promises";
import { extname, join, normalize, resolve } from "node:path";

const root = resolve(new URL("..", import.meta.url).pathname);
const dir = join(root, "apps/storybook/storybook-static");
const arg = (name, fallback) => {
  const index = process.argv.indexOf(`--${name}`);
  return index > -1 ? process.argv[index + 1] : fallback;
};
const story = arg("story");
const out = resolve(arg("out", "build/contact-sheets"));
const styles = arg("styles", "apple,linear").split(",");
const shots = [
  ["Phone 393 · 100 %", 393, 852, true, 1],
  ["Phone 393 · 130 %", 393, 852, true, 1.3],
  ["Phone 393 · 200 %", 393, 852, true, 2],
  ["Phone 393 · 300 %", 393, 852, true, 3],
  ["Tablet 820", 820, 1180, true, 1],
  ["Desktop 1280", 1280, 800, false, 1],
];
const types = {
  ".html": "text/html",
  ".js": "text/javascript",
  ".css": "text/css",
  ".json": "application/json",
  ".woff2": "font/woff2",
  ".svg": "image/svg+xml",
  ".ttf": "font/ttf",
  ".png": "image/png",
  ".wav": "audio/wav",
};
const server = createServer(async (req, res) => {
  let path = normalize(join(dir, decodeURIComponent(req.url.split("?")[0])));
  if (path.endsWith("/")) path += "index.html";
  try {
    const body = await readFile(path);
    res.writeHead(200, {
      "content-type": types[extname(path)] ?? "application/octet-stream",
    });
    res.end(body);
  } catch {
    res.writeHead(404);
    res.end();
  }
}).listen(0);
const { chromium } = createRequire(import.meta.url)("playwright");
const browser = await chromium.launch({ args: ["--font-render-hinting=none"] });
await mkdir(out, { recursive: true });
for (const style of styles) {
  for (const [label, width, height, touch, scale] of shots) {
    const page = await browser.newPage({
      viewport: { width, height },
      hasTouch: touch,
      isMobile: touch,
      deviceScaleFactor: 2,
    });
    await page.goto(
      `http://localhost:${server.address().port}/iframe.html?id=${story}&viewMode=story&globals=style:${style};textScale:${scale}`,
      { waitUntil: "load" },
    );
    // Wait for the story itself, not only the page: Storybook shows a
    // loading spinner first.
    await page.waitForFunction(
      () =>
        document.querySelector("#storybook-root")?.childElementCount > 0 &&
        !document.querySelector(".sb-show-preparing-story"),
      null,
      { timeout: 30000 },
    );
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(300);
    const file = join(out, `${style}-${width}-${scale.toFixed(1)}.png`);
    await page.screenshot({ path: file });
    console.log(`${style} · ${label} → ${file}`);
    await page.close();
  }
}
await browser.close();
server.close();
