import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { mkdir, readFile, writeFile } from "node:fs/promises";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const output = process.env.KDS_PARITY_OUTPUT;
if (!output) throw new Error("Set KDS_PARITY_OUTPUT");
await mkdir(output, { recursive: true });
const browser = await chromium.launch({ channel: "msedge", headless: true });
const web = await browser.newPage();
const flutter = await browser.newPage();
const near = (a, b, label) =>
  assert.ok(Math.abs(a - b) <= 0.5, `${label}: ${a} vs ${b}`);
const results = [];
const catalogue = JSON.parse(
  await readFile(
    new URL("../../../assets/icons/lucide/source.json", import.meta.url),
    "utf8",
  ),
).icons;
const group = (fields) =>
  "{" +
  Object.entries(fields)
    .map(([k, v]) => encodeURIComponent(k) + ":" + encodeURIComponent(v))
    .join(",") +
  "}";
try {
  // Boundary geometry on real component CSS, including mixed-height rows.
  await web.setViewportSize({ width: 1200, height: 1600 });
  await web.goto(
    "http://localhost:6006/iframe.html?id=primitives-grid--responsive&viewMode=story",
  );
  await web.locator(".k-grid").waitFor();
  for (const density of ["dense", "standard", "spacious"]) {
    const checks = await web.evaluate((density) => {
      for (const el of [
        document.documentElement,
        document.querySelector(".k-gallery"),
      ])
        el.dataset.density = density;
      const grid = document.querySelector(".k-grid");
      grid.innerHTML = [20, 40, 30, 10]
        .map((h) => `<div style="height:${h}px"></div>`)
        .join("");
      const gap = parseFloat(getComputedStyle(grid).columnGap);
      return [
        0,
        1,
        239,
        240,
        480 + gap - 0.1,
        480 + gap,
        480 + gap + 0.1,
        760,
        1024,
      ].map((width) => {
        grid.style.width = width + "px";
        const origin = grid.getBoundingClientRect();
        return {
          width,
          gap,
          rects: [...grid.children].map((el) => {
            const r = el.getBoundingClientRect();
            return {
              x: r.x - origin.x,
              y: r.y - origin.y,
              width: r.width,
              height: r.height,
            };
          }),
        };
      });
    }, density);
    for (const { width, gap, rects } of checks) {
      const cols = Math.max(1, Math.floor((width + gap) / (240 + gap)));
      const item = (width - (cols - 1) * gap) / cols;
      let top = 0;
      for (let start = 0; start < 4; start += cols) {
        const end = Math.min(4, start + cols);
        for (let n = start; n < end; n++) {
          near(rects[n].width, item, `grid width ${density}/${width}`);
          near(rects[n].x, (n - start) * (item + gap), "grid x");
          near(rects[n].y, top, "grid row y");
        }
        top += Math.max(...[20, 40, 30, 10].slice(start, end)) + gap;
      }
    }
  }
  console.log("27 Web grid boundary cases passed");
  const fixtures = [
    [
      "container-bounds",
      "primitives-container--bounds",
      ["Contained content", "Centered content with shared gutters."],
    ],
    [
      "grid-responsive",
      "primitives-grid--responsive",
      ["Responsive grid", "Item 1", "Item 2", "Item 3", "Item 4"],
    ],
    ["icon-lucide", "primitives-icon--lucide", ["Shared Lucide icons"]],
    [
      "separator-orientations",
      "primitives-separator--orientations",
      ["Separators", "Above the line", "First", "Second", "Below the line"],
    ],
  ];
  for (const [fixture, story, labels] of fixtures) {
    for (const width of [375, 1024]) {
      await web.setViewportSize({ width, height: width === 375 ? 812 : 900 });
      await flutter.setViewportSize({
        width,
        height: width === 375 ? 812 : 900,
      });
      for (const density of ["dense", "standard", "spacious"]) {
        for (const [brand, theme, scale] of [
          ["orbit", "light", 1],
          ["reference", "dark", 2],
        ]) {
          const windowClass = width < 600 ? "compact" : "expanded";
          const globals = `brand:${brand};theme:${theme};density:${density};windowClass:${windowClass};textScale:${scale};typeScale:compact;inputMode:pointer`;
          await web.goto(
            "http://localhost:6006/iframe.html?" +
              new URLSearchParams({ id: story, viewMode: "story", globals }),
          );
          await web.getByText(labels[0], { exact: true }).waitFor();
          await web.evaluate(() => document.fonts.ready);
          const params = new URLSearchParams({
            path: `primitives/${fixture.split("-")[0]}/${fixture}`,
            preview: "",
            viewport: group({
              name: width === 375 ? "Compact · 375" : "Expanded · 1024",
            }),
            theme: group({
              name: `${brand === "orbit" ? "Orbit" : "Reference"} ${theme === "light" ? "Light" : "Dark"}`,
            }),
            "k-design": group({
              density,
              "type-scale": "compact",
              "input-mode": "pointer",
              "window-class": windowClass,
            }),
            "text-scale": group({ factor: scale }),
          });
          await flutter.goto("http://localhost:6007/#/?" + params);
          await flutter.reload();
          await flutter.locator("flutter-view").waitFor();
          await flutter
            .locator("flt-semantics-placeholder")
            .evaluate((e) => e.click());
          await flutter.getByText(labels[0], { exact: true }).waitFor();
          const measurements = [];
          for (const label of labels) {
            const a = await web.getByText(label, { exact: true }).boundingBox();
            const b = await flutter
              .getByText(label, { exact: true })
              .evaluate((e) => {
                const r = e
                  .closest("[id^=flt-semantic-node-]")
                  .getBoundingClientRect();
                return { x: r.x, y: r.y, width: r.width, height: r.height };
              });
            // Stretched text boxes have different semantics widths; position and line height must match.
            for (const key of ["x", "y", "height"])
              near(
                a[key],
                b[key],
                `${fixture}/${width}/${density}/${theme}/${label}/${key}`,
              );
            measurements.push({ label, web: a, flutter: b });
          }
          if (fixture === "icon-lucide") {
            for (const label of [
              "Check",
              "Close",
              "Next",
              "Information",
              "Check 16",
              "Check 12",
              "Check 20",
              ...catalogue,
            ]) {
              const a = await web
                .getByRole("img", { name: label, exact: true })
                .boundingBox();
              const b = await flutter
                .getByRole("img", { name: label, exact: true })
                .boundingBox();
              for (const key of ["x", "y", "width", "height"])
                near(a[key], b[key], `icon ${label}/${key}`);
              measurements.push({ label, web: a, flutter: b });
            }
          }
          const name = `${fixture}-${width}-${density}-${brand}-${theme}-${scale}`;
          await web.screenshot({ path: `${output}/${name}-web.png` });
          await flutter.screenshot({ path: `${output}/${name}-flutter.png` });
          results.push({
            name,
            measurements,
            webUrl: web.url(),
            flutterUrl: flutter.url(),
          });
          await writeFile(
            `${output}/results.json`,
            JSON.stringify(results, null, 2),
          );
        }
      }
    }
    console.log("Passed", fixture, results.length, "pairs");
  }
  console.log("PASS:", results.length, "matched gallery pairs");
} finally {
  await browser.close();
}
