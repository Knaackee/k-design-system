import assert from "node:assert/strict";
import { createRequire } from "node:module";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage({ viewport: { width: 700, height: 900 } });
const errors = [];
page.on("pageerror", (error) => errors.push(error.message));
const visit = async (story) => {
  await page.goto(
    `http://localhost:6006/iframe.html?id=patterns-datatablevirtual--${story}&viewMode=story&globals=language:en;density:standard`,
  );
  await page.locator(".k-virtual-table").waitFor();
};
const scroll = async (top) => {
  await page.locator(".k-virtual-table").evaluate((element, value) => {
    element.scrollTop = value;
  }, top);
  await page.waitForTimeout(100);
};
try {
  await visit("virtual");
  const table = page.getByRole("table", { name: "Virtual projects" });
  assert.equal(await table.getAttribute("aria-rowcount"), "244");
  assert.ok((await table.getByRole("row").count()) < 15);
  assert.ok(
    (await table.getByRole("cell").count()) < 60,
    "horizontal as well as vertical UI is bounded",
  );
  await page.getByRole("button", { name: "Edit row-0", exact: true }).click();
  const input = page.getByRole("textbox", { name: "Title row-0", exact: true });
  await input.fill("Draft retained");
  await input.press("Enter");
  assert.equal(await input.count(), 0, "Enter leaves the editor closed");
  assert.equal(
    await page.getByRole("status").textContent(),
    "Saved Draft retained",
  );
  await scroll(6000);
  assert.ok(
    !(await page
      .getByRole("button", { name: "Edit row-0", exact: true })
      .count()),
  );
  await scroll(0);
  assert.equal(
    await page
      .getByRole("button", { name: "Edit row-0", exact: true })
      .textContent(),
    "Draft retained",
  );
  await page.getByRole("button", { name: "Edit row-0", exact: true }).click();
  await input.fill("");
  await scroll(6000);
  assert.equal(await input.count(), 1);
  assert.ok(
    (await table.evaluate((el) => el.scrollTop)) < 100,
    "invalid editor remains visible",
  );
  await page.getByRole("button", { name: "Web (120)", exact: true }).click();
  assert.equal(
    await table.getAttribute("aria-rowcount"),
    "244",
    "invalid edit vetoes collapsing its group",
  );
  await input.fill("Discard this draft");
  await input.press("Escape");
  assert.equal(
    await page
      .getByRole("button", { name: "Edit row-0", exact: true })
      .textContent(),
    "Draft retained",
    "Escape cancels even when removing the input triggers blur",
  );
  await page.getByRole("button", { name: "Web (120)", exact: true }).click();
  assert.equal(await table.getAttribute("aria-rowcount"), "123");
  await page.getByRole("button", { name: "Web (120)", exact: true }).click();
  await page
    .getByRole("button", { name: "Focus project 201", exact: true })
    .click();
  await page.waitForFunction(
    () => document.activeElement?.getAttribute("aria-label") === "Edit row-200",
  );
  await page.keyboard.press("Enter");
  await page
    .getByRole("textbox", { name: "Title row-200", exact: true })
    .fill("Saved by scrolling");
  await scroll(0);
  assert.equal(
    await page
      .getByRole("textbox", { name: "Title row-200", exact: true })
      .count(),
    0,
  );
  assert.match(
    await page.getByRole("status").textContent(),
    /Saved by scrolling/,
  );
  await visit("external");
  const external = page.getByRole("table", { name: "External projects" });
  await page.getByText("Project 1", { exact: true }).waitFor();
  await scroll(4000);
  assert.ok((await external.getByRole("row").count()) < 15);
  assert.ok(
    Number(
      await external.getByRole("row").first().getAttribute("aria-rowindex"),
    ) > 30,
  );
  await page
    .getByRole("button", { name: "Deliver stale response", exact: true })
    .click();
  assert.equal(
    await page.getByText("STALE RESULT", { exact: true }).count(),
    0,
  );
  await page.getByRole("button", { name: "Change query", exact: true }).click();
  await page.getByText("Loading projects", { exact: true }).waitFor();
  await page
    .getByRole("button", { name: "Load requested range", exact: true })
    .click();
  await page.getByText("Project 1", { exact: true }).waitFor();
  await page
    .getByRole("button", { name: "Simulate error", exact: true })
    .click();
  assert.match(await page.getByRole("alert").textContent(), /Could not load/);
  assert.deepEqual(errors, []);
  console.log(
    "PASS virtual mounted bounds, edits/recycling, invalid exit/collapse veto, focus request, external windows and stale revisions",
  );
} finally {
  await browser.close();
}
