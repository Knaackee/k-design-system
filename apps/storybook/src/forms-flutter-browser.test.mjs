import assert from "node:assert/strict";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage({ viewport: { width: 1024, height: 900 } });
try {
  await page.goto(
    "http://localhost:6007/#/?path=patterns/filterbar/filter-bar-filters&preview&viewport={name:Expanded%20%C2%B7%201024}&theme={name:Orbit%20Dark}&k-design={density:dense}",
  );
  await page.locator("flt-semantics-placeholder").evaluate((e) => e.click());
  await page.getByRole("button", { name: "Reset all", exact: true }).waitFor();
  const status = page.getByRole("textbox", { name: "Status", exact: true });
  await status.click();
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("Enter");
  await page
    .getByRole("button", { name: "Remove Status: Planned", exact: true })
    .waitFor();
  await status.click();
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("Enter");
  await page
    .getByRole("button", { name: "Remove Status: Active", exact: true })
    .waitFor();
  const person = page.getByRole("textbox", { name: "Assignee", exact: true });
  await person.click();
  await page.keyboard.type("jor");
  await page.getByText("Jordan", { exact: true }).waitFor();
  await page.keyboard.press("Escape");
  await page
    .getByRole("button", { name: "Remove Assignee: Alex", exact: true })
    .waitFor();
  await person.click();
  await page.keyboard.type("jor");
  await page.keyboard.press("Enter");
  await page
    .getByRole("button", { name: "Remove Assignee: Jordan", exact: true })
    .waitFor();
  await page
    .getByRole("checkbox", { name: "Include archived", exact: true })
    .click();
  await page
    .getByRole("checkbox", {
      name: "Include archived",
      exact: true,
      checked: true,
    })
    .waitFor();
  await page.keyboard.press("Space");
  await page
    .getByRole("checkbox", {
      name: "Include archived",
      exact: true,
      checked: false,
    })
    .waitFor();
  await page
    .getByRole("button", { name: "Remove Status: Active", exact: true })
    .click();
  await page
    .getByRole("button", { name: "Remove Status: Active", exact: true })
    .waitFor({ state: "detached" });
  await page.getByRole("button", { name: "Reset all", exact: true }).click();
  await page
    .getByRole("group", {
      name: "Workspace filters No active filters",
      exact: true,
    })
    .waitFor();
  assert.equal(
    await page
      .getByRole("checkbox", { name: "Include archived", exact: true })
      .getAttribute("aria-checked"),
    "false",
  );
  console.log(
    "Flutter browser: keyboard selection, disabled skip, local search, Escape, checkbox, removal/reset passed",
  );
} catch (error) {
  console.error(await page.locator("body").ariaSnapshot());
  throw error;
} finally {
  await browser.close();
}
