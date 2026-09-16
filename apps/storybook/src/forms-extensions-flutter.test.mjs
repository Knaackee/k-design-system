import assert from "node:assert/strict";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage({ viewport: { width: 1024, height: 900 } });
const focusReady = (label) =>
  page.waitForFunction(
    (name) => document.activeElement?.getAttribute("aria-label") === name,
    label,
  );
try {
  await page.goto(
    "http://localhost:6007/#/?path=patterns/filterbar/filter-bar-filters&preview&viewport={name:Expanded%20%C2%B7%201024}&theme={name:Orbit%20Dark}&k-design={density:dense}",
  );
  await page.locator("flt-semantics-placeholder").evaluate((e) => e.click());
  const reset = page.getByRole("button", { name: "Reset all", exact: true });
  await reset.waitFor();
  const search = page.getByRole("textbox", {
    name: "Search items",
    exact: true,
  });
  const person = page.getByRole("textbox", { name: "Assignee", exact: true });
  await search.click();
  await focusReady("Search items");
  await page.keyboard.type("Roadmap");
  const clearSearch = page.getByRole("button", {
    name: "Clear search",
    exact: true,
  });
  await clearSearch.waitFor();
  assert.equal(await search.inputValue(), "Roadmap");
  await clearSearch.click();
  await clearSearch.waitFor({ state: "detached" });
  await focusReady("Search items");
  await page.keyboard.type("Again");
  await clearSearch.waitFor();
  assert.equal(await search.inputValue(), "Again");
  await clearSearch.click();
  await page.getByRole("button", { name: "Clear status", exact: true }).click();
  await page
    .getByRole("button", { name: "Remove Status: Active", exact: true })
    .waitFor({ state: "detached" });
  await person.click();
  await focusReady("Assignee");
  await page.keyboard.type("jor");
  await page.getByText("Jordan", { exact: true }).waitFor();
  await page
    .getByRole("button", { name: "Clear assignee", exact: true })
    .click();
  await page
    .getByRole("button", { name: "Remove Assignee: Alex", exact: true })
    .waitFor({ state: "detached" });
  await page
    .getByRole("group", {
      name: "Workspace filters No active filters",
      exact: true,
    })
    .waitFor();
  assert.equal(await reset.isDisabled(), true);
  // A draft query alone also exposes a keyboard-operable clear action.
  await person.click();
  await focusReady("Assignee");
  await page.keyboard.type("alex");
  await page.getByText("Alex", { exact: true }).waitFor();
  await page.keyboard.press("Tab");
  await focusReady("Clear assignee");
  await page.keyboard.press("Space");
  await page
    .getByRole("button", { name: "Clear assignee", exact: true })
    .waitFor({ state: "detached" });
  await focusReady("Assignee");
  await page.keyboard.type("jor");
  await page.getByText("Jordan", { exact: true }).waitFor();
  await page.keyboard.press("Enter");
  await page
    .getByRole("button", { name: "Remove Assignee: Jordan", exact: true })
    .waitFor();
  await reset.click();
  await page
    .getByRole("group", {
      name: "Workspace filters No active filters",
      exact: true,
    })
    .waitFor();
  assert.equal(await reset.isDisabled(), true);
  console.log(
    "Flutter forms extensions: clear/focus/query/keyboard/reset checks passed",
  );
} catch (error) {
  console.error(await page.locator("body").ariaSnapshot());
  throw error;
} finally {
  await browser.close();
}
