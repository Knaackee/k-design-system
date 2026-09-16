import assert from "node:assert/strict";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage();
try {
  await page.goto(
    "http://localhost:6006/iframe.html?id=patterns-toolbar--actions&viewMode=story",
  );
  const toolbar = page.getByRole("toolbar");
  await toolbar.waitFor();
  await page.getByRole("button", { name: "New item", exact: true }).focus();
  await page.keyboard.press("ArrowRight");
  assert.equal(
    await page.locator(":focus").getAttribute("aria-label"),
    "Actions",
  );
  await page.keyboard.press("ArrowDown");
  assert.equal(await page.locator(":focus").innerText(), "Copy link");
  await page.keyboard.press("ArrowDown");
  assert.equal(await page.locator(":focus").innerText(), "Duplicate");
  await page.keyboard.press("ArrowDown");
  assert.equal(await page.locator(":focus").innerText(), "Archive");
  await page.keyboard.press("Home");
  await page.keyboard.press("d");
  assert.equal(await page.locator(":focus").innerText(), "Duplicate");
  await page.keyboard.press("Enter");
  assert.equal(
    await page.getByRole("status").innerText(),
    "Duplicate selected",
  );
  assert.equal(
    await page.locator(":focus").getAttribute("aria-label"),
    "Actions",
  );
  assert.equal(await page.getByRole("menu").count(), 0);
  await page.keyboard.press("ArrowUp");
  assert.equal(await page.locator(":focus").innerText(), "Delete");
  await page.keyboard.press("Escape");
  assert.equal(
    await page.locator(":focus").getAttribute("aria-label"),
    "Actions",
  );
  await page.keyboard.press("End");
  assert.equal(
    await page.locator(":focus").getAttribute("aria-label"),
    "More actions",
  );
  await page.keyboard.press("ArrowRight");
  assert.equal(await page.locator(":focus").innerText(), "New item");
  assert.equal(await toolbar.locator('button[tabindex="0"]').count(), 1);
  for (const density of ["dense", "standard", "spacious"]) {
    for (const width of [320, 375, 700, 1024]) {
      await page.setViewportSize({ width, height: 900 });
      await page.evaluate((density) => {
        for (const el of [
          document.documentElement,
          document.querySelector(".k-gallery"),
        ])
          el.dataset.density = density;
        document.documentElement.style.setProperty("--k-text-scale", "2");
      }, density);
      await page.getByRole("button", { name: "Actions", exact: true }).click();
      const menu = page.getByRole("menu", { name: "Actions", exact: true });
      const bounds = await menu.boundingBox();
      assert.ok(
        bounds.x >= 7.9 && bounds.x + bounds.width <= width - 7.9,
        `menu bounds ${density}/${width}`,
      );
      assert.equal(
        await menu.getByRole("menuitem", { name: "Export" }).isDisabled(),
        true,
      );
      await page.keyboard.press("Escape");
      const overflow = await page.evaluate(
        () => document.documentElement.scrollWidth > innerWidth,
      );
      assert.equal(overflow, false, `overflow ${density}/${width}`);
    }
  }
  await page.getByRole("button", { name: "More actions" }).click();
  await page.mouse.click(300, 800);
  assert.equal(await page.getByRole("menu").count(), 0);
  console.log(
    "Web actions: keyboard, disabled items, focus restoration, outside dismissal and 12 responsive cases passed",
  );
} finally {
  await browser.close();
}
