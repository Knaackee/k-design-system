import assert from "node:assert/strict";
import { mkdir } from "node:fs/promises";
import { resolve } from "node:path";
import { chromium } from "@playwright/test";

const output = resolve(
  process.env.KDS_SCREENSHOT_DIRECTORY ?? "../../artifacts/ui",
);
await mkdir(output, { recursive: true });
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
const errors = [];
page.on("pageerror", (error) => errors.push(error.message));
const origin = process.env.KDS_STORYBOOK_URL ?? "http://127.0.0.1:6006";
async function open(
  state,
  globals = "theme:light;density:standard;inputMode:pointer;textScale:1",
) {
  await page.goto(
    `${origin}/iframe.html?id=patterns-paymentsetup--${state}&viewMode=story&globals=${globals}`,
  );
  await page.locator(".k-payment-setup").waitFor();
  await page.evaluate(() => document.fonts.ready);
}
async function screenshot(name) {
  assert.equal(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
    true,
    `${name}: horizontal overflow`,
  );
  await page.screenshot({
    path: resolve(output, `${name}.png`),
    fullPage: true,
    animations: "disabled",
  });
}
try {
  await page.setViewportSize({ width: 1280, height: 900 });
  await open("needs-correction");
  await screenshot("payment-setup-correction-desktop");
  const help = page.getByRole("button", {
    name: "Testmodus: So funktioniert die Prüfung",
  });
  assert.equal(await help.getAttribute("aria-expanded"), "false");
  await help.focus();
  await page.keyboard.press("Enter");
  assert.equal(await help.getAttribute("aria-expanded"), "true");
  assert.equal(
    await page
      .getByRole("link", { name: "Offizielle Stripe-Testdaten ansehen" })
      .isVisible(),
    true,
  );
  await screenshot("payment-setup-help-desktop");

  await page.setViewportSize({ width: 390, height: 900 });
  await open(
    "needs-correction",
    "theme:light;density:standard;inputMode:touch;textScale:1",
  );
  await screenshot("payment-setup-correction-mobile");
  await page
    .getByRole("button", { name: "Angaben prüfen", exact: true })
    .click();
  await page
    .getByRole("heading", { name: "Deine Angaben werden geprüft" })
    .waitFor();
  assert.equal(
    await page
      .getByRole("button", { name: "Angaben prüfen", exact: true })
      .count(),
    0,
  );
  await page.getByRole("button", { name: "Status aktualisieren" }).click();
  await page
    .getByRole("heading", { name: "Dein Zahlungskonto ist bereit" })
    .waitFor();
  await screenshot("payment-setup-ready-mobile");

  await open("pending", "theme:dark;density:dense;inputMode:touch;textScale:1");
  await screenshot("payment-setup-pending-dark-mobile");
  await open(
    "long-content",
    "theme:light;density:spacious;inputMode:touch;textScale:2",
  );
  await screenshot("payment-setup-large-text-mobile");
  await page.emulateMedia({ reducedMotion: "reduce" });
  assert.equal(
    await page
      .locator(".k-payment-setup__status")
      .evaluate((element) => getComputedStyle(element).animationName),
    "none",
  );
  for (const state of [
    "connected",
    "action-required",
    "pending",
    "needs-correction",
    "ready",
  ]) {
    await open(state);
    assert.equal(await page.locator(".k-payment-setup__steps > li").count(), 3);
  }
  assert.deepEqual(errors, []);
  console.log(
    "Payment setup: five states, keyboard help, pending/ready interaction, mobile/dark/large text and reduced motion passed.",
  );
  console.log(`Screenshots: ${output}`);
} finally {
  await browser.close();
}
