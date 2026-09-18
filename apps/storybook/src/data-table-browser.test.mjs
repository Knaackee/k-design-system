import assert from "node:assert/strict";
import { createRequire } from "node:module";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage({ viewport: { width: 1024, height: 900 } });
const visit = async (fixture) => {
  await page.goto(
    `http://localhost:6006/iframe.html?id=patterns-datatable--${fixture}&viewMode=story&globals=language:en;density:standard`,
  );
  await page.locator(".k-table").first().waitFor();
};
const ids = () =>
  page
    .locator(".k-table tbody tr")
    .evaluateAll((es) => es.map((e) => e.dataset.rowId));
try {
  await visit("rows");
  assert.deepEqual(await ids(), [
    "atlas",
    "orbit",
    "docs",
    "portal",
    "audit",
    "sync",
  ]);
  const chooseSort = async (name) => {
    await page.getByRole("button", { name: "Sort", exact: true }).click();
    await page.getByRole("menuitem", { name, exact: true }).click();
  };
  await page.getByRole("button", { name: "Sort", exact: true }).focus();
  await page.keyboard.press("Enter");
  await page
    .getByRole("menuitem", { name: "Budget ascending", exact: true })
    .click();
  assert.deepEqual(await ids(), [
    "audit",
    "docs",
    "sync",
    "portal",
    "orbit",
    "atlas",
  ]);
  await chooseSort("Budget descending");
  assert.deepEqual(await ids(), [
    "atlas",
    "orbit",
    "portal",
    "sync",
    "docs",
    "audit",
  ]);
  await chooseSort("Original order");
  assert.deepEqual(await ids(), [
    "atlas",
    "orbit",
    "docs",
    "portal",
    "audit",
    "sync",
  ]);
  assert.ok(
    await page
      .locator(".k-table thead")
      .evaluate((e) => getComputedStyle(e).clipPath === "inset(50%)"),
    "No visible table header",
  );
  await page.getByRole("searchbox", { name: "Search projects" }).fill("alex");
  assert.deepEqual(await ids(), ["atlas", "portal"]);
  await page
    .getByRole("combobox", { name: "Status filter", exact: true })
    .click();
  await page.getByRole("option", { name: "Planned", exact: true }).click();
  assert.deepEqual(await ids(), ["portal"]);
  await page.getByRole("button", { name: "Reset all", exact: true }).click();
  assert.equal((await ids()).length, 6);
  await page
    .getByRole("searchbox", { name: "Search projects" })
    .fill("nonexistent");
  await page
    .getByRole("status")
    .filter({ hasText: "No matching projects" })
    .waitFor();
  assert.equal(await page.locator(".k-table").count(), 0);
  await page.getByRole("button", { name: "Reset all", exact: true }).click();
  await visit("groups");
  const parent = page.getByRole("button", {
    name: "In progress (3)",
    exact: true,
  });
  await parent.click();
  assert.equal(await parent.getAttribute("aria-expanded"), "false");
  assert.deepEqual(await ids(), ["orbit", "portal", "audit"]);
  await parent.click();
  await page.getByRole("button", { name: "Web (2)", exact: true }).click();
  assert.deepEqual(await ids(), ["sync", "orbit", "portal", "audit"]);
  await parent.click();
  await parent.click();
  assert.equal(
    await page
      .getByRole("button", { name: "Web (2)", exact: true })
      .getAttribute("aria-expanded"),
    "false",
  );
  await page.getByRole("button", { name: "Web (2)", exact: true }).click();
  await page
    .getByRole("combobox", { name: "Status for Atlas website", exact: true })
    .click();
  await page.getByRole("option", { name: "Done", exact: true }).click();
  await page.getByRole("button", { name: "Done (2)", exact: true }).waitFor();
  assert.equal((await ids()).length, 6);
  await chooseSort("Project ascending");
  const trigger = page.getByRole("button", {
    name: "Edit title for atlas",
    exact: true,
  });
  assert.equal(
    await page
      .getByRole("textbox", { name: "Title for atlas", exact: true })
      .count(),
    0,
  );
  await trigger.click();
  const title = page.getByRole("textbox", {
    name: "Title for atlas",
    exact: true,
  });
  assert.ok(await title.evaluate((e) => e === document.activeElement));
  await title.fill("Zeta");
  await title.press("End");
  await page.keyboard.type(" updated");
  assert.equal(await title.inputValue(), "Zeta updated");
  assert.ok(await title.evaluate((e) => e === document.activeElement));
  await title.press("Enter");
  assert.equal(await trigger.innerText(), "Zeta updated");
  assert.ok(await trigger.evaluate((e) => e === document.activeElement));
  await trigger.press("Enter");
  await title.fill("Discard me");
  await title.press("Escape");
  assert.equal(await trigger.innerText(), "Zeta updated");
  await trigger.click();
  await title.fill("Atlas revised");
  await page.getByRole("button", { name: "Open atlas", exact: true }).click();
  assert.equal(await trigger.innerText(), "Atlas revised");
  assert.match(
    await page.getByRole("status").innerText(),
    /Open: Atlas revised/,
  );
  assert.ok(
    await page
      .getByRole("button", { name: "Open atlas", exact: true })
      .evaluate((e) => e === document.activeElement),
  );
  await page.getByRole("button", { name: "Done (2)", exact: true }).click();
  await page.getByRole("button", { name: "Done (2)", exact: true }).click();
  assert.equal(await trigger.innerText(), "Atlas revised");
  await page
    .getByRole("searchbox", { name: "Search projects" })
    .fill("Atlas revised");
  assert.deepEqual(await ids(), ["atlas"]);
  await page.getByRole("button", { name: "Reset all", exact: true }).click();
  assert.equal(await trigger.innerText(), "Atlas revised");
  const resting = page.getByRole("combobox", {
    name: "Status for Atlas revised",
    exact: true,
  });
  assert.equal(
    await resting.evaluate((e) => getComputedStyle(e).borderTopColor),
    "rgba(0, 0, 0, 0)",
  );
  await resting.click();
  await page.getByRole("option", { name: "Planned", exact: true }).waitFor();
  await page.keyboard.press("Escape");
  await trigger.click();
  await title.fill("Outside commit");
  await page.mouse.click(4, 4);
  assert.equal(await title.count(), 0);
  assert.equal(await trigger.innerText(), "Outside commit");
  assert.equal(
    await page.evaluate(() => document.activeElement === document.body),
    true,
    "blank pointer click must not restore cell focus",
  );
  await visit("groups");
  const add = page.getByRole("button", {
    name: "Add project to In progress / Web",
    exact: true,
  });
  await add.click();
  const newTitle = (n) =>
    page.getByRole("textbox", { name: `Title for new-${n}`, exact: true });
  assert.equal(await newTitle(1).inputValue(), "");
  assert.ok(await newTitle(1).evaluate((e) => e === document.activeElement));
  await newTitle(1).press("Escape");
  await page.waitForFunction(
    () =>
      document.activeElement?.getAttribute("aria-label") ===
      "Add project to In progress / Web",
  );
  assert.equal(
    await page.getByRole("button", { name: "Open new-1", exact: true }).count(),
    0,
  );
  await add.click();
  await page.getByRole("searchbox", { name: "Search projects" }).click();
  assert.equal(
    await page.getByRole("button", { name: "Open new-2", exact: true }).count(),
    0,
  );
  await add.click();
  await newTitle(3).fill("Created project");
  await newTitle(3).press("Escape");
  assert.equal(
    await page
      .getByRole("button", { name: "Edit title for new-3", exact: true })
      .count(),
    0,
    "Escape cancels changed new draft",
  );
  await add.click();
  await newTitle(4).fill("Another project");
  await page.getByRole("searchbox", { name: "Search projects" }).click();
  assert.equal(
    await page
      .getByRole("button", { name: "Edit title for new-4", exact: true })
      .innerText(),
    "Another project",
  );
  await add.click();
  const pendingRow = page.locator('tr[data-row-id="new-5"]');
  await pendingRow.getByRole("combobox").click();
  await page.getByRole("option", { name: "Done", exact: true }).waitFor();
  assert.equal(
    await pendingRow.count(),
    1,
    "same-row dropdown preserves empty draft",
  );
  await page.keyboard.press("Escape");
  assert.equal(
    await pendingRow.count(),
    1,
    "closing dropdown is not leaving row",
  );
  await page.getByRole("searchbox", { name: "Search projects" }).click();
  await pendingRow.waitFor({ state: "detached" });
  await add.click();
  const changedRow = page.locator('tr[data-row-id="new-6"]');
  await newTitle(6).press("Tab");
  assert.ok(
    await changedRow
      .getByRole("combobox")
      .evaluate((e) => e === document.activeElement),
    "Tab remains inside row",
  );
  await changedRow.getByRole("combobox").press("ArrowDown");
  await page.getByRole("option", { name: "Done", exact: true }).click();
  await page.getByRole("searchbox", { name: "Search projects" }).click();
  assert.equal(
    await changedRow.count(),
    1,
    "changed status keeps default-title row",
  );
  await visit("rows");
  await page
    .getByRole("searchbox", { name: "Search projects" })
    .fill("no match");
  await page.getByRole("button", { name: "Add project", exact: true }).click();
  assert.ok(
    await newTitle(1).evaluate((e) => e === document.activeElement),
    "draft remains visible with active filter",
  );
  await newTitle(1).fill("temporary");
  await newTitle(1).fill("");
  await newTitle(1).press("Escape");
  assert.equal(
    await page.getByRole("button", { name: "Open new-1", exact: true }).count(),
    0,
  );
  console.log(
    "PASS: external sort menu/keyboard, combined filters/reset/empty, nested collapse persistence, cell editing regroup, title edit/focus/caret/persistence, leading icons, new draft focus/default cleanup/retention",
  );
} finally {
  await browser.close();
}
