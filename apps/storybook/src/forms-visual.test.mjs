import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { readFile, writeFile } from "node:fs/promises";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const output = process.env.KDS_PARITY_OUTPUT;
if (!output)
  throw Error("Set KDS_PARITY_OUTPUT to fresh forms-parity screenshots");
const cases = JSON.parse(await readFile(`${output}/results.json`, "utf8"));
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage();
const results = [];
try {
  for (const fixture of cases) {
    const [, , density, scaleString] = fixture.name.split("-");
    const scale = Number(scaleString);
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
        async ({ png, measurements, platform, metrics, scale }) => {
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
          const distance = (a, b) =>
            Math.sqrt(a.reduce((sum, v, i) => sum + (v - b[i]) ** 2, 0));
          return measurements.slice(0, 3).map((m) => {
            const r = m[platform];
            const [height, inset, gap] = metrics;
            const centerY = r.y + r.height / 2;
            const x = Math.floor(r.x + r.width / 2);
            const outside = pixel(x, Math.floor(r.y - 2));
            const painted = [];
            for (let y = Math.floor(r.y); y < Math.ceil(r.y + r.height); y++)
              if (distance(pixel(x, y), outside) > 3) painted.push(y);
            const paintedTop = Math.min(...painted),
              paintedHeight = Math.max(...painted) - paintedTop + 1;
            const bg = pixel(x, Math.floor(centerY));
            const left = Math.floor(r.x + inset + 1 + (16 + gap));
            const right = Math.min(
              Math.floor(r.x + r.width - inset - 20),
              left + Math.ceil((m.label === "Search items" ? 100 : 55) * scale),
            );
            const top = Math.ceil(centerY - height / 2 + 2),
              bottom = Math.floor(centerY + height / 2 - 2);
            let norm = 0;
            for (let y = top; y < bottom; y++)
              for (let x = left; x < right; x++)
                norm = Math.max(norm, distance(pixel(x, y), bg));
            let mass = 0,
              moment = 0,
              minX = Infinity,
              minY = Infinity,
              maxY = -Infinity;
            for (let y = top; y < bottom; y++)
              for (let x = left; x < right; x++) {
                const coverage = distance(pixel(x, y), bg) / norm;
                if (coverage < 0.15) continue;
                mass += coverage;
                moment += (y + 0.5 - centerY) * coverage;
                if (coverage > 0.5) {
                  minX = Math.min(minX, x);
                  minY = Math.min(minY, y);
                  maxY = Math.max(maxY, y);
                }
              }
            return {
              label: m.label,
              paintedTop,
              paintedHeight,
              inkX: minX,
              inkHeight: maxY - minY + 1,
              inkCenter: moment / mass,
            };
          });
        },
        { png, measurements: fixture.measurements, platform, metrics, scale },
      );
    }
    for (let i = 0; i < 3; i++)
      results.push({
        name: fixture.name,
        label: pair.web[i].label,
        web: pair.web[i],
        flutter: pair.flutter[i],
      });
  }
  await writeFile(`${output}/visual.json`, JSON.stringify(results, null, 2));
  const failures = results.filter(
    (r) =>
      Math.abs(r.web.paintedTop - r.flutter.paintedTop) > 0.5 ||
      r.web.paintedHeight !== r.flutter.paintedHeight ||
      Math.abs(r.web.inkX - r.flutter.inkX) > 1 ||
      Math.abs(r.web.inkHeight - r.flutter.inkHeight) > 1 ||
      !Number.isFinite(r.flutter.inkCenter) ||
      Math.abs(r.web.inkCenter - r.flutter.inkCenter) > 0.45,
  );
  console.log(
    `Input paint and glyph comparisons: ${results.length}; max center delta ${Math.max(...results.map((r) => Math.abs(r.web.inkCenter - r.flutter.inkCenter))).toFixed(3)}px`,
  );
  assert.deepEqual(
    failures,
    [],
    "Painted input borders or glyph positions differ",
  );
} finally {
  await browser.close();
}
