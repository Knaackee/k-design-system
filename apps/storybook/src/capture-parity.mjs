import { createRequire } from "node:module";
import { mkdir, writeFile } from "node:fs/promises";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const output = process.env.KDS_PARITY_OUTPUT;
if (!output)
  throw new Error("Set KDS_PARITY_OUTPUT to the screenshot output directory");
await mkdir(output, { recursive: true });
const browser = await chromium.launch({ channel: "msedge", headless: true });
const web = await browser.newPage();
const flutter = await browser.newPage();
const group = (fields) =>
  "{" +
  Object.entries(fields)
    .map(([k, v]) => encodeURIComponent(k) + ":" + encodeURIComponent(v))
    .join(",") +
  "}";
const results = [];
try {
  for (const [fixture, story, label] of [
    ["card-variants", "primitives-card--variants", "Project settings"],
    ["surface-tones", "primitives-surface--tones", "Canvas"],
    [
      "layout-composition",
      "primitives-layout--composition",
      "Shared composition",
    ],
  ]) {
    for (const width of [375, 1024]) {
      const height = width === 375 ? 812 : 900;
      await web.setViewportSize({ width, height });
      await flutter.setViewportSize({ width, height });
      for (const density of ["dense", "standard", "spacious"]) {
        for (const [brand, theme, scale, inputMode] of [
          ["orbit", "light", 1, "pointer"],
          ["orbit", "dark", 2, "touch"],
          ["reference", "light", 2, "pointer"],
          ["reference", "dark", 1, "touch"],
        ]) {
          const windowClass = width === 375 ? "compact" : "expanded";
          const globals = `brand:${brand};theme:${theme};density:${density};typeScale:compact;inputMode:${inputMode};windowClass:${windowClass};textScale:${scale}`;
          await web.goto(
            "http://localhost:6006/iframe.html?" +
              new URLSearchParams({ id: story, viewMode: "story", globals }),
          );
          await web.getByText(label, { exact: true }).waitFor();
          await web.evaluate(() => document.fonts.ready);
          const component = fixture.split("-")[0];
          const params = new URLSearchParams({
            path: `primitives/${component}/${fixture}`,
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
              "input-mode": inputMode,
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
          await flutter.getByText(label, { exact: true }).waitFor();
          // Wait for a rendered frame after the semantics tree becomes available.
          await flutter.evaluate(
            () =>
              new Promise((resolve) =>
                requestAnimationFrame(() => requestAnimationFrame(resolve)),
              ),
          );
          const name = `${fixture}-${width}-${density}-${brand}-${theme}-${scale}-${inputMode}`;
          await web.screenshot({ path: `${output}/${name}-web.png` });
          await flutter.screenshot({ path: `${output}/${name}-flutter.png` });
          results.push({
            name,
            web: await web.getByText(label, { exact: true }).boundingBox(),
            flutter: await flutter
              .getByText(label, { exact: true })
              .evaluate((e) => {
                const r = e
                  .closest("[id^=flt-semantic-node-]")
                  .getBoundingClientRect();
                return { x: r.x, y: r.y, width: r.width, height: r.height };
              }),
            webUrl: web.url(),
            flutterUrl: flutter.url(),
          });
        }
        console.log(
          "Captured",
          fixture,
          width,
          density,
          results.length,
          "pairs",
        );
      }
    }
  }
  await writeFile(`${output}/results.json`, JSON.stringify(results, null, 2));
  console.log("Saved", results.length, "matched screenshot pairs");
} finally {
  await browser.close();
}
