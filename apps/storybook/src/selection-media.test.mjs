import assert from "node:assert/strict";
import { createRequire } from "node:module";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage({ viewport: { width: 1024, height: 900 } });
try {
  for (const density of ["dense", "standard", "spacious"])
    for (const scale of [1, 2]) {
      console.log(`Select media: ${density}, scale ${scale}`);
      await page.goto(
        `http://localhost:6006/iframe.html?id=patterns-datatable--rows&viewMode=story&globals=density:${density};textScale:${scale}`,
      );
      await page
        .getByRole("combobox", { name: "Status filter", exact: true })
        .click();
      await page
        .getByRole("option", { name: "In progress", exact: true })
        .click();
      await page.getByRole("button", { name: "Sort", exact: true }).focus();
      const controls = await page
        .locator(".k-selection[data-media]")
        .evaluateAll((elements) =>
          elements.map((e) => {
            const icon = e.querySelector(".k-selection__media .k-option-media"),
              input = e.querySelector("input");
            const a = icon.getBoundingClientRect(),
              b = input.getBoundingClientRect();
            return {
              presentation: e.dataset.presentation,
              offset: a.y + a.height / 2 - (b.y + b.height / 2),
            };
          }),
        );
      assert.ok(controls.some((c) => c.presentation === "standard"));
      assert.ok(controls.some((c) => c.presentation === "inline"));
      for (const control of controls)
        assert.ok(
          Math.abs(control.offset) <= 0.5,
          `${density} ${scale} ${control.presentation}: ${control.offset}px`,
        );
      const first = page
        .locator(".k-table tbody tr")
        .first()
        .locator("td")
        .first();
      assert.equal(Math.round((await first.boundingBox()).width), 48);
      assert.equal(
        await first.evaluate((e) => getComputedStyle(e).paddingLeft),
        "0px",
      );
      const hit = await first.getByRole("button").boundingBox();
      assert.ok(hit.width <= 48 && hit.width >= 28);
    }
  const select = page.getByRole("combobox", {
    name: "Status filter",
    exact: true,
  });
  assert.equal(
    await select.evaluate((e) => getComputedStyle(e).cursor),
    "pointer",
  );
  await select.click();
  const option = page.getByRole("option").first();
  assert.equal(
    await option.evaluate((e) => getComputedStyle(e).cursor),
    "pointer",
  );
  assert.equal(
    await option.evaluate((e) => getComputedStyle(e).userSelect),
    "none",
  );
  await page.keyboard.press("Control+a");
  assert.equal(
    await select.evaluate((e) => e.selectionStart === e.selectionEnd),
    true,
  );
  await page.keyboard.press("Escape");
  const box = await select.boundingBox();
  await page.mouse.move(box.x + 10, box.y + box.height / 2);
  await page.mouse.down();
  await page.mouse.move(box.x + box.width - 10, box.y + box.height / 2, {
    steps: 8,
  });
  await page.mouse.up();
  assert.equal(
    await select.evaluate((e) => e.selectionStart === e.selectionEnd),
    true,
  );
  await page.goto(
    "http://localhost:6006/iframe.html?id=forms-combobox--states&viewMode=story",
  );
  const combo = page.getByRole("combobox", { name: "Assignee", exact: true });
  await combo.fill("Alex");
  await combo.press("Control+a");
  assert.equal(
    await combo.evaluate((e) => e.selectionEnd - e.selectionStart),
    4,
    "Combobox preserves editable query selection",
  );
  console.log(
    "PASS: inline/standard select media centered at all densities and 100/200% text; compact icon track preserves button bounds",
  );
} finally {
  await browser.close();
}
