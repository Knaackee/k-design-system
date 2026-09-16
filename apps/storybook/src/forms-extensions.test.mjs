import assert from "node:assert/strict";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage();
const base = process.env.KDS_STORYBOOK_URL || "http://localhost:6006";
try {
  await page.goto(
    `${base}/iframe.html?id=patterns-filterbar--filters&viewMode=story`,
  );
  const reset = page.getByRole("button", { name: "Reset all", exact: true });
  await reset.waitFor();
  const search = page.getByRole("searchbox", {
    name: "Search items",
    exact: true,
  });
  const status = page.getByRole("combobox", { name: "Status", exact: true });
  const person = page.getByRole("combobox", { name: "Assignee", exact: true });
  assert.equal(
    await page
      .getByRole("button", { name: "Clear search", exact: true })
      .count(),
    0,
  );
  await search.fill("roadmap");
  await page.keyboard.press("Tab");
  assert.equal(
    await page
      .getByRole("button", { name: "Clear search", exact: true })
      .evaluate((e) => e === document.activeElement),
    true,
  );
  await page.keyboard.press("Enter");
  assert.equal(await search.inputValue(), "");
  assert.equal(
    await search.evaluate((e) => e === document.activeElement),
    true,
  );
  await page.getByRole("button", { name: "Clear status", exact: true }).click();
  assert.equal(await status.inputValue(), "");
  assert.equal(
    await status.evaluate((e) => e === document.activeElement),
    true,
  );
  assert.equal(
    await page
      .getByRole("button", { name: "Remove Status: Active", exact: true })
      .count(),
    0,
  );
  await person.click();
  await person.fill("jor");
  assert.equal(await page.getByRole("option").count(), 1);
  await page
    .getByRole("button", { name: "Clear assignee", exact: true })
    .click();
  assert.equal(await person.inputValue(), "");
  assert.equal(await person.getAttribute("aria-expanded"), "false");
  assert.equal(
    await person.evaluate((e) => e === document.activeElement),
    true,
  );
  assert.equal(await reset.isDisabled(), true);
  // Empty selection with a draft query must also be clearable by keyboard.
  await person.fill("alex");
  await page.keyboard.press("Tab");
  assert.equal(
    await page
      .getByRole("button", { name: "Clear assignee", exact: true })
      .evaluate((e) => e === document.activeElement),
    true,
  );
  await page.keyboard.press("Space");
  assert.equal(await person.inputValue(), "");
  await person.click();
  const alex = page.getByRole("option", { name: "Alex", exact: true });
  await alex.waitFor();
  assert.equal(
    await alex.locator("img").evaluate(async (img) => {
      await img.decode();
      return img.naturalWidth > 0 && img.alt === "";
    }),
    true,
  );
  assert.equal(
    await alex.getAttribute("aria-label"),
    null,
    "label remains text based",
  );
  await alex.click();
  await page.locator(".k-selection__media img").evaluate(async (img) => {
    await img.decode();
  });
  // Failed image keeps the 16px slot and uses a decorative fallback icon.
  await page
    .locator(".k-selection__media img")
    .evaluate((img) => img.dispatchEvent(new Event("error")));
  await page.locator(".k-selection__media .k-icon").waitFor();
  assert.equal(await person.inputValue(), "Alex");
  await reset.click();
  assert.equal(await reset.isDisabled(), true);
  await page
    .getByRole("checkbox", { name: "Include archived", exact: true })
    .check();
  assert.equal(await reset.isEnabled(), true);
  assert.equal(
    await page.getByText("No active filters", { exact: true }).count(),
    0,
  );
  await reset.click();
  assert.equal(await reset.isDisabled(), true);
  await page.goto(
    `${base}/iframe.html?id=forms-searchfield--states&viewMode=story`,
  );
  await page
    .getByRole("searchbox", { name: "Read only", exact: true })
    .waitFor();
  for (const label of ["Read only", "Unavailable"]) {
    assert.equal(
      await page
        .getByRole("searchbox", { name: label, exact: true })
        .locator("xpath=..")
        .getByRole("button")
        .count(),
      0,
    );
  }
  await page.goto(`${base}/iframe.html?id=forms-select--states&viewMode=story`);
  const unavailable = page.getByRole("combobox", {
    name: "Unavailable",
    exact: true,
  });
  await unavailable.waitFor();
  assert.equal(await unavailable.isDisabled(), true);
  assert.equal(
    await unavailable
      .locator("xpath=../..")
      .locator(".k-option-media,.k-form-clear")
      .count(),
    0,
  );
  console.log(
    "Forms extensions: clear/focus/query/reset/media/disabled checks passed",
  );
} finally {
  await browser.close();
}
