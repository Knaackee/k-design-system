import assert from "node:assert/strict";
import { createRequire } from "node:module";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
const browser = await chromium.launch({ channel: "msedge", headless: true });
try {
  const page = await browser.newPage({
    viewport: { width: 1024, height: 900 },
  });
  await page.goto(
    "http://localhost:6007/#/?path=patterns/datatable/data-table-groups&preview&viewport={name:Expanded%20%C2%B7%201024}&k-design={density:dense}",
  );
  await page.locator("flt-semantics-placeholder").evaluate((e) => e.click());
  const add = page.getByRole("button", {
    name: /Add project to In progress \/ Web/,
  });
  const title = (n) =>
    page.getByRole("textbox", { name: `Title for new-${n}`, exact: true });
  await add.click();
  await title(1).waitFor();
  await page.keyboard.type("Keyboard draft");
  await page.waitForFunction(
    () => document.activeElement?.value === "Keyboard draft",
  );
  await page.keyboard.press("Escape");
  await title(1).waitFor({ state: "detached" });
  assert.equal(
    await page.getByRole("button", { name: /Edit title for new-1/ }).count(),
    1,
    "changed draft retained",
  );
  await add.click();
  await title(2).waitFor();
  await page.keyboard.press("Escape");
  await title(2).waitFor({ state: "detached" });
  assert.equal(
    await page.getByRole("button", { name: /Edit title for new-2/ }).count(),
    0,
    "unchanged draft removed",
  );
  await add.click();
  await title(3).waitFor();
  await page
    .getByRole("textbox", { name: "Search projects", exact: true })
    .click();
  await title(3).waitFor({ state: "detached" });
  assert.equal(
    await page.getByRole("button", { name: /Edit title for new-3/ }).count(),
    0,
    "blur removes default draft",
  );
  const emptyStatus = () =>
    page.getByRole("textbox", { name: /^Status for\s*$/ });
  await add.click();
  await title(4).waitFor();
  await emptyStatus().click();
  await page.locator('[aria-label="Options"]').waitFor();
  assert.equal(
    await page.getByRole("button", { name: /Edit title for new-4/ }).count(),
    1,
  );
  await page.keyboard.press("Escape");
  await page.locator('[aria-label="Options"]').waitFor({ state: "detached" });
  assert.equal(
    await page.getByRole("button", { name: /Edit title for new-4/ }).count(),
    1,
    "popup cancel retains row",
  );
  await page
    .getByRole("textbox", { name: "Search projects", exact: true })
    .click();
  await page
    .getByRole("button", { name: /Edit title for new-4/ })
    .waitFor({ state: "detached" });
  await add.click();
  await title(5).waitFor();
  await emptyStatus().click();
  await page.locator('[aria-label="Options"]').waitFor();
  await page.keyboard.press("End");
  await page.keyboard.press("Enter");
  await page.locator('[aria-label="Options"]').waitFor({ state: "detached" });
  await page
    .getByRole("textbox", { name: "Search projects", exact: true })
    .click();
  assert.equal(
    await page.getByRole("button", { name: /Edit title for new-5/ }).count(),
    1,
    "status edit retains blank-title draft",
  );
  console.log(
    "PASS: Flutter browser initial keyboard focus, changed Escape retention, unchanged Escape/row-exit cleanup, same-row dropdown cancellation and status editing",
  );
} finally {
  await browser.close();
}
