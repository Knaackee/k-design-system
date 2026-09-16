import assert from "node:assert/strict";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const browser = await chromium.launch({ channel: "msedge", headless: true });
const web = await browser.newPage({ viewport: { width: 1024, height: 900 } });
const flutter = await browser.newPage({
  viewport: { width: 1024, height: 900 },
});
const group = (fields) =>
  "{" +
  Object.entries(fields)
    .map(([k, v]) => encodeURIComponent(k) + ":" + encodeURIComponent(v))
    .join(",") +
  "}";
let checked = 0;
try {
  const cases = [
    ...[1, 2, 3, 6].flatMap((columns) =>
      ["control", "action", "section"].map((gap) => ({
        columns,
        gap,
        min: 240,
      })),
    ),
    ...[80, 160, 320].map((min) => ({ columns: 0, gap: "control", min })),
  ];
  for (const { columns, gap, min } of cases) {
    const args = `${columns ? `columns:${columns};` : ""}gap:${gap};minColumnWidth:${min}`;
    await web.goto(
      "http://localhost:6006/iframe.html?" +
        new URLSearchParams({
          id: "primitives-grid--responsive",
          viewMode: "story",
          args,
          globals:
            "density:standard;theme:light;brand:orbit;windowClass:expanded;textScale:1",
        }),
    );
    await web.getByText("Item 1", { exact: true }).waitFor();
    await web.evaluate(() => document.fonts.ready);
    await flutter.goto(
      "http://localhost:6007/#/?" +
        new URLSearchParams({
          path: "primitives/grid/grid-responsive",
          preview: "",
          "k-design": group({
            density: "standard",
            "window-class": "expanded",
            "type-scale": "compact",
            "input-mode": "pointer",
          }),
          viewport: group({ name: "Expanded · 1024" }),
          knobs: group({
            Columns: columns ? String(columns) : "Auto",
            Gap: gap,
            "Minimum column width": min,
          }),
        }),
    );
    await flutter.reload();
    await flutter.locator("flutter-view").waitFor();
    await flutter
      .locator("flt-semantics-placeholder")
      .evaluate((e) => e.click());
    await flutter.getByText("Item 1", { exact: true }).waitFor();
    for (const n of [1, 2, 3, 4]) {
      const a = await web.getByText(`Item ${n}`, { exact: true }).boundingBox();
      const b = await flutter
        .getByText(`Item ${n}`, { exact: true })
        .evaluate((e) => {
          const r = e
            .closest("[id^=flt-semantic-node-]")
            .getBoundingClientRect();
          return { x: r.x, y: r.y, height: r.height };
        });
      for (const key of ["x", "y", "height"])
        assert.ok(
          Math.abs(a[key] - b[key]) <= 0.5,
          `${columns}/${gap}/${min}/Item ${n}/${key}: ${a[key]} vs ${b[key]}`,
        );
    }
    const actual = await web
      .locator(".k-grid")
      .evaluate(
        (e) => getComputedStyle(e).gridTemplateColumns.split(" ").length,
      );
    if (columns) assert.equal(actual, columns);
    console.log("PASS", columns || "Auto", gap, min);
    checked++;
  }
  console.log(
    "PASS:",
    checked,
    "matching configurations through actual gallery controls",
  );
} finally {
  await browser.close();
}
