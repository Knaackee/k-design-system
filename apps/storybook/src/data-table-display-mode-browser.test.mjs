import assert from "node:assert/strict";
import { createRequire } from "node:module";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage({
  viewport: { width: 375, height: 812 },
  hasTouch: true,
  isMobile: true,
});
const visit = async (fixture) => {
  await page.goto(
    `http://localhost:6006/iframe.html?id=patterns-datatable--${fixture}&viewMode=story&globals=density:standard`,
  );
  await page.locator(".k-table").first().waitFor();
};
try {
  await visit("single-column");
  assert.equal(await page.locator(".k-data-single-row").count(), 6);
  assert.equal(await page.locator(".k-editable-cell").count(), 0);
  assert.equal(
    await page.locator(".k-table tbody tr").first().locator("td").count(),
    1,
  );
  await page.getByRole("button", { name: "Open Atlas website" }).click();
  assert.match(
    await page.getByRole("status").last().innerText(),
    /Open: Atlas website/,
  );
  await page.setViewportSize({ width: 1024, height: 900 });
  assert.equal(await page.locator(".k-data-single-row").count(), 6);

  await page.setViewportSize({ width: 375, height: 812 });
  await visit("rows");
  assert.ok(await page.locator(".k-editable-cell").count());
  const viewport = page.locator(".k-table-viewport").first();
  const before = await viewport.evaluate((element) => ({
    client: element.clientWidth,
    full: element.scrollWidth,
  }));
  assert.ok(before.full > before.client);
  const bounds = await viewport.boundingBox();
  assert.ok(bounds);
  const cdp = await page.context().newCDPSession(page);
  for (let i = 0; i <= 8; i++) {
    await cdp.send("Input.dispatchTouchEvent", {
      type: i === 0 ? "touchStart" : i === 8 ? "touchEnd" : "touchMove",
      touchPoints:
        i === 8 ? [] : [{ x: bounds.x + 270 - i * 23, y: bounds.y + 70 }],
    });
    await page.waitForTimeout(30);
  }
  await page.waitForTimeout(250);
  assert.ok(await viewport.evaluate((element) => element.scrollLeft > 0));
  console.log("DataTable display mode and touch scroll passed");
} finally {
  await browser.close();
}
