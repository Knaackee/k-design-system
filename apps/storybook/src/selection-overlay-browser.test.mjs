import assert from "node:assert/strict";
import { createRequire } from "node:module";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
const browser = await chromium.launch({ channel: "msedge", headless: true });
try {
  const page = await browser.newPage({
    viewport: { width: 1440, height: 1000 },
  });
  await page.goto(
    "http://localhost:6007/#/?path=patterns/datatable/data-table-groups&viewport={name:Medium%20%C2%B7%20700}&k-design={density:standard}",
  );
  await page.locator("flt-semantics-placeholder").evaluate((e) => e.click());
  const input = page.getByRole("textbox", {
    name: "Status for Atlas website",
    exact: true,
  });
  await input.click();
  const popup = page.locator('[aria-label="Options"]');
  await popup.waitFor();
  const trigger = await input.evaluate((e) => {
    const r = e.closest('[id^="flt-semantic-node-"]').getBoundingClientRect();
    return { x: r.x, bottom: r.bottom, width: r.width };
  });
  const bounds = await popup.boundingBox();
  assert.ok(
    Math.abs(bounds.x - trigger.x) <= 0.5,
    "Dropdown shares trigger left edge in shifted gallery overlay",
  );
  assert.ok(
    Math.abs(bounds.width - trigger.width) <= 0.5,
    "Dropdown shares trigger width",
  );
  assert.ok(
    Math.abs(bounds.y - trigger.bottom - 8) <= 0.5,
    "Dropdown uses standard density gap below trigger",
  );
  console.log("PASS: Flutter dropdown anchored in shifted Widgetbook viewport");
} finally {
  await browser.close();
}
