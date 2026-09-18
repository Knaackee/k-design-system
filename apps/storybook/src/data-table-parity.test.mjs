import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { mkdir, writeFile } from "node:fs/promises";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
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
try {
  for (const fixture of ["rows", "groups"])
    for (const width of [375, 700, 1024])
      for (const density of ["dense", "standard", "spacious"])
        for (const scale of [1, 2]) {
          const height = width === 375 ? 812 : 900,
            theme = scale === 1 ? "light" : "dark",
            brand = scale === 1 ? "orbit" : "reference";
          await web.setViewportSize({ width, height });
          await flutter.setViewportSize({ width, height });
          await web.goto(
            "http://localhost:6006/iframe.html?" +
              new URLSearchParams({
                id: `patterns-datatable--${fixture}`,
                viewMode: "story",
                globals: `brand:${brand};theme:${theme};density:${density};textScale:${scale}`,
              }),
          );
          await web.locator(".k-table").first().waitFor();
          await web.evaluate(() => document.fonts.ready);
          await flutter.goto(
            "http://localhost:6007/#/?" +
              new URLSearchParams({
                path: `patterns/datatable/data-table-${fixture}`,
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
                  name: scale === 1 ? "Orbit Light" : "Reference Dark",
                }),
                "k-design": group({ density }),
                "text-scale": group({ factor: scale }),
              }),
          );
          await flutter.reload();
          await flutter.locator("flutter-view").waitFor();
          await flutter
            .locator("flt-semantics-placeholder")
            .evaluate((e) => e.click());
          await flutter
            .getByRole("button", { name: /Edit title for atlas/ })
            .waitFor();
          const a = await web.locator(".k-table tbody tr").evaluateAll((es) =>
            es.map((e) => {
              const r = e.getBoundingClientRect();
              return { x: r.x, y: r.y, width: r.width, height: r.height };
            }),
          );
          const b = await flutter.getByRole("row").evaluateAll((es) =>
            es.map((e) => {
              const r = e.getBoundingClientRect();
              return { x: r.x, y: r.y, width: r.width, height: r.height };
            }),
          );
          const indentGeometry = await web.evaluate(() => {
            const row = document.querySelector(".k-table tbody tr");
            const bar = document.querySelector(".k-filter-bar");
            return {
              rowX: row.getBoundingClientRect().x,
              barX: bar.getBoundingClientRect().x,
              inset: parseFloat(
                getComputedStyle(row).getPropertyValue(
                  "--k-space-control-inset-inline",
                ),
              ),
            };
          });
          assert.ok(
            Math.abs(
              indentGeometry.rowX -
                indentGeometry.barX -
                (fixture === "groups" ? 2 * indentGeometry.inset : 0),
            ) < 0.5,
            "Leaf rows indent once per group level",
          );
          const name = `data-table-${fixture}-${width}-${density}-${scale}`;
          results.push({ name, web: a, flutter: b });
          await writeFile(
            `${output}/data-table-parity-results.json`,
            JSON.stringify(results, null, 2),
          );
          assert.equal(b.length, a.length, name + " rows");
          for (let i = 0; i < a.length; i++)
            for (const key of ["x", "y", "width", "height"])
              assert.ok(
                Math.abs(a[i][key] - b[i][key]) <= 0.5,
                `${name} row ${i} ${key}: ${a[i][key]} vs ${b[i][key]}`,
              );
          if (density === "standard" && scale === 1) {
            await web.screenshot({ path: `${output}/${name}-web.png` });
            await flutter.screenshot({ path: `${output}/${name}-flutter.png` });
            await web
              .getByRole("button", {
                name: "Edit title for atlas",
                exact: true,
              })
              .click();

            const editorA = web.getByRole("textbox", {
              name: "Title for atlas",
              exact: true,
            });
            const editorB = flutter.getByRole("textbox", {
              name: /Title for atlas/,
            });

            const inputA = await editorA.locator("xpath=..").boundingBox();
            await web.screenshot({
              path: output + "/" + name + "-edit-web.png",
            });
            await editorA.press("Escape");
            await flutter
              .getByRole("button", { name: /Edit title for atlas/ })
              .click();
            await editorB.waitFor();
            const inputB = await editorB.evaluate((e) => {
              const r = e
                .closest("[id^=flt-semantic-node-]")
                .getBoundingClientRect();
              return { x: r.x, y: r.y, width: r.width, height: r.height };
            });
            for (const key of ["x", "y", "width", "height"])
              assert.ok(
                Math.abs(inputA[key] - inputB[key]) <= 0.5,
                name +
                  " editor " +
                  key +
                  ": " +
                  inputA[key] +
                  " vs " +
                  inputB[key],
              );

            await flutter.screenshot({
              path: output + "/" + name + "-edit-flutter.png",
            });

            await editorB.press("Escape");
          }
        }
  console.log(
    `PASS: ${results.length} cross-platform data-table geometry cases`,
  );
} finally {
  await browser.close();
}
