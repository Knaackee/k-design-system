import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { mkdir } from "node:fs/promises";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
const output = process.env.KDS_PARITY_OUTPUT;
if (!output) throw Error("Set KDS_PARITY_OUTPUT");
await mkdir(output, { recursive: true });
const browser = await chromium.launch({ channel: "msedge", headless: true });
const web = await browser.newPage(),
  flutter = await browser.newPage();
let cases = 0;
try {
  for (const width of [375, 700, 1024])
    for (const density of ["dense", "standard", "spacious"])
      for (const scale of [1, 2]) {
        const theme = scale === 1 ? "light" : "dark",
          height = width === 375 ? 812 : 900;
        await web.setViewportSize({ width, height });
        await flutter.setViewportSize({ width, height });
        await web.goto(
          `http://localhost:6006/iframe.html?id=patterns-datatablevirtual--virtual&viewMode=story&globals=theme:${theme};density:${density};textScale:${scale}`,
        );
        await web
          .getByRole("button", { name: "Edit row-0", exact: true })
          .waitFor();
        await web.evaluate(() => document.fonts.ready);
        const viewport =
          width === 375
            ? "Compact · 375"
            : width === 700
              ? "Medium · 700"
              : "Expanded · 1024";
        await flutter.goto(
          "http://localhost:6007/#/?" +
            new URLSearchParams({
              path: "patterns/datatablevirtual/data-table-virtual",
              preview: "",
              viewport: `{name:${viewport}}`,
              theme: `{name:Orbit ${scale === 1 ? "Light" : "Dark"}}`,
              "k-design": `{density:${density}}`,
              "text-scale": `{factor:${scale}}`,
            }),
        );
        await flutter.reload();
        await flutter
          .locator("flt-semantics-placeholder")
          .evaluate((e) => e.click());
        await flutter.getByRole("button", { name: /Edit row-0\b/ }).waitFor();
        const name = `virtual-${width}-${density}-${scale}`;
        for (const i of [0, 1, 2]) {
          const a = await web
            .getByRole("button", { name: `Edit row-${i}`, exact: true })
            .boundingBox();
          const b = await flutter
            .getByRole("button", { name: new RegExp(`Edit row-${i}\\b`) })
            .boundingBox();
          for (const key of ["x", "y", "width", "height"])
            assert.ok(
              Math.abs(a[key] - b[key]) <= 0.5,
              `${name} row${i} ${key}: ${a[key]} vs ${b[key]}`,
            );
        }
        if (density === "standard" && scale === 1) {
          await web.screenshot({ path: `${output}/${name}-web.png` });
          await flutter.screenshot({ path: `${output}/${name}-flutter.png` });
        }
        cases++;
      }
  console.log(`PASS: ${cases} virtual-table cross-platform geometry cases`);
} finally {
  await browser.close();
}
