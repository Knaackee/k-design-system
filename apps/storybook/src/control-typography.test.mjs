import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { readFile, writeFile } from "node:fs/promises";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const output = process.env.KDS_PARITY_OUTPUT;
if (!output)
  throw Error("Set KDS_PARITY_OUTPUT to fresh actions-parity screenshots");
const cases = JSON.parse(await readFile(`${output}/results.json`, "utf8"));
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage();
const results = [];
try {
  for (const fixture of cases) {
    const density = fixture.name.split("-")[2];
    // Current density contract: visual height, inline inset, icon gap.
    const metrics = {
      dense: [32, 8, 4],
      standard: [36, 12, 8],
      spacious: [44, 16, 12],
    }[density];
    const pair = {};
    for (const platform of ["web", "flutter"]) {
      const png = (
        await readFile(`${output}/${fixture.name}-${platform}.png`)
      ).toString("base64");
      pair[platform] = await page.evaluate(
        async ({ png, measurements, platform, metrics }) => {
          const image = new Image();
          image.src = `data:image/png;base64,${png}`;
          await image.decode();
          const canvas = document.createElement("canvas");
          canvas.width = image.width;
          canvas.height = image.height;
          const ctx = canvas.getContext("2d");
          ctx.drawImage(image, 0, 0);
          const { data } = ctx.getImageData(0, 0, image.width, image.height);
          const pixel = (x, y) => [
            ...data.slice(
              (y * image.width + x) * 4,
              (y * image.width + x) * 4 + 3,
            ),
          ];
          return measurements.slice(0, 2).map((m) => {
            const r = m[platform],
              [height, inset, gap] = metrics;
            const centerY = r.y + r.height / 2;
            const left = Math.floor(r.x + inset + 1);
            const right = Math.ceil(
              r.x +
                r.width -
                inset -
                1 -
                (m.label === "Actions" ? 16 + gap : 0),
            );
            const top = Math.ceil(centerY - height / 2 + 2),
              bottom = Math.floor(centerY + height / 2 - 2);
            const bg = pixel(Math.floor(r.x + 3), Math.floor(centerY));
            const contrast = (x, y) =>
              Math.sqrt(
                pixel(x, y).reduce((sum, v, i) => sum + (v - bg[i]) ** 2, 0),
              );
            let norm = 0;
            for (let y = top; y < bottom; y++)
              for (let x = left; x < right; x++)
                norm = Math.max(norm, contrast(x, y));
            let mass = 0,
              moment = 0,
              minY = Infinity,
              maxY = -Infinity;
            for (let y = top; y < bottom; y++)
              for (let x = left; x < right; x++) {
                const coverage = contrast(x, y) / norm;
                // Ignore weak raster noise, retain antialiased glyph coverage.
                if (coverage < 0.15) continue;
                mass += coverage;
                moment += (y + 0.5 - centerY) * coverage;
                if (coverage > 0.5) {
                  minY = Math.min(minY, y);
                  maxY = Math.max(maxY, y);
                }
              }
            return {
              label: m.label,
              center: moment / mass,
              height: maxY - minY + 1,
              mass,
            };
          });
        },
        { png, measurements: fixture.measurements, platform, metrics },
      );
    }
    for (let i = 0; i < 2; i++) {
      results.push({
        name: fixture.name,
        label: pair.web[i].label,
        web: pair.web[i],
        flutter: pair.flutter[i],
        centerDelta: Math.abs(pair.web[i].center - pair.flutter[i].center),
      });
    }
  }
  await writeFile(
    `${output}/typography.json`,
    JSON.stringify(results, null, 2),
  );
  const failures = results.filter(
    (r) =>
      !Number.isFinite(r.centerDelta) ||
      r.centerDelta > 0.45 ||
      Math.abs(r.web.height - r.flutter.height) > 1,
  );
  console.log(
    `Ink comparisons: ${results.length}; largest vertical centroid difference: ${Math.max(...results.map((r) => r.centerDelta)).toFixed(3)}px`,
  );
  assert.deepEqual(
    failures,
    [],
    "Control glyphs are vertically shifted or differently sized",
  );
} finally {
  await browser.close();
}
