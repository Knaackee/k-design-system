import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { readFile, readdir } from "node:fs/promises";
const require = createRequire(import.meta.url);
const React = require("react"),
  { renderToStaticMarkup } = require("react-dom/server");
const {
  KLocalizationProvider,
  KSelect,
  KInput,
  KFilterChip,
  KFilterBar,
  KDateTimePicker,
} = await import("../../../packages/web/ui/dist/index.js");
const h = React.createElement;
const markup = renderToStaticMarkup(
  h(
    KLocalizationProvider,
    {
      locale: "de",
      messages: { clear: "Entfernen" },
      dateFormat: "dayMonthYear",
      timeZone: "Europe/Berlin",
    },
    h(
      React.Fragment,
      null,
      h(KInput, { value: "abc", clearable: true, onClear() {} }),
      h(KSelect, { value: null, options: [], onValueChange() {} }),
      h(KFilterChip, { label: "Status", onRemove() {} }),
      h(KFilterBar, { label: "Filters", onReset() {} }),
      h(KDateTimePicker, {
        value: "2026-09-16T12:30:00.000Z",
        onValueChange() {},
      }),
      h(
        KLocalizationProvider,
        { locale: "fr" },
        h(KInput, {
          value: "abc",
          clearable: true,
          onClear() {},
          clearLabel: "Custom clear",
        }),
      ),
    ),
  ),
);
for (const text of [
  "Entfernen",
  "Auswählen…",
  "Status entfernen",
  "Alle zurücksetzen",
  "16.09.2026 14:30",
  "Custom clear",
])
  assert.ok(markup.includes(text), text);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const browser = await chromium.launch({ channel: "msedge", headless: true });
const page = await browser.newPage({ viewport: { width: 1024, height: 900 } });
try {
  for (const name of (
    await readdir(new URL("../../../locales/", import.meta.url))
  ).filter((n) => n.endsWith(".json"))) {
    const code = name.slice(0, -5),
      pack = JSON.parse(
        await readFile(
          new URL(`../../../locales/${name}`, import.meta.url),
          "utf8",
        ),
      );
    await page.goto(
      "http://localhost:6006/iframe.html?" +
        new URLSearchParams({
          id: "forms-datetimepicker--states",
          viewMode: "story",
          globals: `language:${code}`,
        }),
    );
    await page.getByText("Schedule", { exact: true }).waitFor();
    await page
      .getByRole("button", { name: pack.messages.chooseDateTime, exact: true })
      .first()
      .click();
    const dialog = page.getByRole("dialog");
    await dialog
      .getByRole("group", { name: pack.messages.hours, exact: true })
      .waitFor();
    await dialog
      .getByRole("group", { name: pack.messages.minutes, exact: true })
      .waitFor();
    await dialog
      .getByRole("button", {
        name: `${pack.messages.month}: ${pack.months[8]}`,
        exact: true,
      })
      .waitFor();
    await dialog
      .getByRole("button", { name: pack.messages.apply, exact: true })
      .click();
    assert.equal(
      await page.getByRole("status").innerText(),
      "Value: 2026-09-16T12:30:00.000Z",
    );
    console.log(
      `${code}: translated dialog/calendar; canonical value unchanged`,
    );
  }
  await page.goto(
    "http://localhost:6006/iframe.html?" +
      new URLSearchParams({
        id: "forms-datetimepicker--states",
        viewMode: "story",
        globals: "language:fr",
        args: "locale:de",
      }),
  );
  await page
    .getByRole("button", { name: "Datum und Uhrzeit wählen", exact: true })
    .first()
    .click();
  await page.getByRole("group", { name: "Stunden", exact: true }).waitFor();
  console.log(
    "Component language overrides global language; provider/form overrides passed",
  );
} finally {
  await browser.close();
}
