import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { mkdir, writeFile } from "node:fs/promises";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const output = process.env.KDS_PARITY_OUTPUT;
if (!output) throw Error("Set KDS_PARITY_OUTPUT");
await mkdir(output, { recursive: true });
const browser = await chromium.launch({ channel: "msedge", headless: true });
const web = await browser.newPage(),
  flutter = await browser.newPage();
const group = (fields) =>
  "{" +
  Object.entries(fields)
    .map(([k, v]) => encodeURIComponent(k) + ":" + encodeURIComponent(v))
    .join(",") +
  "}";
const results = [];
const review = process.env.KDS_PARITY_REVIEW === "1";
try {
  for (const width of review ? [1024] : [375, 700, 1024])
    for (const density of review
      ? ["dense"]
      : ["dense", "standard", "spacious"])
      for (const scale of review ? [1] : [1, 2])
        for (const inputMode of review ? ["pointer"] : ["pointer", "touch"]) {
          const height = width === 375 ? 812 : 900;
          await web.setViewportSize({ width, height });
          await flutter.setViewportSize({ width, height });
          const theme = review ? "dark" : scale === 1 ? "light" : "dark",
            brand = scale === 1 ? "orbit" : "reference";
          const windowClass =
            width < 600 ? "compact" : width < 840 ? "medium" : "expanded";
          await web.goto(
            "http://localhost:6006/iframe.html?" +
              new URLSearchParams({
                id: "patterns-toolbar--actions",
                viewMode: "story",
                globals: `brand:${brand};theme:${theme};density:${density};windowClass:${windowClass};textScale:${scale};typeScale:compact;inputMode:${inputMode}`,
              }),
          );
          await web.getByRole("toolbar").waitFor();
          await web.evaluate(() => document.fonts.ready);
          await flutter.goto(
            "http://localhost:6007/#/?" +
              new URLSearchParams({
                path: "patterns/toolbar/toolbar-actions",
                preview: "",
                viewport: group({
                  name:
                    width === 375
                      ? "Compact · 375"
                      : width === 700
                        ? "Medium · 700"
                        : "Expanded · 1024",
                }),
                theme: group({
                  name: `${brand === "orbit" ? "Orbit" : "Reference"} ${theme === "dark" ? "Dark" : "Light"}`,
                }),
                "k-design": group({
                  density,
                  "type-scale": "compact",
                  "input-mode": inputMode,
                  "window-class": windowClass,
                }),
                "text-scale": group({ factor: scale }),
              }),
          );
          await flutter.reload();
          await flutter.locator("flutter-view").waitFor();
          await flutter
            .locator("flt-semantics-placeholder")
            .evaluate((e) => e.click());
          await flutter
            .locator("flt-semantics span")
            .filter({ hasText: /^No action selected$/ })
            .waitFor();
          const measurements = [];
          for (const label of [
            "New item",
            "Actions",
            "Refresh",
            "More actions",
          ]) {
            const a = await web
              .getByRole("button", { name: label, exact: true })
              .locator("xpath=..")
              .boundingBox();
            const b = await flutter
              .getByRole("button", { name: label, exact: true })
              .boundingBox();
            measurements.push({ label, web: a, flutter: b });
          }
          const name = `toolbar-${width}-${density}-${scale}-${inputMode}`;
          await web.screenshot({ path: `${output}/${name}-web.png` });
          await flutter.screenshot({ path: `${output}/${name}-flutter.png` });
          await web
            .getByRole("button", { name: "Actions", exact: true })
            .click();
          await flutter
            .getByRole("button", { name: "Actions", exact: true })
            .click();
          await flutter.getByText("Copy link", { exact: true }).waitFor();
          for (const label of [
            "Copy link",
            "Duplicate",
            "Export",
            "Archive",
            "Delete",
          ]) {
            const a = await web
              .getByRole("menuitem", { name: label, exact: true })
              .boundingBox();
            const b = await flutter
              .getByText(label, { exact: true })
              .evaluate((e) => {
                const r = e
                  .closest("[id^=flt-semantic-node-]")
                  .getBoundingClientRect();
                return { x: r.x, y: r.y, width: r.width, height: r.height };
              });
            measurements.push({ label, web: a, flutter: b });
          }
          await web.screenshot({ path: `${output}/${name}-menu-web.png` });
          await flutter.screenshot({
            path: `${output}/${name}-menu-flutter.png`,
          });
          results.push({ name, measurements });
          await writeFile(
            `${output}/results.json`,
            JSON.stringify(results, null, 2),
          );
          console.log(name, JSON.stringify(measurements));
        }
  assert.equal(results.length, review ? 1 : 36);
  const differences = results.flatMap((result) =>
    result.measurements.flatMap((m) =>
      ["x", "y", "width", "height"]
        .filter((key) => Math.abs(m.web[key] - m.flutter[key]) > 0.5)
        .map((key) => ({
          name: result.name,
          label: m.label,
          key,
          web: m.web[key],
          flutter: m.flutter[key],
        })),
    ),
  );
  await writeFile(
    `${output}/differences.json`,
    JSON.stringify(differences, null, 2),
  );
  console.log("Geometry differences", differences.length);
  assert.deepEqual(
    differences,
    [],
    "Cross-platform geometry differs by more than 0.5px",
  );
} finally {
  await browser.close();
}
