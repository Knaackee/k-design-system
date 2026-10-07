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
const context = await browser.newContext({
  hasTouch: true,
  isMobile: true,
  viewport: { width: 420, height: 820 },
});
const page = await context.newPage();
const base = process.env.KDS_STORYBOOK_URL || "http://localhost:6006";

const order = () =>
  page
    .locator("[data-agent-id]")
    .evaluateAll((items) => items.map((item) => item.dataset.agentId));

try {
  await page.goto(
    `${base}/iframe.html?id=patterns-agentswitcher--custom-content&viewMode=story&args=reorderable:false`,
  );
  await page.getByRole("button", { name: "Nova, plant, VIP" }).waitFor();
  assert.equal(
    await page.locator(".k-agent-switcher__avatar-custom").count(),
    3,
  );
  assert.equal(await page.getByText("VIP", { exact: true }).count(), 1);
  assert.equal(
    await page
      .locator('[data-agent-id="nova"]')
      .evaluate((item) =>
        item.style.getPropertyValue("--k-agent-selected-color"),
      ),
    "var(--k-color-brand-secondary-accent)",
  );
  const customNova = page.getByRole("button", { name: "Nova, plant, VIP" });
  const customNovaBox = await customNova.boundingBox();
  await page.mouse.move(
    customNovaBox.x + customNovaBox.width / 2,
    customNovaBox.y + customNovaBox.height / 2,
  );
  await page.mouse.down();
  await page.waitForTimeout(520);
  assert.equal(await page.locator("[data-dragging]").count(), 0);
  await page.mouse.up();

  await page.goto(
    `${base}/iframe.html?id=patterns-agentswitcher--custom-content&viewMode=story&args=showConnections:false;showActivity:false;showUnread:false;customColors:false`,
  );
  await page.getByRole("button", { name: "Nova, plant, VIP" }).waitFor();
  assert.equal(await page.locator(".k-agent-switcher__connection").count(), 0);
  assert.equal(
    await page.locator(".k-agent-switcher__activity-label").count(),
    0,
  );
  assert.equal(await page.locator(".k-agent-switcher__unread").count(), 0);

  await page.goto(
    `${base}/iframe.html?id=patterns-agentswitcher--reorder&viewMode=story`,
  );
  const nova = page.getByRole("button", { name: "Nova, plant, VIP" });
  const atlas = page.getByRole("button", { name: /Atlas/ });
  await nova.waitFor();
  const reorderList = page.locator(".k-agent-switcher__list");
  const wheelBehavior = await reorderList.evaluate((element) => {
    element.scrollLeft = 0;
    const vertical = new WheelEvent("wheel", {
      deltaY: 120,
      bubbles: true,
      cancelable: true,
    });
    element.dispatchEvent(vertical);
    const translated = element.scrollLeft;
    element.scrollLeft = element.scrollWidth;
    const boundary = new WheelEvent("wheel", {
      deltaY: 120,
      bubbles: true,
      cancelable: true,
    });
    element.dispatchEvent(boundary);
    const horizontal = new WheelEvent("wheel", {
      deltaX: -40,
      deltaY: 80,
      bubbles: true,
      cancelable: true,
    });
    element.dispatchEvent(horizontal);
    return {
      translated,
      verticalPrevented: vertical.defaultPrevented,
      boundaryPrevented: boundary.defaultPrevented,
      horizontalPrevented: horizontal.defaultPrevented,
    };
  });
  assert.ok(wheelBehavior.translated > 0);
  assert.equal(wheelBehavior.verticalPrevented, true);
  assert.equal(wheelBehavior.boundaryPrevented, false);
  assert.equal(wheelBehavior.horizontalPrevented, false);

  await reorderList.evaluate((element) => {
    element.scrollLeft = 0;
  });
  const sage = page.locator('[data-agent-id="sage"] button');
  const sageBox = await sage.boundingBox();
  await page.mouse.move(
    sageBox.x + sageBox.width / 2,
    sageBox.y + sageBox.height / 2,
  );
  await page.mouse.down();
  await page.mouse.move(sageBox.x - 80, sageBox.y + sageBox.height / 2, {
    steps: 3,
  });
  await page.mouse.up();
  assert.ok(
    (await reorderList.evaluate((element) => element.scrollLeft)) > 0,
    "short mouse drag pans the strip",
  );
  assert.equal(await nova.getAttribute("aria-pressed"), "true");
  assert.deepEqual((await order()).slice(0, 4), [
    "nova",
    "atlas",
    "echo",
    "sage",
  ]);
  const postPanTransforms = await page
    .locator("[data-agent-id]")
    .evaluateAll((items) =>
      items.slice(0, 4).map((item) => ({
        id: item.dataset.agentId,
        transform: getComputedStyle(item).transform,
        translate: getComputedStyle(item).translate,
      })),
    );
  assert.ok(
    postPanTransforms.every(
      ({ transform, translate }) =>
        transform === "none" && (translate === "none" || translate === "0px"),
    ),
    `short pan leaves no sortable transforms: ${JSON.stringify(postPanTransforms)}`,
  );
  await reorderList.evaluate((element) => {
    element.scrollLeft = 0;
  });

  const clickLayout = await page.evaluate(() => {
    const atlasItem = document.querySelector('[data-agent-id="atlas"]');
    const sageItem = document.querySelector('[data-agent-id="sage"]');
    const atlasBounds = atlasItem.getBoundingClientRect();
    const hit = document.elementFromPoint(
      atlasBounds.x + atlasBounds.width / 2,
      atlasBounds.y + atlasBounds.height / 2,
    );
    return {
      atlas: atlasBounds.toJSON(),
      sage: sageItem.getBoundingClientRect().toJSON(),
      hitId: hit?.closest("[data-agent-id]")?.dataset.agentId,
    };
  });
  assert.equal(
    clickLayout.hitId,
    "atlas",
    `short pan restores item hit testing: ${JSON.stringify(clickLayout)}`,
  );

  await atlas.dispatchEvent("click");
  assert.equal(await atlas.getAttribute("aria-pressed"), "true");
  await nova.dispatchEvent("click");
  assert.equal(await nova.getAttribute("aria-pressed"), "true");

  await nova.focus();
  await page.keyboard.press("Alt+ArrowRight");
  assert.deepEqual((await order()).slice(0, 3), ["atlas", "nova", "echo"]);
  assert.equal(await nova.getAttribute("aria-pressed"), "true");

  const source = await atlas.boundingBox();
  const shiftedNeighborBeforeDrag = await nova.boundingBox();
  const target = await page.locator('[data-agent-id="sage"]').boundingBox();
  const dragX = target.x + target.width / 2;
  const dragY = target.y + target.height / 2 + 10;
  await page.mouse.move(
    source.x + source.width / 2,
    source.y + source.height / 2,
  );
  await page.mouse.down();
  await page.waitForTimeout(520);
  assert.equal(
    await page.locator("[data-dragging]").count(),
    1,
    "long press activates sortable drag",
  );
  await page.mouse.move(dragX, dragY, { steps: 6 });
  await page.waitForTimeout(50);
  assert.deepEqual((await order()).slice(0, 4), [
    "nova",
    "echo",
    "sage",
    "atlas",
  ]);
  const activeDuringDrag = await atlas.boundingBox();
  const activeCenter = {
    x: activeDuringDrag.x + activeDuringDrag.width / 2,
    y: activeDuringDrag.y + activeDuringDrag.height / 2,
  };
  const activeTransform = await atlas.locator("..").evaluate((item) => ({
    inline: item.style.transform,
    computed: getComputedStyle(item).transform,
  }));
  assert.ok(
    Math.abs(activeCenter.x - dragX) < 2 &&
      Math.abs(activeCenter.y - dragY) < 2,
    `the active item follows the pointer during the live preview: ${JSON.stringify({ activeCenter, pointer: { x: dragX, y: dragY }, activeTransform })}`,
  );
  assert.ok(
    (await nova.boundingBox()).x < shiftedNeighborBeforeDrag.x,
    "neighboring items shift before pointerup",
  );
  assert.equal(
    await atlas.evaluate((button) => button.hasPointerCapture(1)),
    true,
    "pointer capture survives the active item's DOM reorder",
  );
  assert.equal(await page.locator("[data-drag-over]").count(), 0);
  assert.equal(
    await page
      .locator('[data-agent-id="sage"]')
      .evaluate((item) => getComputedStyle(item).outlineStyle),
    "none",
  );
  await page.mouse.up();
  assert.deepEqual((await order()).slice(0, 4), [
    "nova",
    "echo",
    "sage",
    "atlas",
  ]);
  assert.equal(await nova.getAttribute("aria-pressed"), "true");

  const beforeCancel = await order();
  const pixel = page.locator('[data-agent-id="pixel"] button');
  const pixelBox = await pixel.boundingBox();
  const cancelTarget = page.locator('[data-agent-id="lumen"]');
  const cancelTargetBox = await cancelTarget.boundingBox();
  await page.mouse.move(
    pixelBox.x + pixelBox.width / 2,
    pixelBox.y + pixelBox.height / 2,
  );
  await page.mouse.down();
  await page.waitForTimeout(520);
  await page.mouse.move(
    cancelTargetBox.x + cancelTargetBox.width / 2,
    cancelTargetBox.y + cancelTargetBox.height / 2,
  );
  assert.notDeepEqual(await order(), beforeCancel);
  await pixel.dispatchEvent("pointercancel", {
    pointerId: 1,
    pointerType: "mouse",
  });
  await page.mouse.up();
  assert.deepEqual(await order(), beforeCancel);
  await pixel.click();
  assert.equal(await pixel.getAttribute("aria-pressed"), "true");

  const list = page.locator(".k-agent-switcher__list");
  await list.evaluate((element) => {
    element.scrollLeft = 0;
  });
  const listBox = await list.boundingBox();
  const session = await context.newCDPSession(page);
  await session.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ x: listBox.x + 300, y: listBox.y + 40 }],
  });
  await session.send("Input.dispatchTouchEvent", {
    type: "touchMove",
    touchPoints: [{ x: listBox.x + 100, y: listBox.y + 40 }],
  });
  await session.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
  await page.waitForTimeout(100);
  assert.ok(
    (await list.evaluate((element) => element.scrollLeft)) > 0,
    "touch pan scrolls before long-press activation",
  );
  assert.deepEqual(await order(), beforeCancel);

  await page.goto(
    `${base}/iframe.html?id=patterns-agentswitcher--reorder&viewMode=story`,
  );
  const edgeList = page.locator(".k-agent-switcher__list");
  const edgeListBox = await edgeList.boundingBox();
  const edgeNova = page.getByRole("button", { name: "Nova, plant, VIP" });
  const edgeNovaBox = await edgeNova.boundingBox();
  await page.mouse.move(
    edgeNovaBox.x + edgeNovaBox.width / 2,
    edgeNovaBox.y + edgeNovaBox.height / 2,
  );
  await page.mouse.down();
  await page.waitForTimeout(520);
  await page.mouse.move(
    edgeListBox.x + edgeListBox.width - 4,
    edgeNovaBox.y + 20,
  );
  await page.waitForTimeout(700);
  await page.mouse.up();
  assert.ok(
    (await edgeList.evaluate((element) => element.scrollLeft)) > 0,
    "active edge drag scrolls the long strip",
  );
  assert.ok(
    (await order()).indexOf("nova") > 2,
    "edge drag reaches later items",
  );

  await page.goto(
    `${base}/iframe.html?id=patterns-agentswitcher--reorder&viewMode=story`,
  );
  const touchNovaBox = await page
    .getByRole("button", { name: "Nova, plant, VIP" })
    .boundingBox();
  const touchSageBox = await page
    .locator('[data-agent-id="sage"]')
    .boundingBox();
  await session.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [
      {
        x: touchNovaBox.x + touchNovaBox.width / 2,
        y: touchNovaBox.y + touchNovaBox.height / 2,
      },
    ],
  });
  await page.waitForTimeout(520);
  await session.send("Input.dispatchTouchEvent", {
    type: "touchMove",
    touchPoints: [
      {
        x: touchSageBox.x + touchSageBox.width / 2,
        y: touchSageBox.y + touchSageBox.height / 2,
      },
    ],
  });
  await session.send("Input.dispatchTouchEvent", {
    type: "touchEnd",
    touchPoints: [],
  });
  assert.deepEqual((await order()).slice(0, 4), [
    "atlas",
    "echo",
    "sage",
    "nova",
  ]);

  console.log(
    "Agent switcher browser: optional content, standalone long-press, wheel and mouse pan, click, keyboard reorder, live delayed mouse/touch drag, cancellation, selection suppression, touch pan, and edge scrolling passed",
  );
} finally {
  await browser.close();
}
