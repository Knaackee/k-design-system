import assert from "node:assert/strict";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage();
const near = (actual, expected, name) =>
  assert.ok(
    Math.abs(actual - expected) <= 0.5,
    `${name}: ${actual} != ${expected}`,
  );
let checked = 0;
try {
  for (const width of [375, 1024]) {
    await page.setViewportSize({ width, height: 1600 });
    await page.goto(
      "http://localhost:6006/iframe.html?id=primitives-card--variants&viewMode=story",
    );
    await page.locator(".k-card").first().waitFor();
    await page.evaluate(() => document.fonts.ready);
    await page.evaluate(() => {
      window.originalCard = document.querySelector(".k-card");
    });
    for (const density of ["dense", "standard", "spacious"]) {
      for (const brand of ["orbit", "reference"]) {
        for (const theme of ["light", "dark"]) {
          for (const typeScale of ["compact", "standard"]) {
            for (const inputMode of ["pointer", "touch"]) {
              for (const scale of [1, 2]) {
                const result = await page.evaluate(
                  ({
                    width,
                    density,
                    brand,
                    theme,
                    typeScale,
                    inputMode,
                    scale,
                  }) => {
                    const attrs = {
                      density,
                      brand,
                      theme,
                      typeScale,
                      inputMode,
                      windowClass: width < 600 ? "compact" : "expanded",
                    };
                    for (const target of [
                      document.documentElement,
                      document.querySelector(".k-gallery"),
                    ])
                      Object.assign(target.dataset, attrs);
                    document.documentElement.style.setProperty(
                      "--k-text-scale",
                      String(scale),
                    );
                    const css = getComputedStyle(
                      document.querySelector(".k-gallery"),
                    );
                    const token = (name) =>
                      parseFloat(css.getPropertyValue("--k-" + name));
                    const rect = (el) => {
                      const r = el.getBoundingClientRect();
                      return {
                        top: r.top,
                        bottom: r.bottom,
                        left: r.left,
                        right: r.right,
                        width: r.width,
                        height: r.height,
                      };
                    };
                    const cards = [...document.querySelectorAll(".k-card")].map(
                      (el) => ({
                        card: rect(el),
                        heading: rect(el.querySelector(".k-text--heading4")),
                        body: rect(el.querySelector(".k-text--body-small")),
                        target: rect(el.querySelector(".k-button-target")),
                        button: rect(el.querySelector(".k-button")),
                      }),
                    );
                    return {
                      cards,
                      same:
                        window.originalCard ===
                        document.querySelector(".k-card"),
                      gutter: token("space-layout-gutter"),
                      control: token("space-control-gap"),
                      action: token("space-content-action-gap"),
                      section: token("space-layout-section-gap"),
                      padding: token("space-card-padding"),
                      border: token("border-width-default"),
                      size: token("size-control"),
                      target: token("size-hit-target"),
                    };
                  },
                  { width, density, brand, theme, typeScale, inputMode, scale },
                );
                assert.ok(
                  result.same,
                  "density updates must preserve the mounted card",
                );
                const columns = width < 600 ? 1 : 2;
                const available = Math.min(760, width - 2 * result.gutter);
                for (const item of result.cards) {
                  near(
                    item.card.width,
                    (available - (columns - 1) * result.section) / columns,
                    "column width",
                  );
                  near(
                    item.body.top - item.heading.bottom,
                    result.control,
                    "control gap",
                  );
                  near(
                    item.target.top - item.body.bottom,
                    result.action,
                    "action gap",
                  );
                  near(
                    item.heading.left - item.card.left,
                    result.padding + result.border,
                    "card inset",
                  );
                  near(
                    item.button.height,
                    result.size,
                    "visible button height",
                  );
                  assert.ok(
                    item.target.height >= result.target,
                    "minimum hit target",
                  );
                  assert.ok(
                    item.heading.right <= item.card.right &&
                      item.button.right <= item.card.right,
                    "content remains inside card",
                  );
                }
                const [first, second] = result.cards;
                near(
                  columns === 1
                    ? second.card.top - first.card.bottom
                    : second.card.left - first.card.right,
                  result.section,
                  "section gap",
                );
                checked++;
              }
            }
          }
        }
      }
    }
  }
  let surfaces = 0;
  for (const width of [375, 1024]) {
    await page.setViewportSize({ width, height: 1000 });
    await page.goto(
      "http://localhost:6006/iframe.html?id=primitives-surface--tones&viewMode=story",
    );
    await page.locator(".k-surface-sample").first().waitFor();
    for (const density of ["dense", "standard", "spacious"]) {
      const geometry = await page.evaluate(
        ({ width, density }) => {
          for (const el of [
            document.documentElement,
            document.querySelector(".k-gallery"),
          ]) {
            el.dataset.density = density;
            el.dataset.windowClass = width < 600 ? "compact" : "expanded";
          }
          const root = document.querySelector(".k-gallery");
          const css = getComputedStyle(root);
          const token = (name) =>
            parseFloat(css.getPropertyValue("--k-" + name));
          const items = [...document.querySelectorAll(".k-surface-sample")].map(
            (el) => {
              const r = el.getBoundingClientRect(),
                h = el.querySelector(".k-text--label").getBoundingClientRect(),
                b = el
                  .querySelector(".k-text--body-small")
                  .getBoundingClientRect();
              return {
                width: r.width,
                left: r.left,
                right: r.right,
                top: r.top,
                bottom: r.bottom,
                inset: h.left - r.left,
                gap: b.top - h.bottom,
              };
            },
          );
          return {
            items,
            gutter: token("space-layout-gutter"),
            section: token("space-layout-section-gap"),
            control: token("space-control-gap"),
            padding: token("space-card-padding"),
            border: token("border-width-default"),
          };
        },
        { width, density },
      );
      const columns = width < 600 ? 1 : 2;
      for (const item of geometry.items) {
        near(
          item.width,
          (Math.min(760, width - 2 * geometry.gutter) -
            (columns - 1) * geometry.section) /
            columns,
          "surface column width",
        );
        near(item.inset, geometry.padding + geometry.border, "surface inset");
        near(item.gap, geometry.control, "surface content gap");
      }
      const [a, b] = geometry.items;
      near(
        columns === 1 ? b.top - a.bottom : b.left - a.right,
        geometry.section,
        "surface section gap",
      );
      surfaces++;
    }
  }
  console.log("PASS", surfaces, "Web surface geometries");
  const layouts = await page.evaluate(async () =>
    (await import("/src/layout-harness.tsx")).checkLayouts(),
  );
  console.log("PASS", layouts, "Web layout assertions");
  console.log(
    `PASS ${checked} live Web card geometry configurations (0.5px tolerance)`,
  );
} finally {
  await browser.close();
}
