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
const base = process.env.KDS_STORYBOOK_URL || "http://localhost:6006";

try {
  const desktop = await browser.newPage({
    viewport: { width: 1100, height: 820 },
  });
  await desktop.goto(
    `${base}/iframe.html?id=patterns-agentchatworkspace--fullscreen&viewMode=story`,
  );
  await desktop.getByRole("heading", { name: "Ada", exact: true }).waitFor();
  const sidebar = desktop.locator(".k-agent-chat-workspace__sidebar");
  assert.equal(Math.round((await sidebar.boundingBox()).width), 280);
  assert.equal(
    await desktop
      .getByRole("button", { name: "Agenten", exact: true })
      .isVisible(),
    false,
  );
  const desktopAgents = sidebar.locator("[data-agent-id]");
  const firstAgent = desktopAgents.locator("button").first();
  await firstAgent.focus();
  await desktop.keyboard.press("Alt+ArrowDown");
  assert.deepEqual(
    await desktopAgents.evaluateAll((items) =>
      items.slice(0, 2).map((item) => item.dataset.agentId),
    ),
    ["linus", "ada"],
  );

  const mobile = await browser.newPage({
    viewport: { width: 420, height: 820 },
  });
  await mobile.goto(
    `${base}/iframe.html?id=patterns-agentchatworkspace--mobile&viewMode=story`,
  );
  await mobile.getByRole("heading", { name: "Ada", exact: true }).waitFor();
  const trigger = mobile.locator(
    "button.k-agent-chat-workspace__agents-trigger",
  );
  assert.equal(await trigger.isVisible(), true);
  assert.equal(
    await mobile.locator(".k-agent-chat-workspace__sidebar").isVisible(),
    false,
  );
  assert.equal(
    Math.round(
      (await mobile.locator(".k-agent-chat-workspace__avatar").boundingBox())
        .width,
    ),
    112,
  );
  assert.deepEqual(
    await mobile.evaluate(() => ({
      width: document.documentElement.scrollWidth,
      viewport: window.innerWidth,
      height: document.documentElement.scrollHeight,
      viewportHeight: window.innerHeight,
    })),
    { width: 420, viewport: 420, height: 820, viewportHeight: 820 },
  );
  await trigger.click();
  const dialog = mobile.getByRole("dialog", { name: "Agenten" });
  await dialog.waitFor();
  assert.ok((await dialog.boundingBox()).width <= 280);
  assert.equal(await trigger.getAttribute("aria-expanded"), "true");
  assert.equal(await dialog.locator(":focus").count(), 1);
  await mobile.keyboard.press("Escape");
  await dialog.waitFor({ state: "hidden" });
  assert.equal(await trigger.getAttribute("aria-expanded"), "false");
  assert.equal(
    await trigger.evaluate((element) => element === document.activeElement),
    true,
  );

  await trigger.click();
  await mobile
    .getByRole("dialog", { name: "Agenten" })
    .getByRole("button", { name: "Linus, Arbeitet" })
    .click();
  await mobile
    .getByRole("dialog", { name: "Agenten" })
    .waitFor({ state: "hidden" });
  await mobile.getByRole("heading", { name: "Linus", exact: true }).waitFor();

  await mobile.goto(
    `${base}/iframe.html?id=patterns-agentchatworkspace--needs-input&viewMode=story`,
  );
  await mobile.getByRole("heading", { name: "Mira", exact: true }).waitFor();
  assert.match(
    await mobile.getByRole("status").textContent(),
    /Benötigt Eingabe/,
  );

  await mobile.goto(
    `${base}/iframe.html?id=patterns-agentchatworkspace--offline&viewMode=story`,
  );
  await mobile
    .getByRole("heading", { name: "Lokaler Pi", exact: true })
    .waitFor();
  assert.match(await mobile.getByRole("status").textContent(), /Offline/);
  assert.equal(await mobile.getByRole("textbox").isDisabled(), true);

  console.log(
    "Agent chat workspace browser: desktop shell, vertical keyboard reorder, mobile drawer focus/Escape, hero sizing, needs-input, and offline states passed",
  );
} finally {
  await browser.close();
}
