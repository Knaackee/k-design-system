import assert from "node:assert/strict";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage();
const story = async (id) => {
  await page.goto(
    `${process.env.KDS_STORYBOOK_URL || "http://localhost:6006"}/iframe.html?id=${id}&viewMode=story`,
  );
  await page.getByText("Workspace filters", { exact: true }).waitFor();
};
try {
  await story("forms-input--states");
  const title = page.getByRole("textbox", { name: "Title", exact: false });
  await title.fill("Sprint planning");
  assert.equal(await title.getAttribute("required"), "");
  assert.equal(
    await page
      .getByRole("textbox", { name: "Required name" })
      .getAttribute("aria-invalid"),
    "true",
  );
  const description = await page
    .getByRole("textbox", { name: "Required name" })
    .getAttribute("aria-describedby");
  assert.equal(
    await page.locator(`[id="${description}"]`).innerText(),
    "Enter an item name.",
  );
  assert.equal(
    await page.getByRole("textbox", { name: "Read only" }).isEditable(),
    false,
  );
  assert.equal(
    await page
      .getByRole("textbox", { name: "Unavailable", exact: true })
      .isDisabled(),
    true,
  );
  await story("forms-checkbox--states");
  const mixed = page.getByRole("checkbox", { name: "Select group" });
  assert.equal(await mixed.evaluate((e) => e.indeterminate), true);
  await mixed.focus();
  await page.keyboard.press("Space");
  assert.equal(await mixed.isChecked(), true);
  assert.equal(
    await page.getByRole("checkbox", { name: "Unavailable" }).isDisabled(),
    true,
  );
  await story("patterns-filterbar--filters");
  const status = page.getByRole("combobox", { name: "Status", exact: true });
  await status.focus();
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("Enter");
  assert.equal(await status.inputValue(), "Planned");
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("Enter");
  assert.equal(await status.inputValue(), "Active", "disabled Closed skipped");
  const person = page.getByRole("combobox", { name: "Assignee", exact: true });
  await person.click();
  await person.fill("jor");
  assert.equal(await page.getByRole("option").count(), 1);
  await page.keyboard.press("Escape");
  assert.equal(await person.inputValue(), "Alex", "Escape cancels query");
  await person.click();
  await person.fill("missing");
  assert.equal(await page.getByText("No results", { exact: true }).count(), 1);
  await person.fill("jor");
  await page.keyboard.press("Enter");
  assert.equal(await person.inputValue(), "Jordan");
  await person.click();
  await person.fill("sam");
  assert.equal(
    await page
      .getByRole("option", { name: "Sam" })
      .getAttribute("aria-disabled"),
    "true",
  );
  await page.keyboard.press("Enter");
  await page.keyboard.press("Escape");
  assert.equal(await person.inputValue(), "Jordan");
  await page.getByRole("searchbox", { name: "Search items" }).fill("roadmap");
  await page.getByRole("checkbox", { name: "Include archived" }).check();
  await page.getByRole("button", { name: "Remove Status: Active" }).click();
  assert.equal(await status.inputValue(), "");
  await page.getByRole("button", { name: "Reset all", exact: true }).click();
  assert.equal(await person.inputValue(), "");
  assert.equal(
    await page.getByRole("searchbox", { name: "Search items" }).inputValue(),
    "",
  );
  assert.equal(
    await page.getByRole("checkbox", { name: "Include archived" }).isChecked(),
    false,
  );
  assert.equal(
    await page.getByText("No active filters", { exact: true }).count(),
    1,
  );
  for (const density of ["dense", "standard", "spacious"])
    for (const width of [375, 700, 1024]) {
      await page.setViewportSize({ width, height: 900 });
      await page.evaluate((density) => {
        document.querySelector(".k-gallery").dataset.density = density;
        document.documentElement.style.setProperty("--k-text-scale", "2");
      }, density);
      await status.click();
      const rect = await page.getByRole("listbox").boundingBox();
      assert.ok(
        rect.x >= 7.9 && rect.x + rect.width <= width - 7.9,
        `${width}/${density}: popup bounds`,
      );
      await page.keyboard.press("Escape");
      assert.equal(
        await page.evaluate(
          () => document.documentElement.scrollWidth > innerWidth,
        ),
        false,
        `${width}/${density}: overflow`,
      );
    }
  console.log(
    "Forms Web: labels, error/read-only/disabled, mixed checkbox, keyboard selection, local search/cancel, disabled skip, removal/reset, 9 responsive cases passed",
  );
} finally {
  await browser.close();
}
