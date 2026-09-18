import assert from "node:assert/strict";
import { createRequire } from "node:module";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
const browser = await chromium.launch({ channel: "msedge", headless: true });
try {
  const page = await browser.newPage({
    viewport: { width: 1024, height: 1200 },
  });
  await page.goto(
    "http://localhost:6006/iframe.html?id=patterns-datatable--cells&viewMode=story",
  );
  await page.getByRole("button", { name: "Cell text", exact: true }).click();
  const text = page.getByRole("textbox", { name: "Cell text", exact: true });
  await text.fill("Updated project");
  await text.press("Enter");
  await page
    .getByRole("button", { name: "Cell text", exact: true })
    .filter({ hasText: "Updated project" })
    .waitFor();
  const check = page.getByRole("checkbox", { name: "Approved" });
  assert.equal(await check.isChecked(), true);
  await check.click();
  assert.equal(await check.isChecked(), false);
  await page
    .getByRole("combobox", { name: "Cell select", exact: true })
    .click();
  await page.getByRole("option", { name: "Planned", exact: true }).click();
  await page
    .getByRole("combobox", { name: "Cell combobox", exact: true })
    .click();
  await page.getByRole("option", { name: "Sam Rivera", exact: true }).click();
  for (const kind of ["date", "time", "datetime"]) {
    await page
      .getByRole("button", { name: `Cell ${kind}`, exact: true })
      .click();
    await page.getByRole("dialog").waitFor();
    await page.keyboard.press("Escape");
    assert.equal(await page.getByRole("dialog").count(), 0);
  }
  await page
    .getByRole("button", { name: "Cell currency", exact: true })
    .click();
  const currency = page.getByRole("textbox", {
    name: "Cell currency",
    exact: true,
  });
  await currency.fill("2.345,67");
  await currency.press("Enter");
  await page
    .getByRole("button", { name: "Cell currency", exact: true })
    .filter({ hasText: "2.345,67" })
    .waitFor();
  assert.equal(
    await page
      .getByRole("button", { name: "Cell readonly", exact: true })
      .count(),
    0,
  );
  console.log(
    "PASS: composed form cells, first-click picker dialogs, localized currency commit, readonly content",
  );
} finally {
  await browser.close();
}
