import assert from "node:assert/strict";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage({ viewport: { width: 1024, height: 900 } });
const base = process.env.KDS_WIDGETBOOK_URL || "http://localhost:6007";
const cases = [
  {
    folder: "datepicker",
    fixture: "date-picker-states",
    title: "Choose date",
    initial: "2026-09-16",
    next: "2026-09-18",
    fields: { Date: "18.09.2026" },
  },
  {
    folder: "timepicker",
    fixture: "time-picker-states",
    title: "Choose time",
    initial: "14:30",
    next: "15:45",
    fields: { Time: "15:45" },
  },
  {
    folder: "datetimepicker",
    fixture: "date-time-picker-states",
    title: "Choose date and time",
    initial: "2026-09-16T12:30:00.000Z",
    next: "2026-09-18T13:45:00.000Z",
    fields: { Date: "18.09.2026", Time: "15:45" },
  },
];
const button = (name) => page.getByRole("button", { name, exact: true });
const status = (value) =>
  page.getByText(`Value: ${value}`, { exact: true }).and(page.locator("span"));
try {
  for (const allowTextInput of [true, false]) {
    for (const fixture of cases) {
      await page.goto(
        `${base}/?picker-smoke=${fixture.folder}-${allowTextInput}#/?path=forms/${fixture.folder}/${fixture.fixture}&preview&knobs={allowTextInput:${allowTextInput},minuteStep:15}&viewport={name:Expanded%20%C2%B7%201024}&theme={name:Orbit%20Dark}&k-design={density:dense}`,
      );
      await page
        .locator("flt-semantics-placeholder")
        .evaluate((element) => element.click());
      await status(fixture.initial).waitFor();
      const trigger = page.getByRole("button", {
        name: fixture.title,
        exact: true,
        disabled: false,
      });
      assert.equal(
        await trigger.count(),
        1,
        "Only the editable fixture has an enabled trigger",
      );
      await trigger.click();
      await button("Apply").waitFor();
      if (!allowTextInput && fixture.folder === "datetimepicker") {
        for (const [header, choice] of [
          ["Month: September", "September"],
          ["Year: 2026", "2026"],
        ]) {
          await button(header).click();
          await page
            .getByRole("group", { name: "Hours", exact: true })
            .waitFor({ state: "hidden" });
          assert.equal(
            await page
              .getByRole("group", { name: "Hours", exact: true })
              .count(),
            0,
          );
          await button(choice).click();
          assert.equal(
            await page
              .getByRole("group", { name: "Hours", exact: true })
              .count(),
            0,
          );
          await button("16.09.2026").click();
          await page
            .getByRole("group", { name: "Hours", exact: true })
            .waitFor();
        }
      }
      const changeDraft = async () => {
        if (allowTextInput) {
          for (const [label, value] of Object.entries(fixture.fields)) {
            const input = page.getByRole("textbox", {
              name: label,
              exact: true,
            });
            await input.click();
            await page.keyboard.press("Control+A");
            await page.keyboard.type(value);
          }
        } else {
          assert.equal(await page.getByRole("textbox").count(), 0);
          if (fixture.fields.Date) await button("18.09.2026").click();
          if (fixture.fields.Time) {
            await page
              .getByRole("group", { name: "Hours", exact: true })
              .getByRole("button", { name: "15", exact: true })
              .click();
            await page
              .getByRole("group", { name: "Minutes", exact: true })
              .getByRole("button", { name: "45", exact: true })
              .click();
          }
        }
      };
      await changeDraft();
      await button("Cancel").click();
      await status(fixture.initial).waitFor();
      // Flutter logical focus is verified by keyboard activation after dismissal.
      await page.keyboard.press("Space");
      await button("Apply").waitFor();
      await changeDraft();
      await button("Apply").click();
      await status(fixture.next).waitFor();
      await page.keyboard.press("Space");
      await button("Clear").waitFor();
      await button("Clear").click();
      await status("None").waitFor();
      await page.keyboard.press("Space");
      await button("Apply").waitFor();
      assert.equal(
        await button("Clear").isDisabled(),
        true,
        "Empty value cannot be cleared again",
      );
      await button("Cancel").click();
      await status("None").waitFor();
      console.log(
        `Flutter ${fixture.fixture} manual=${allowTextInput}: cancel, apply, clear and keyboard focus return passed`,
      );
    }
  }
} catch (error) {
  console.error(await page.locator("body").ariaSnapshot());
  throw error;
} finally {
  await browser.close();
}
