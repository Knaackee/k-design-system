import assert from "node:assert/strict";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage({ viewport: { width: 1024, height: 900 } });
const base = process.env.KDS_STORYBOOK_URL || "http://localhost:6006";
const story = async (id, args = "") => {
  await page.goto(
    `${base}/iframe.html?` +
      new URLSearchParams({
        id,
        viewMode: "story",
        args: `allowTextInput:true;${args}`,
      }),
  );
  await page.getByText("Schedule", { exact: true }).waitFor();
};
try {
  await story("forms-datepicker--states");
  const date = page.getByRole("textbox", { name: "Date", exact: true });
  assert.equal(await date.inputValue(), "16.09.2026");
  await date.fill("31.02.2026");
  await date.press("Enter");
  await page.getByRole("alert").waitFor();
  assert.equal(await page.getByRole("status").innerText(), "Value: 2026-09-16");
  await date.fill("29.02.2024");
  await date.press("Enter");
  assert.equal(await page.getByRole("status").innerText(), "Value: 2024-02-29");
  const trigger = page
    .getByRole("button", { name: "Choose date", exact: true })
    .first();
  await trigger.click();
  let dialog = page.getByRole("dialog");
  await dialog.getByRole("button", { name: "29.02.2024", exact: true }).focus();
  await page.keyboard.press("PageDown");
  assert.equal(
    await dialog
      .getByRole("button", { name: "29.03.2024", exact: true })
      .evaluate((e) => e === document.activeElement),
    true,
  );
  await page.keyboard.press("ArrowRight");
  await page.keyboard.press("Enter");
  assert.equal(
    await dialog
      .getByRole("textbox", { name: "Date", exact: true })
      .inputValue(),
    "30.03.2024",
  );
  await dialog.getByRole("button", { name: "Cancel", exact: true }).click();
  assert.equal(await date.inputValue(), "29.02.2024");
  assert.equal(
    await trigger.evaluate((e) => e === document.activeElement),
    true,
  );
  await trigger.click();
  await dialog.getByRole("button", { name: "Clear", exact: true }).click();
  assert.equal(await date.inputValue(), "");
  assert.equal(
    await trigger.evaluate((e) => e === document.activeElement),
    true,
  );
  assert.equal(
    await page
      .getByRole("textbox", { name: "Read only", exact: true })
      .isEditable(),
    false,
  );
  assert.equal(
    await page
      .getByRole("textbox", { name: "Unavailable", exact: true })
      .isDisabled(),
    true,
  );
  await story("forms-timepicker--states", "timeFormat:h12");
  const time = page.getByRole("textbox", { name: "Time", exact: true });
  assert.equal(await time.inputValue(), "02:30 PM");
  await time.fill("12:05 AM");
  await time.press("Enter");
  assert.equal(await page.getByRole("status").innerText(), "Value: 00:05");
  await page
    .getByRole("button", { name: "Choose time", exact: true })
    .first()
    .click();
  dialog = page.getByRole("dialog");
  await dialog
    .getByRole("textbox", { name: "Time", exact: true })
    .fill("09:45 PM");
  await dialog.getByRole("button", { name: "Apply", exact: true }).click();
  assert.equal(await page.getByRole("status").innerText(), "Value: 21:45");
  await story("forms-datetimepicker--states");
  const datetime = page.getByRole("textbox", {
    name: "Date and time",
    exact: true,
  });
  assert.equal(await datetime.inputValue(), "16.09.2026 14:30");
  await datetime.fill("29.03.2026 02:30");
  await datetime.press("Enter");
  await page
    .getByText("This local time does not exist in the selected time zone.", {
      exact: true,
    })
    .waitFor();
  await datetime.fill("25.10.2026 02:30");
  await datetime.press("Enter");
  await page
    .getByText(
      "This local time occurs twice. Choose an explicit disambiguation policy.",
      { exact: true },
    )
    .waitFor();
  await story(
    "forms-datetimepicker--states",
    "disambiguation:later;timeZone:Europe_Berlin",
  );
  await page
    .getByRole("textbox", { name: "Date and time", exact: true })
    .fill("25.10.2026 02:30");
  await page.keyboard.press("Enter");
  assert.equal(
    await page.getByRole("status").innerText(),
    "Value: 2026-10-25T01:30:00.000Z",
  );
  await story(
    "forms-datetimepicker--states",
    "timeZone:America_New_York;dateFormat:monthDayYear;timeFormat:h12;locale:de",
  );
  assert.equal(
    await page
      .getByRole("textbox", { name: "Date and time", exact: true })
      .inputValue(),
    "09/16/2026 08:30 AM",
  );
  await page
    .getByRole("button", { name: "Datum und Uhrzeit wählen", exact: true })
    .first()
    .click();
  assert.equal(
    await page.getByText("America/New_York", { exact: true }).count(),
    0,
  );
  await page.keyboard.press("Escape");
  assert.equal(await page.getByRole("dialog").count(), 0);
  await story("forms-datepicker--states", "allowTextInput:false");
  await page.getByRole("textbox", { name: "Date", exact: true }).click();
  dialog = page.getByRole("dialog");
  assert.equal(await dialog.getByRole("textbox").count(), 0);
  await dialog
    .getByRole("button", { name: "Month: September", exact: true })
    .click();
  assert.equal(
    await dialog
      .getByRole("button", { name: "September", exact: true })
      .evaluate((element) => element === document.activeElement),
    true,
  );
  await dialog.getByRole("button", { name: "October", exact: true }).click();
  await dialog.getByRole("button", { name: "Year: 2026", exact: true }).click();
  const currentYear = dialog.getByRole("button", { name: "2026", exact: true });
  assert.equal(
    await currentYear.evaluate((element) => element === document.activeElement),
    true,
  );
  await currentYear.click();
  assert.equal(
    await dialog
      .getByRole("button", { name: "16.10.2026", exact: true })
      .evaluate((element) => element === document.activeElement),
    true,
  );
  await dialog.getByRole("button", { name: "Year: 2026", exact: true }).click();
  await dialog.getByRole("button", { name: "2027", exact: true }).click();
  await dialog.getByRole("button", { name: "18.10.2027", exact: true }).click();
  await dialog.getByRole("button", { name: "Apply", exact: true }).click();
  assert.equal(await page.getByRole("status").innerText(), "Value: 2027-10-18");

  for (const kind of ["time", "datetime"]) {
    await story(
      `forms-${kind}picker--states`,
      "allowTextInput:false;minuteStep:15;timeFormat:h12",
    );
    await page
      .getByRole("textbox", {
        name: kind === "time" ? "Time" : "Date and time",
        exact: true,
      })
      .click();
    dialog = page.getByRole("dialog");
    assert.equal(await dialog.getByRole("textbox").count(), 0);
    const hours = dialog.getByRole("group", { name: "Hours", exact: true });
    const minutes = dialog.getByRole("group", { name: "Minutes", exact: true });
    const period = dialog.getByRole("group", { name: "Period", exact: true });
    assert.equal(await minutes.getByRole("button").count(), 4);
    await hours.getByRole("button", { name: "03", exact: true }).click();
    await minutes.getByRole("button", { name: "45", exact: true }).click();
    await period.getByRole("button", { name: "PM", exact: true }).click();
    await dialog.getByRole("button", { name: "Apply", exact: true }).click();
    assert.equal(
      await page.getByRole("status").innerText(),
      kind === "time" ? "Value: 15:45" : "Value: 2026-09-16T13:45:00.000Z",
    );
  }
  await story("forms-timepicker--states", "minuteStep:15");
  const offStepTime = page.getByRole("textbox", { name: "Time", exact: true });
  await offStepTime.fill("12:07");
  await offStepTime.press("Enter");
  assert.equal(await page.getByRole("status").innerText(), "Value: 12:07");
  await page
    .getByRole("button", { name: "Choose time", exact: true })
    .first()
    .click();
  dialog = page.getByRole("dialog");
  const offStepMinutes = dialog.getByRole("group", {
    name: "Minutes",
    exact: true,
  });
  const selectedMinute = offStepMinutes.getByRole("button", {
    name: "07",
    exact: true,
  });
  assert.equal(await selectedMinute.getAttribute("aria-pressed"), "true");
  await selectedMinute.focus();
  await page.keyboard.press("ArrowDown");
  const nextMinute = offStepMinutes.getByRole("button", {
    name: "15",
    exact: true,
  });
  await page.waitForFunction(
    () => document.activeElement?.textContent === "15",
  );
  assert.equal(await nextMinute.getAttribute("aria-pressed"), "true");
  assert.equal(
    await nextMinute.evaluate((element) => element === document.activeElement),
    true,
  );
  await dialog.getByRole("button", { name: "Apply", exact: true }).click();
  assert.equal(await page.getByRole("status").innerText(), "Value: 12:15");
  await story("forms-datetimepicker--states", "allowTextInput:false");
  await page
    .getByRole("textbox", { name: "Date and time", exact: true })
    .click();
  dialog = page.getByRole("dialog");
  const timeColumns = dialog.locator(".k-picker-time");
  assert.equal(await timeColumns.count(), 1);
  for (const [header, choice] of [
    ["Month: September", "September"],
    ["Year: 2026", "2026"],
  ]) {
    await dialog.getByRole("button", { name: header, exact: true }).click();
    assert.equal(await timeColumns.count(), 0);
    await dialog.getByRole("button", { name: choice, exact: true }).click();
    assert.equal(
      await timeColumns.count(),
      0,
      "Time stays hidden until a day is chosen",
    );
    await dialog
      .getByRole("button", { name: "16.09.2026", exact: true })
      .click();
    assert.equal(await timeColumns.count(), 1);
  }
  const scroll = dialog
    .getByRole("group", { name: "Minutes", exact: true })
    .locator(".k-picker-time-scroll");
  await page.waitForTimeout(100);
  const before = await scroll.evaluate((e) => e.scrollTop);
  const bounds = await scroll.boundingBox();
  await page.mouse.move(
    bounds.x + bounds.width / 2,
    bounds.y + bounds.height / 2,
  );
  await page.mouse.down();
  await page.mouse.move(
    bounds.x + bounds.width / 2,
    bounds.y + bounds.height / 2 - 60,
    { steps: 10 },
  );
  await page.mouse.up();
  assert.ok(
    (await scroll.evaluate((e) => e.scrollTop)) > before + 40,
    "Mouse drag scrolls time column",
  );
  assert.equal(
    await scroll.locator('[aria-pressed="true"]').innerText(),
    "30",
    "Dragging does not select a value",
  );
  await dialog.getByRole("button", { name: "Apply", exact: true }).click();
  assert.equal(
    await page.getByRole("status").innerText(),
    "Value: 2026-09-16T12:30:00.000Z",
  );
  await page
    .getByRole("textbox", { name: "Date and time", exact: true })
    .click();
  await page
    .getByRole("dialog")
    .getByRole("button", { name: "Clear", exact: true })
    .click();
  await page
    .getByRole("textbox", { name: "Date and time", exact: true })
    .click();
  assert.equal(
    await page.locator(".k-picker-time").count(),
    0,
    "Empty date-time waits for day choice",
  );
  await page.getByRole("button", { name: "16.09.2026", exact: true }).click();
  assert.equal(await page.locator(".k-picker-time").count(), 1);
  await story("forms-timepicker--states", "allowTextInput:false");
  await page.getByRole("textbox", { name: "Time", exact: true }).click();
  const swipeColumn = page
    .getByRole("group", { name: "Minutes", exact: true })
    .locator(".k-picker-time-scroll");
  await page.waitForTimeout(100);
  const swipeBefore = await swipeColumn.evaluate((e) => e.scrollTop);
  const swipeBounds = await swipeColumn.boundingBox();
  const cdp = await page.context().newCDPSession(page);
  const x = swipeBounds.x + swipeBounds.width / 2;
  const y = swipeBounds.y + swipeBounds.height * 0.75;
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x, y }],
  });
  for (let step = 1; step <= 8; step++) {
    await cdp.send("Input.dispatchTouchEvent", {
      type: "touchMove",
      touchPoints: [{ x, y: y - step * 10 }],
    });
  }
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
  await page.waitForFunction(
    (before) =>
      document.querySelectorAll(".k-picker-time-scroll")[1].scrollTop >
      before + 30,
    swipeBefore,
  );
  assert.equal(
    await swipeColumn.locator('[aria-pressed="true"]').innerText(),
    "30",
    "Swiping does not select a value",
  );
  await cdp.detach();
  console.log(
    "Picker Web: manual formats, invalid dates, UTC/timezone/DST policies, calendar keyboard and month/year selection, hour/minute/period selection, cancel/clear/focus, readonly/disabled passed",
  );
} finally {
  await browser.close();
}
