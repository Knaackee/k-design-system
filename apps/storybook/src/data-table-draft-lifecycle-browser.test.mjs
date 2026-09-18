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
    "http://localhost:6006/iframe.html?id=patterns-datatable--groups&viewMode=story&globals=density:dense",
  );
  const add = page.getByRole("button", {
    name: "Add project to In progress / Web",
    exact: true,
  });
  await add.click();
  const title = page.getByRole("textbox", {
    name: "Title for new-1",
    exact: true,
  });
  await title.waitFor();
  assert.ok(await title.evaluate((e) => e === document.activeElement));
  const table = title.locator("xpath=ancestor::table");
  const status = page.getByRole("combobox", {
    name: "Status for ",
    exact: true,
  });
  await status.click();
  await page.getByRole("option", { name: "Done", exact: true }).click();
  const draft = page.getByRole("button", {
    name: "Edit title for new-1",
    exact: true,
  });
  await draft.waitFor();
  assert.equal(
    await draft.locator("xpath=ancestor::table").getAttribute("aria-label"),
    "Project workspace / In progress / Web",
  );
  await page.getByRole("searchbox", { name: "Search projects" }).click();
  assert.equal(await draft.count(), 1);
  await draft.click();
  await title.fill("Committed project");
  await title.press("Enter");
  await page
    .getByRole("status")
    .filter({ hasText: "committed: new-1" })
    .waitFor();
  assert.equal(
    await page
      .getByRole("button", { name: "Edit title for new-1" })
      .locator("xpath=ancestor::table")
      .getAttribute("aria-label"),
    "Project workspace / Done / Web",
  );
  await add.click();
  const two = page.getByRole("textbox", {
    name: "Title for new-2",
    exact: true,
  });
  await two.fill("Discard me");
  await two.press("Escape");
  assert.equal(
    await page.getByRole("button", { name: "Edit title for new-2" }).count(),
    0,
  );
  await add.click();
  const three = page.getByRole("textbox", {
    name: "Title for new-3",
    exact: true,
  });
  await three.waitFor();
  await page.getByRole("searchbox", { name: "Search projects" }).click();
  await three.waitFor({ state: "detached" });
  assert.equal(
    await page.getByRole("button", { name: "Edit title for new-3" }).count(),
    0,
  );
  await page.getByRole("checkbox", { name: "Fail save" }).check();
  await add.click();
  const four = page.getByRole("textbox", {
    name: "Title for new-4",
    exact: true,
  });
  await four.fill("Retry project");
  await four.press("Enter");
  await page.getByRole("alert").filter({ hasText: "Save failed" }).waitFor();
  await page.getByRole("checkbox", { name: "Fail save" }).uncheck();
  await page.getByRole("checkbox", { name: "Delay save" }).check();
  await page.getByRole("button", { name: "Save new-4", exact: true }).click();
  assert.equal(
    await page
      .getByRole("button", { name: "Cancel new-4", exact: true })
      .isDisabled(),
    true,
  );
  await page
    .getByRole("status")
    .filter({ hasText: "committed: new-4" })
    .waitFor();
  console.log(
    "PASS draft creation/focus, status stays pinned, dirty exit retention, explicit save/regroup, changed Escape and pristine cleanup",
  );
} finally {
  await browser.close();
}
