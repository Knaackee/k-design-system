#!/usr/bin/env node
// Decision 0010 geometry parity, Web half.
//
// Reads the Flutter measurements written by
// apps/widgetbook/test/geometry_parity_test.dart, measures the Storybook story
// Review/GeometryParity under the same configurations and fails when a size
// differs by more than the tolerance.
//
// Usage:
//   (cd apps/widgetbook && flutter test test/geometry_parity_test.dart)
//   pnpm build:storybook
//   node tooling/geometry-parity.mjs [--json]
// Writes build/geometry-parity.txt.
import { createRequire } from "node:module";
import { createServer } from "node:http";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize, resolve } from "node:path";

const root = resolve(new URL("..", import.meta.url).pathname);
const staticDir = join(root, "apps/storybook/storybook-static");
const flutterFile = join(
  root,
  "apps/widgetbook/build/geometry-parity.flutter.json",
);
const storyId = "review-geometryparity--reference";
const json = process.argv.includes("--json");

/** Must match `_configurations` in geometry_parity_test.dart. */
export const configurations = {
  phone: { viewport: { width: 393, height: 852 }, touch: true },
  desktop: { viewport: { width: 1280, height: 800 }, touch: false },
};
/** CSS px. Text shaping differs by sub-pixels between Skia and Chromium. */
export const tolerance = 1;

export function compare(flutter, web, axes) {
  const findings = [];
  for (const [key, entries] of Object.entries(flutter)) {
    for (const [id, size] of Object.entries(entries)) {
      const other = web[key]?.[id];
      if (!other) {
        findings.push(`${key} ${id}: missing on Web`);
        continue;
      }
      for (const axis of axes[id] ?? "wh") {
        const delta = other[axis] - size[axis];
        if (Math.abs(delta) > tolerance)
          findings.push(
            `${key} ${id} ${axis === "w" ? "width" : "height"}: ` +
              `Flutter ${size[axis].toFixed(1)} vs Web ${other[axis].toFixed(1)} ` +
              `(${delta > 0 ? "+" : ""}${delta.toFixed(1)})`,
          );
      }
    }
  }
  return findings;
}

function serve() {
  const types = {
    ".html": "text/html",
    ".js": "text/javascript",
    ".css": "text/css",
    ".json": "application/json",
    ".svg": "image/svg+xml",
    ".woff2": "font/woff2",
    ".ttf": "font/ttf",
  };
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

async function main() {
  const flutter = JSON.parse(await readFile(flutterFile, "utf8"));
  const { chromium } = createRequire(import.meta.url)("playwright");
  const browser = await chromium.launch();
  const server = await serve();
  const base = `http://127.0.0.1:${server.address().port}`;
  const web = {};
  for (const key of Object.keys(flutter.measurements)) {
    const [name, scale] = key.split("@");
    const configuration = configurations[name];
    const context = await browser.newContext({
      viewport: configuration.viewport,
      hasTouch: configuration.touch,
      isMobile: configuration.touch,
      deviceScaleFactor: 1,
    });
    const page = await context.newPage();
    await page.goto(
      `${base}/iframe.html?id=${storyId}&viewMode=story&globals=textScale:${Number(scale)}`,
      { waitUntil: "load" },
    );
    await page.waitForSelector("[data-parity]");
    // Text widths are only comparable in Inter, the face Flutter measures
    // with. A web font is fetched lazily, so `document.fonts.ready` can
    // resolve before Inter is requested and the fallback face is measured.
    const font = await page.evaluate(async () => {
      const faces = ["400 16px Inter", "500 16px Inter", "600 16px Inter"];
      await Promise.all(faces.map((face) => document.fonts.load(face)));
      await document.fonts.ready;
      return faces.filter((face) => !document.fonts.check(face));
    });
    if (font.length)
      throw new Error(
        `Inter did not load (${font.join(", ")}); widths would be measured in a fallback face.`,
      );
    web[key] = await page.evaluate(() =>
      Object.fromEntries(
        [...document.querySelectorAll("[data-parity]")].map((entry) => {
          const target =
            entry.style.alignSelf === "stretch"
              ? entry
              : (entry.firstElementChild ?? entry);
          const rect = target.getBoundingClientRect();
          return [entry.dataset.parity, { w: rect.width, h: rect.height }];
        }),
      ),
    );
    await context.close();
  }
  await browser.close();
  server.close();

  const findings = compare(flutter.measurements, web, flutter.axes);
  const report = [
    `Geometry parity: ${Object.keys(flutter.measurements).length} configurations, ` +
      `${Object.keys(flutter.axes).length} entries, ${findings.length} difference(s) > ${tolerance}px.`,
    ...findings.map((line) => `  DIFF ${line}`),
  ].join("\n");
  await mkdir(join(root, "build"), { recursive: true });
  await writeFile(join(root, "build/geometry-parity.txt"), report + "\n");
  await writeFile(
    join(root, "build/geometry-parity.web.json"),
    JSON.stringify(web, null, 2),
  );
  console.log(json ? JSON.stringify({ findings }, null, 2) : report);
  process.exitCode = findings.length ? 1 : 0;
}

if (import.meta.url === `file://${process.argv[1]}`) await main();
