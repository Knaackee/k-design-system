import assert from "node:assert/strict";
import { createRequire } from "node:module";
const { chromium } = createRequire(import.meta.url)(
  process.env.KDS_PLAYWRIGHT_MODULE || "playwright",
);
const browser = await chromium.launch({ channel: "msedge", headless: true });
try {
  const page = await browser.newPage({
    viewport: { width: 1280, height: 900 },
  });
  await page.goto(
    "http://localhost:6006/iframe.html?id=showcase-dashboard-app-shell--dashboard&viewMode=story",
  );
  const main = page.locator(".dashboard-shell__main");
  const before = await main.boundingBox();
  const expand = page.getByRole("button", { name: "Expand sidebar" });
  assert.equal(await expand.count(), 1);
  await expand.press("Enter");
  await page.waitForFunction(
    () =>
      document.querySelector(".dashboard-shell__main").getBoundingClientRect()
        .left === 248,
  );
  assert.equal(
    (await main.boundingBox()).x,
    before.x + 192,
    "Left sidebar reserves its expanded width",
  );
  await page.getByRole("button", { name: "Projects", exact: true }).click();
  assert.ok(
    await page.getByRole("button", { name: "Collapse sidebar" }).isVisible(),
    "Navigation keeps the expanded sidebar open",
  );
  await page.getByRole("button", { name: "Collapse sidebar" }).click();
  await page
    .getByRole("button", { name: "Website refresh", exact: true })
    .click();
  const detailBounds = await main.boundingBox();
  await page
    .getByRole("button", { name: "Project details", exact: true })
    .click();
  await page.getByRole("textbox", { name: "Notes" }).fill("Retained note");
  assert.deepEqual(
    await main.boundingBox(),
    detailBounds,
    "Right overlay must not move content",
  );
  for (const width of [768, 375, 1280]) {
    await page.setViewportSize({ width, height: 900 });
    await page.waitForFunction(
      () => document.querySelectorAll('[role="dialog"]').length === 1,
    );
    assert.equal(
      await page.getByRole("textbox", { name: "Notes" }).inputValue(),
      "Retained note",
    );
    assert.equal(await page.getByRole("textbox", { name: "Notes" }).count(), 1);
  }
  await page.waitForFunction(
    () =>
      document.activeElement?.getAttribute("aria-label") === "Close details",
  );
  await page.getByRole("button", { name: "Close details" }).click();
  await page.getByRole("button", { name: "Settings", exact: true }).click();
  await page.getByRole("button", { name: "Save changes" }).click();
  assert.match(await page.getByRole("status").innerText(), /saved locally/);
  await page.getByRole("searchbox").fill("security");
  assert.equal(
    await page.getByRole("button", { name: "Profile", exact: true }).count(),
    0,
  );
  await page.getByRole("button", { name: "Back to app" }).click();
  assert.ok(
    await page
      .getByRole("heading", { name: "Website refresh", exact: true })
      .isVisible(),
  );
  await page.setViewportSize({ width: 375, height: 900 });
  await page.getByRole("button", { name: "Open navigation" }).click();
  const drawer = page.locator(".dashboard-shell__navigation-drawer");
  assert.equal(
    await drawer.getByRole("heading", { name: "Orbit", exact: true }).count(),
    1,
  );
  assert.equal(await drawer.locator(".k-sidebar__header").count(), 0);
  const drawerBounds = await drawer.boundingBox();
  const sidebarBounds = await drawer
    .locator(".dashboard-shell__sidebar")
    .boundingBox();
  assert.equal(drawerBounds.width, 248);
  const settingsBounds = await drawer
    .getByRole("button", { name: "Settings", exact: true })
    .boundingBox();
  assert.ok(
    drawerBounds.y +
      drawerBounds.height -
      settingsBounds.y -
      settingsBounds.height <=
      12,
    "Settings button stays at the viewport bottom without a sidebar header",
  );
  assert.equal(
    await drawer.getByRole("button", { name: "Close navigation" }).isVisible(),
    true,
  );
  assert.ok(
    drawerBounds.y <= 1,
    "Navigation starts at the top, not at the bottom",
  );
  assert.ok(
    Math.abs(drawerBounds.height - 900) <= 2,
    "Navigation is full height",
  );
  assert.ok(
    drawerBounds.width < 375,
    "Navigation leaves a dismissible backdrop",
  );
  assert.ok(Math.abs(sidebarBounds.width - drawerBounds.width) <= 2);
  assert.ok(
    Math.abs(
      sidebarBounds.y +
        sidebarBounds.height -
        drawerBounds.y -
        drawerBounds.height,
    ) <= 1,
  );
  await page.getByRole("button", { name: "Projects", exact: true }).click();
  assert.equal(
    await page.getByRole("dialog", { name: "Orbit", exact: true }).count(),
    0,
  );
  await page.getByRole("button", { name: "Open navigation" }).click();
  await page.getByRole("button", { name: "Settings", exact: true }).click();
  assert.equal(
    await page.getByRole("dialog", { name: "Orbit", exact: true }).count(),
    0,
  );
  assert.ok(
    await page.getByRole("button", { name: "Back to app" }).isVisible(),
  );
  await page.getByRole("button", { name: "Back to app" }).click();
  await page.getByRole("button", { name: "Appearance: System" }).click();
  await page.getByRole("button", { name: "Appearance: Light" }).click();
  assert.equal(
    await page.locator(".dashboard-shell").getAttribute("data-theme"),
    "dark",
  );
  await page.getByRole("button", { name: "Open navigation" }).click();
  assert.equal(await page.locator("html").getAttribute("data-theme"), "dark");
  console.log(
    "PASS: sidebar, inspector resize/state/focus, settings search/save/return",
  );
} finally {
  await browser.close();
}
