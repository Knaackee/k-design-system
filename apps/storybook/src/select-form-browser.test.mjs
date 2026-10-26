import assert from "node:assert/strict";
import { createRequire } from "node:module";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
const browser = await chromium.launch({ channel: "msedge", headless: true });
try {
  const page = await browser.newPage();
  await page.goto(
    "http://localhost:6006/iframe.html?id=actions-iconbutton--actions&viewMode=story",
  );
  await page.locator(".k-icon-button").first().waitFor();
  const iconFits = await page
    .locator(".k-icon-button")
    .first()
    .evaluate((button) => {
      const content = button.querySelector(".k-truncated__content");
      const icon = button.querySelector(".k-icon");
      return (
        content.getBoundingClientRect().width >=
        icon.getBoundingClientRect().width
      );
    });
  assert.ok(iconFits, "Icon button must not clip its icon");
  await page.goto(
    "http://localhost:6006/iframe.html?id=forms-select-form-contract--native-form&viewMode=story",
  );
  const country = page.getByRole("combobox", { name: "Country" });
  await country.waitFor();
  await country.click();
  assert.equal(await country.getAttribute("aria-expanded"), "true");
  await country.click();
  assert.equal(await country.getAttribute("aria-expanded"), "false");
  await page.getByRole("button", { name: "Submit", exact: true }).click();
  assert.equal(
    await page.getByLabel("Submitted", { exact: true }).textContent(),
    "",
  );
  assert.equal(await country.getAttribute("aria-invalid"), "true");
  assert.ok(
    await country.evaluate((element) => document.activeElement === element),
  );
  await country.click();
  await page.getByRole("option", { name: "France", exact: true }).click();
  assert.equal(await country.getAttribute("aria-expanded"), "false");
  assert.equal(
    await page.getByLabel("Changes", { exact: true }).textContent(),
    "1",
  );
  const controlled = page.getByRole("combobox", {
    name: "Controlled",
    exact: true,
  });
  await controlled.click();
  await page.getByRole("option", { name: "France", exact: true }).click();
  assert.equal(await controlled.getAttribute("aria-expanded"), "false");
  const wrapped = page.getByRole("combobox", { name: "Wrapped", exact: true });
  await wrapped.click();
  await page.getByRole("option", { name: "France", exact: true }).click();
  assert.equal(await wrapped.getAttribute("aria-expanded"), "false");
  await page.getByRole("button", { name: "Submit", exact: true }).click();
  assert.deepEqual(
    JSON.parse(
      await page.getByLabel("Submitted", { exact: true }).textContent(),
    ),
    { country: "fr", controlled: "fr", search: "fr" },
  );
  await page.getByRole("button", { name: "Reset", exact: true }).click();
  await page.waitForFunction(
    () => document.querySelector('select[name="controlled"]').value === "de",
  );
  assert.equal(await country.inputValue(), "Choose");
  assert.equal(await controlled.inputValue(), "Germany");
  assert.equal(await page.locator('select[name="country"]').inputValue(), "");
  assert.equal(
    await page.getByLabel("Changes", { exact: true }).textContent(),
    "3",
  );
  await page.goto(
    "http://localhost:6006/iframe.html?id=forms-select--multiple&viewMode=story",
  );
  const multiple = page.getByRole("combobox").first();
  await multiple.waitFor();
  await multiple.click();
  const firstOption = page.getByRole("option").first();
  await firstOption.click();
  assert.equal(await multiple.getAttribute("aria-expanded"), "true");
  console.log(
    "PASS select: native validation, focus, submission, change bubbling, controlled/uncontrolled reset, disabled omission",
  );
} finally {
  await browser.close();
}
