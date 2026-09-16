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
const quick = process.env.KDS_PARITY_REVIEW === "1";
try {
  // A successful Flutter compile can still leave incomplete static assets.
  // Fail explicitly before comparing fallback fonts or missing avatar images.
  const manifestResponse = await flutter.request.get(
    "http://localhost:6007/assets/FontManifest.json",
  );
  assert.equal(
    manifestResponse.ok(),
    true,
    "Flutter font manifest must be served",
  );
  const manifest = await manifestResponse.json();
  const inter = manifest.find(
    (font) => font.family === "packages/k_design_tokens/Inter",
  );
  assert.ok(inter, "Flutter must bundle the shared Inter font");
  for (const asset of [
    ...inter.fonts.map((font) => `assets/${font.asset}`),
    "avatars/alex.png",
    "avatars/jordan.png",
  ]) {
    const response = await flutter.request.get(
      `http://localhost:6007/${asset}`,
    );
    assert.equal(response.ok(), true, `Missing Flutter asset: ${asset}`);
    assert.ok(
      (await response.body()).length > 0,
      `Empty Flutter asset: ${asset}`,
    );
  }
  for (const width of quick ? [1024] : [375, 700, 1024])
    for (const density of quick ? ["dense"] : ["dense", "standard", "spacious"])
      for (const scale of process.env.KDS_PARITY_SCALES
        ? process.env.KDS_PARITY_SCALES.split(",").map(Number)
        : quick
          ? [1]
          : [1, 2])
        for (const inputMode of quick ? ["pointer"] : ["pointer", "touch"]) {
          const height = width === 375 ? 812 : 900;
          await web.setViewportSize({ width, height });
          await flutter.setViewportSize({ width, height });
          const windowClass =
            width < 600 ? "compact" : width < 840 ? "medium" : "expanded";
          const theme = quick || scale === 2 ? "dark" : "light";
          const brand = scale === 2 ? "reference" : "orbit";
          await web.goto(
            (process.env.KDS_STORYBOOK_URL || "http://localhost:6006") +
              "/iframe.html?" +
              new URLSearchParams({
                id: "patterns-filterbar--filters",
                viewMode: "story",
                globals: `brand:${brand};theme:${theme};density:${density};windowClass:${windowClass};textScale:${scale};typeScale:compact;inputMode:${inputMode}`,
              }),
          );
          await web
            .getByRole("button", { name: "Reset all", exact: true })
            .waitFor();
          await web.evaluate(() => document.fonts.ready);
          await flutter.goto(
            "http://localhost:6007/#/?" +
              new URLSearchParams({
                path: "patterns/filterbar/filter-bar-filters",
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
            .getByRole("button", { name: "Reset all", exact: true })
            .waitFor();
          const measurements = [];
          for (const label of ["Search items", "Status", "Assignee"]) {
            const a = await web
              .getByRole(label === "Search items" ? "searchbox" : "combobox", {
                name: label,
                exact: true,
              })
              .locator("xpath=..")
              .boundingBox();
            const b = await flutter
              .getByRole("textbox", { name: label, exact: true })
              .evaluate((e) => {
                const r = e
                  .closest("[id^=flt-semantic-node-]")
                  .getBoundingClientRect();
                return { x: r.x, y: r.y, width: r.width, height: r.height };
              });
            measurements.push({ label, web: a, flutter: b });
          }
          for (const label of [
            "Remove Status: Active",
            "Remove Assignee: Alex",
            "Reset all",
          ]) {
            measurements.push({
              label,
              web: await web
                .getByRole("button", { name: label, exact: true })
                .locator("xpath=..")
                .boundingBox(),
              flutter: await flutter
                .getByRole("button", { name: label, exact: true })
                .boundingBox(),
            });
          }
          for (const label of ["Clear status", "Clear assignee"]) {
            measurements.push({
              label,
              web: await web
                .getByRole("button", { name: label, exact: true })
                .boundingBox(),
              flutter: await flutter
                .getByRole("button", { name: label, exact: true })
                .boundingBox(),
            });
          }
          const name = `forms-${width}-${density}-${scale}-${inputMode}`;
          await web.screenshot({ path: `${output}/${name}-web.png` });
          await flutter.screenshot({ path: `${output}/${name}-flutter.png` });
          await web
            .getByRole("combobox", { name: "Status", exact: true })
            .click();
          const webOptions = new Map();
          for (const label of ["Active", "Planned", "Closed"]) {
            webOptions.set(
              label,
              await web
                .getByRole("option", { name: label, exact: true })
                .boundingBox(),
            );
          }
          await web.screenshot({ path: `${output}/${name}-open-web.png` });
          await flutter
            .getByRole("textbox", { name: "Status", exact: true })
            .click();
          await flutter.getByText("Planned", { exact: true }).waitFor();
          for (const label of ["Active", "Planned", "Closed"]) {
            const a = webOptions.get(label);
            const b = await flutter
              .getByText(label, { exact: true })
              .evaluate((e) => {
                const r = e
                  .closest("[id^=flt-semantic-node-]")
                  .getBoundingClientRect();
                return { x: r.x, y: r.y, width: r.width, height: r.height };
              });
            measurements.push({
              label: `Option: ${label}`,
              web: a,
              flutter: b,
            });
          }

          await flutter.screenshot({
            path: `${output}/${name}-open-flutter.png`,
          });
          results.push({ name, measurements });
          await writeFile(
            `${output}/results.json`,
            JSON.stringify(results, null, 2),
          );
          console.log(name, JSON.stringify(measurements));
        }
  const differences = results.flatMap((result) =>
    result.measurements.flatMap((m) =>
      ["x", "y", "width", "height"]
        .filter((k) => Math.abs(m.web[k] - m.flutter[k]) > 0.5)
        .map((k) => ({
          name: result.name,
          label: m.label,
          key: k,
          web: m.web[k],
          flutter: m.flutter[k],
        })),
    ),
  );
  await writeFile(
    `${output}/differences.json`,
    JSON.stringify(differences, null, 2),
  );
  assert.deepEqual(
    differences,
    [],
    "Forms geometry differs by more than 0.5px",
  );
  console.log(`Forms parity: ${results.length} configurations passed`);
} finally {
  await browser.close();
}
