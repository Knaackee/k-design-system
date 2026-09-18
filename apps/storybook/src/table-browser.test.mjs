import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { mkdir, writeFile } from "node:fs/promises";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const output = process.env.KDS_PARITY_OUTPUT;
if (!output) throw Error("Set KDS_PARITY_OUTPUT");
await mkdir(output, { recursive: true });
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage();
const results = [];
const near = (a, b, label) =>
  assert.ok(Math.abs(a - b) <= 0.5, `${label}: ${a} vs ${b}`);
try {
  for (const fixture of ["basic", "cells"])
    for (const width of [375, 700, 1024])
      for (const density of ["dense", "standard", "spacious"])
        for (const scale of [1, 2]) {
          await page.setViewportSize({ width, height: 1200 });
          await page.goto(
            `http://localhost:6006/iframe.html?id=data-display-table--${fixture}&viewMode=story&globals=density:${density};textScale:${scale};brand:${scale === 2 ? "reference" : "orbit"};theme:${scale === 2 ? "dark" : "light"}`,
          );
          await page
            .getByRole("table", { name: "Project overview", exact: true })
            .waitFor();
          await page.evaluate(() => document.fonts.ready);
          const metrics = await page.evaluate(() => {
            const table = document.querySelector(".k-table");
            const viewport = document.querySelector(".k-table-viewport");
            const rect = (element) => {
              const r = element.getBoundingClientRect();
              return { x: r.x, y: r.y, width: r.width, height: r.height };
            };
            const css = getComputedStyle(table);
            const token = (name) =>
              parseFloat(css.getPropertyValue(`--k-${name}`));
            return {
              table: rect(table),
              viewport: rect(viewport),
              headers: [...table.querySelectorAll("th")].map(rect),
              rows: [...table.querySelectorAll("tbody tr")].map((r) =>
                [...r.children].map(rect),
              ),
              minimum:
                token("size-control") +
                2 * token("space-control-gap") +
                token("border-width-default"),
              pageWidth: document.documentElement.scrollWidth,
              tabIndex: viewport.getAttribute("tabindex"),
            };
          });
          const bases =
            fixture === "basic" ? [240, 160, 120] : [240, 180, 160, 88];
          const base = bases.reduce((a, b) => a + b, 0);
          const flex = fixture === "basic" ? [2, 1, 0] : [2, 1, 1, 0];
          const totalFlex = flex.reduce((a, b) => a + b, 0);
          const extra = Math.max(0, metrics.viewport.width - base);
          near(
            metrics.table.width,
            Math.max(base, metrics.viewport.width),
            "table width",
          );
          assert.ok(
            metrics.pageWidth <= width,
            "Overflow must stay inside table viewport",
          );
          assert.equal(
            metrics.tabIndex,
            base > metrics.viewport.width ? "0" : null,
          );
          metrics.headers.forEach((h, i) =>
            near(
              h.width,
              bases[i] + (extra * flex[i]) / totalFlex,
              "track width",
            ),
          );
          for (const row of metrics.rows)
            for (let i = 0; i < row.length; i++) {
              near(row[i].x, metrics.headers[i].x, "aligned column");
              near(row[i].width, metrics.headers[i].width, "same track");
              assert.ok(row[i].height >= metrics.minimum - 0.5, "row minimum");
            }
          assert.equal(
            await page.locator(".k-table th[scope=col]").count(),
            bases.length,
          );
          results.push({ fixture, width, density, scale, metrics });
          if (density === "standard" && scale === 1)
            await page.screenshot({
              path: `${output}/table-${fixture}-${width}-web.png`,
              fullPage: true,
            });
        }
  await page.setViewportSize({ width: 1024, height: 900 });
  await page.goto(
    "http://localhost:6006/iframe.html?id=data-display-table--cells&viewMode=story",
  );
  const select = page.getByRole("combobox", {
    name: "Status for Atlas website",
    exact: true,
  });
  await select.click();
  await page.getByRole("option", { name: "Done", exact: true }).click();
  assert.match(
    await page.getByRole("status").innerText(),
    /Atlas website: Done/,
  );
  await page
    .getByRole("button", { name: "Actions for Atlas website", exact: true })
    .click();
  await page.getByRole("menuitem", { name: "Copy name", exact: true }).click();
  assert.match(
    await page.getByRole("status").innerText(),
    /Copy name: Atlas website/,
  );
  await page.setViewportSize({ width: 375, height: 900 });
  await page.locator(".k-table-viewport").focus();
  await page.keyboard.press("ArrowRight");
  await page.waitForFunction(
    () => document.querySelector(".k-table-viewport").scrollLeft > 0,
  );
  await writeFile(
    `${output}/web-results.json`,
    JSON.stringify(results, null, 2),
  );
  console.log(
    `PASS: ${results.length} table geometry cases; select, menu and keyboard scroll interactions`,
  );
} finally {
  await browser.close();
}
