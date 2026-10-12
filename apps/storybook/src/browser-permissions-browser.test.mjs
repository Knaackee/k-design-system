import assert from "node:assert/strict";
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const browser = await chromium.launch({
  channel:
    process.env.KDS_BROWSER_CHANNEL ||
    (process.platform === "win32" ? "msedge" : undefined),
  headless: true,
});
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
const base = process.env.KDS_STORYBOOK_URL || "http://localhost:6006";
const open = (story) =>
  page.goto(
    `${base}/iframe.html?id=patterns-browserpermissions--${story}&viewMode=story`,
  );
try {
  const openAsk = (story) =>
    page.goto(
      `${base}/iframe.html?id=patterns-agentui-browserpermissionask--${story}&viewMode=story`,
    );
  await openAsk("request");
  await page.getByRole("radio", { name: /^Immer fragen/ }).check();
  await page.getByRole("button", { name: "Entscheidung senden" }).click();
  await page
    .getByRole("status")
    .filter({ hasText: "Diese Aktion wartet weiterhin" })
    .waitFor();
  assert.equal(await page.getByRole("radio").count(), 5);
  await page.getByRole("radio", { name: /^Einmal erlauben/ }).check();
  await page.getByRole("button", { name: "Entscheidung senden" }).click();
  await page.getByText("Einmal erlauben", { exact: true }).waitFor();
  assert.equal(await page.getByRole("radio").count(), 0);
  await openAsk("once-only");
  await page.getByRole("radio").first().waitFor();
  assert.equal(
    await page.getByRole("radio", { name: /^Erlauben und merken/ }).count(),
    0,
  );
  await openAsk("manual");
  await page.getByRole("radio", { name: /^Browser übernehmen/ }).waitFor();
  assert.equal(await page.getByRole("radio").count(), 2);
  assert.equal(
    await page.getByRole("radio", { name: /^Einmal erlauben/ }).count(),
    0,
  );
  await openAsk("submitted");
  await page.getByText("Einmal erlauben", { exact: true }).waitFor();
  assert.equal(await page.getByRole("radio").count(), 0);
  await open("rule-management");
  const google = page.locator('[data-rule-id="google-search"]');
  await google.getByRole("combobox").click();
  await page.getByRole("option", { name: "Blockieren", exact: true }).click();
  assert.equal(await google.getByRole("combobox").inputValue(), "Blockieren");
  await google
    .getByRole("button", { name: "Basisregel wiederherstellen" })
    .click();
  assert.equal(await google.getByRole("combobox").inputValue(), "Erlaubt");
  const custom = page.locator('[data-rule-id="hotel-filter"]');
  await custom.getByRole("button", { name: "Widerrufen" }).click();
  assert.equal(await custom.getByRole("combobox").isDisabled(), true);
  await open("empty");
  await page
    .getByText("Noch keine Browserberechtigungen", { exact: true })
    .waitFor();
  assert.equal(await page.getByRole("combobox").count(), 0);
  await open("mobile-rules");
  await page.getByRole("combobox").first().waitFor();
  assert.equal(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    ),
    true,
  );
  console.log(
    "Browser permissions: Ask pending/submitted, manual/once-only boundaries, rule edit/reset/revoke, empty and mobile management passed.",
  );
} finally {
  await browser.close();
}
