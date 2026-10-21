import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import { createServer } from "vite";

const require = createRequire(import.meta.url);
const { chromium } = require(process.env.KDS_PLAYWRIGHT_MODULE || "playwright");
const root = fileURLToPath(new URL("..", import.meta.url));
const toolbarModule = `/@fs/${fileURLToPath(new URL("../../../packages/web/ui/dist/editors/map-zone-editor-toolbar.js", import.meta.url)).replaceAll("\\", "/")}`;
const labelsModule = `/@fs/${fileURLToPath(new URL("../../../packages/web/ui/dist/editors/map-zone-editor-labels.js", import.meta.url)).replaceAll("\\", "/")}`;
const fixtureId = "virtual:zone-editor-click-regression";
const fixtureSource = `
  import React, { useState } from "react";
  import { createRoot } from "react-dom/client";
  import { ZoneEditorToolbar } from "${toolbarModule}";
  import { kDefaultMapZoneEditorLabels } from "${labelsModule}";
  import { KButton } from "@k-design-system/ui/primitives/button";
  import { KSnackbar, KToastViewport } from "@k-design-system/ui/feedback/notifications";
  import { KMapZoneEditor } from "@k-design-system/ui/editors/map-zone-editor";
  import { setWorkerUrl } from "maplibre-gl";
  import workerUrl from "maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url";
  setWorkerUrl(workerUrl);
  import { validateMapZone } from "@k-design-system/ui/maps/map-zone-geometry";
  import "@k-design-system/tokens/tokens.css";
  import "maplibre-gl/dist/maplibre-gl.css";
  import "@k-design-system/ui/styles.css";
  import "@k-design-system/ui/maps.css";
  import "@k-design-system/ui/map-zone-editor.css";
  window.zoneFixture = { changes: [], pending: [], errors: [], undoEvents: [] };
  const reportUndo = action => { window.zoneFixture.undoEvents.push(!!action); window.undoAction = action; if (action) window.oldUndoAction = action; };
  const reportPending = pending => window.zoneFixture.pending.push(pending);
  function Fixture() {
    const [zones, setZones] = useState([]);
    const [selected, setSelected] = useState(null);
    const [inset, setInset] = useState(0);
    window.setEditorInset = setInset;
    window.externalZones = setZones;
    window.externalSelect = setSelected;
    return React.createElement(KMapZoneEditor, {
      zones, selectedZoneId: selected, onSelect: setSelected, bottomOverlayInset: inset,
      mapProps: { mapStyle: { version: 8, sources: {}, layers: [] }, center: [13.4, 52.5], zoom: 10 },
      onChange: next => {
        window.zoneFixture.changes.push(next.map(zone => ({
          id: zone.id, name: zone.name, kind: zone.kind, circle: zone.circle,
          coordinates: zone.coordinates, validation: validateMapZone(zone),
        })));
        setZones(next);
      },
      onPendingChangesChanged: reportPending,
      onUndoActionChange: reportUndo,
      onValidationError: error => window.zoneFixture.errors.push(error),
    });
  }
  function ToolbarFixture() {
    const [dirty, setDirty] = useState(true);
    window.setToolbarDirty = setDirty;
    window.toolbarActions = [];
    const labels = { ...kDefaultMapZoneEditorLabels,
      ...(location.search.includes("long") ? { acceptChanges: "Änderungen für dieses Gebiet übernehmen" } : {}) };
    return React.createElement(ZoneEditorToolbar, {
      zones: [{ id: "one", name: "Zone", coordinates: [] }], selectedZoneId: "draft", draft: { id: "draft", name: "Zone", coordinates: [] },
      open: false, dirty, canUndo: true, disabled: false, canFinish: true,
      labels, panelTitle: "Zonen", panel: null,
      onOpenChange() {}, onAdd() {}, onProperties() {},
      onUndo: () => window.toolbarActions.push("undo"),
      onDiscard: () => window.toolbarActions.push("discard"),
      onFinish: () => window.toolbarActions.push("apply"),
    });
  }
  function NotificationFixture() {
    const [visible, setVisible] = useState(true);
    window.setNotificationVisible = setVisible;
    window.notificationHeights ??= [];
    return React.createElement(KToastViewport, { position: "bottom-center", onHeightChange: height => window.notificationHeights.push(height) },
      visible ? React.createElement(KSnackbar, { message: "Applied", onDismiss: () => setVisible(false),
        action: React.createElement(KButton, { onClick: () => window.notificationUndo = true }, "Undo") }) : null);
  }
  createRoot(document.getElementById("root")).render(React.createElement(location.search.includes("notification") ? NotificationFixture : location.search.includes("toolbar") ? ToolbarFixture : Fixture));
`;
const server = await createServer({
  root,
  configFile: false,
  server: { host: "127.0.0.1", port: 0, hmr: false },
  plugins: [
    {
      name: "zone-editor-browser-regression-fixture",
      resolveId(id) {
        if (id === fixtureId) return `\0${fixtureId}`;
      },
      load(id) {
        if (id === `\0${fixtureId}`) return fixtureSource;
      },
      configureServer(vite) {
        vite.middlewares.use((request, response, next) => {
          if (request.url.split("?")[0] !== "/") return next();
          response.setHeader("Content-Type", "text/html");
          response.end(
            `<!doctype html><html lang="de" data-brand="orbit" data-theme="light" data-density="standard"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><link rel="icon" href="data:,"></head><body style="margin:0"><div id="root" class="k-map-zone-editor-container" style="height:700px;position:relative"></div><script type="module" src="/@id/${fixtureId}"></script></body></html>`,
          );
        });
      },
    },
  ],
});
let browser;
try {
  await server.listen();
  const address = server.httpServer.address();
  assert.ok(address && typeof address === "object");
  browser = await chromium.launch({
    channel:
      process.env.KDS_BROWSER_CHANNEL ||
      (process.platform === "win32" ? "msedge" : undefined),
    headless: true,
  });
  const page = await browser.newPage({
    viewport: { width: 1100, height: 800 },
  });
  page.on("pageerror", (error) =>
    console.error("Fixture page error:", error.message),
  );
  page.on("console", (message) => {
    if (message.type() === "error")
      console.error("Fixture console:", message.text());
  });
  await page.goto(`http://127.0.0.1:${address.port}`);
  await page.waitForFunction(() => !!window.zoneFixture);
  await page.getByRole("button", { name: "Umkreis", exact: true }).click();
  await page.waitForFunction(() => window.zoneFixture.pending.includes(true));
  await page.getByRole("button", { name: "Übernehmen", exact: true }).click();
  await page.waitForFunction(
    () =>
      window.zoneFixture.changes.length === 1 &&
      window.zoneFixture.pending.at(-1) === false,
  );
  const result = await page.evaluate(() => window.zoneFixture);
  assert.equal(result.changes.length, 1);
  assert.equal(result.changes[0].length, 1);
  const created = result.changes[0][0];
  assert.equal(typeof created.id, "string");
  assert.ok(created.name.trim().length > 0);
  assert.equal(created.kind, "circle");
  assert.equal(created.circle.radiusKm, 3);
  assert.deepEqual(created.circle.center, [13.4, 52.5]);
  assert.ok(created.coordinates.length >= 12);
  assert.equal(created.validation, null);
  assert.deepEqual(result.errors, []);
  assert.equal(result.pending[0], false);
  assert.ok(result.pending.includes(true));
  assert.equal(result.pending.at(-1), false);
  await page.waitForFunction(() => !!window.undoAction);
  await page
    .locator(".k-map-zone-editor__toolbar")
    .evaluate((element) =>
      Promise.all(
        element
          .getAnimations()
          .map((animation) => animation.finished.catch(() => {})),
      ),
    );
  const originalToolbarY = (
    await page.locator(".k-map-zone-editor__toolbar").boundingBox()
  ).y;
  await page.evaluate(() => window.setEditorInset(96));
  await page.waitForFunction(
    (y) =>
      Math.abs(
        document
          .querySelector(".k-map-zone-editor__toolbar")
          .getBoundingClientRect().y -
          (y - 96),
      ) < 1,
    originalToolbarY,
  );
  await page.evaluate(() => window.setEditorInset(0));
  await page.waitForFunction(
    (y) =>
      Math.abs(
        document
          .querySelector(".k-map-zone-editor__toolbar")
          .getBoundingClientRect().y - y,
      ) < 1,
    originalToolbarY,
  );

  assert.equal(
    await page.locator(".k-map-zone-editor__map .k-toast-viewport").count(),
    0,
  );
  await page.evaluate(() => window.undoAction.undo());
  await page.waitForFunction(
    () => window.zoneFixture.changes.length === 2 && !window.undoAction,
  );
  assert.deepEqual(
    await page.evaluate(() => window.zoneFixture.changes[1]),
    [],
  );
  await page.evaluate(() => window.oldUndoAction.undo());
  assert.equal(await page.evaluate(() => window.zoneFixture.changes.length), 2);
  await page.getByRole("button", { name: "Umkreis", exact: true }).click();
  await page.getByRole("button", { name: "Übernehmen", exact: true }).click();
  await page.waitForFunction(() => !!window.undoAction);
  await page.evaluate(() =>
    window.externalZones(
      window.zoneFixture.changes
        .at(-1)
        .map((zone) => ({ ...zone, name: "External update" })),
    ),
  );
  await page.waitForFunction(() => !window.undoAction);
  await page.evaluate(() => window.oldUndoAction.undo());
  assert.equal(
    await page.evaluate(() => window.zoneFixture.changes.length),
    3,
    "stale undo overwrote external document",
  );
  await page.goto(`http://127.0.0.1:${address.port}`);
  await page.waitForFunction(
    () => !!window.externalZones && !!window.externalSelect,
  );
  await page.evaluate(() => {
    window.externalZones([
      {
        id: "touch",
        name: "Touch",
        kind: "polygon",
        color: "#155dfc",
        coordinates: [
          [13.38, 52.49],
          [13.42, 52.49],
          [13.42, 52.53],
          [13.38, 52.53],
        ],
      },
    ]);
    window.externalSelect("touch");
  });
  const moveHandle = page.getByRole("button", {
    name: "Zone verschieben",
    exact: true,
  });
  await moveHandle.waitFor();
  await moveHandle.evaluate((button) => {
    const box = button.getBoundingClientRect();
    const event = (type, id, x, primary) =>
      new PointerEvent(type, {
        bubbles: true,
        pointerId: id,
        pointerType: "touch",
        isPrimary: primary,
        button: 0,
        clientX: x,
        clientY: box.y + box.height / 2,
      });
    button.dispatchEvent(event("pointerdown", 41, box.x + box.width / 2, true));
    button.dispatchEvent(
      event("pointermove", 41, box.x + box.width / 2 + 30, true),
    );
  });
  await page.waitForFunction(
    () =>
      document.querySelector('[aria-label="Zone verschieben"]')?.dataset
        .dragging === "true",
  );
  await page.evaluate(() =>
    window.dispatchEvent(
      new PointerEvent("pointerdown", {
        bubbles: true,
        pointerId: 42,
        pointerType: "touch",
        isPrimary: false,
        button: 0,
      }),
    ),
  );
  await page.waitForFunction(
    () =>
      document.querySelector('[aria-label="Zone verschieben"]')?.dataset
        .dragging === "false",
  );
  const midpoint = page
    .getByRole("button", { name: /Punkt danach.*1/ })
    .first();
  await midpoint.evaluate((button) => {
    const box = button.getBoundingClientRect();
    button.dispatchEvent(
      new PointerEvent("pointerdown", {
        bubbles: true,
        pointerId: 51,
        pointerType: "touch",
        isPrimary: true,
        button: 0,
        clientX: box.x + box.width / 2,
        clientY: box.y + box.height / 2,
      }),
    );
    window.dispatchEvent(
      new PointerEvent("pointerdown", {
        bubbles: true,
        pointerId: 52,
        pointerType: "touch",
        isPrimary: false,
        button: 0,
      }),
    );
    button.click();
  });
  assert.equal(
    await page.evaluate(() => window.zoneFixture.changes.length),
    0,
    "multi-touch cancellation committed a zone move or inserted a midpoint",
  );
  const compact = await browser.newPage({
    viewport: { width: 320, height: 800 },
    isMobile: true,
    hasTouch: true,
  });
  for (const width of [320, 390, 700]) {
    await compact.setViewportSize({ width, height: 800 });
    for (const longLabel of [false, true]) {
      await compact.goto(
        `http://127.0.0.1:${address.port}/?toolbar=1${longLabel ? "&long=1" : ""}`,
      );
      const actions = compact.locator(".k-map-zone-editor__dirty-actions");
      const undo = actions.getByRole("button", {
        name: "Rückgängig",
        exact: true,
      });
      const discard = actions.getByRole("button", {
        name: "Verwerfen",
        exact: true,
      });
      const apply = actions.getByRole("button", {
        name: longLabel
          ? "Änderungen für dieses Gebiet übernehmen"
          : "Übernehmen",
        exact: true,
      });
      await undo.waitFor();
      assert.equal(await undo.getAttribute("title"), "Rückgängig");
      assert.equal(await discard.getAttribute("title"), "Verwerfen");
      assert.equal(await undo.innerText(), "");
      assert.equal(await discard.innerText(), "");
      assert.equal(await apply.getAttribute("data-variant"), "primary");
      const boxes = await Promise.all(
        [undo, discard, apply].map((control) => control.boundingBox()),
      );
      assert.ok(
        boxes.every((box) => box && box.x >= 0 && box.x + box.width <= width),
        `actions overflow ${width}px`,
      );
      assert.ok(
        Math.max(...boxes.map((box) => box.y)) -
          Math.min(...boxes.map((box) => box.y)) <=
          1,
        `actions wrapped at ${width}px`,
      );
      await actions.evaluate((element) =>
        Promise.all(
          element
            .getAnimations()
            .map((animation) => animation.finished.catch(() => {})),
        ),
      );
      const dirtyBox = await actions.boundingBox();
      const normalBar = compact.locator(".k-map-zone-editor__toolbar");
      assert.equal(await normalBar.getAttribute("aria-hidden"), "true");
      assert.equal(await normalBar.evaluate((element) => element.inert), true);
      await compact.evaluate(() => window.setToolbarDirty(false));
      await compact.waitForFunction(
        () =>
          document
            .querySelector(".k-map-zone-editor__toolbar")
            .getAttribute("data-visible") !== null,
      );
      await normalBar.evaluate((element) =>
        Promise.all(
          element
            .getAnimations()
            .map((animation) => animation.finished.catch(() => {})),
        ),
      );
      const toolbarBox = await normalBar.boundingBox();
      await compact.evaluate(() => window.setToolbarDirty(true));
      await compact.waitForFunction(
        () =>
          document
            .querySelector(".k-map-zone-editor__dirty-actions")
            .getAttribute("data-visible") !== null,
      );
      assert.ok(
        Math.abs(dirtyBox.width - toolbarBox.width) <= 1,
        `bar width mismatch at ${width}px`,
      );
      assert.ok(
        Math.abs(dirtyBox.x - toolbarBox.x) <= 1,
        `bar alignment mismatch at ${width}px`,
      );
      assert.ok(
        Math.abs(dirtyBox.height - toolbarBox.height) <= 1,
        `bar height mismatch at ${width}px`,
      );
      const surfaces = await compact.evaluate(() =>
        [
          ".k-map-zone-editor__dirty-actions",
          ".k-map-zone-editor__toolbar",
        ].map((selector) => {
          const style = getComputedStyle(document.querySelector(selector));
          return {
            radius: style.borderRadius,
            background: style.backgroundColor,
            padding: style.padding,
          };
        }),
      );
      assert.deepEqual(
        surfaces[0],
        surfaces[1],
        `bar surfaces mismatch at ${width}px`,
      );
      assert.ok(
        Math.abs(dirtyBox.y - toolbarBox.y) <= 1,
        `bars do not share bottom slot at ${width}px`,
      );
      const duration = await actions.evaluate(
        (element) => getComputedStyle(element).transitionDuration,
      );
      assert.ok(
        duration.split(",").some((value) => parseFloat(value) > 0),
        "dirty bar has no motion",
      );
      if (
        process.env.KDS_ZONE_EDITOR_SCREENSHOT &&
        width === 390 &&
        !longLabel
      ) {
        await actions.evaluate((element) =>
          Promise.all(
            element
              .getAnimations()
              .map((animation) => animation.finished.catch(() => {})),
          ),
        );
        await normalBar.evaluate((element) =>
          Promise.all(
            element
              .getAnimations()
              .map((animation) => animation.finished.catch(() => {})),
          ),
        );
        await compact.screenshot({
          path: process.env.KDS_ZONE_EDITOR_SCREENSHOT,
        });
      }
      await undo.click();
      await discard.click();
      await apply.click();
      assert.deepEqual(await compact.evaluate(() => window.toolbarActions), [
        "undo",
        "discard",
        "apply",
      ]);
      await apply.focus();
      await compact.evaluate(() => window.setToolbarDirty(false));
      await compact.waitForFunction(() =>
        document
          .querySelector(".k-map-zone-editor__toolbar")
          .contains(document.activeElement),
      );
      assert.equal(
        await compact
          .getByRole("button", {
            name: longLabel
              ? "Änderungen für dieses Gebiet übernehmen"
              : "Übernehmen",
            exact: true,
          })
          .count(),
        0,
      );
      await compact.waitForFunction(
        () =>
          document
            .querySelector(".k-map-zone-editor__dirty-actions")
            .getAttribute("aria-hidden") === "true",
      );
      assert.equal(await actions.getAttribute("aria-hidden"), "true");
      assert.equal(await actions.evaluate((element) => element.inert), true);
      await compact.waitForFunction(
        () =>
          getComputedStyle(
            document.querySelector(".k-map-zone-editor__dirty-actions"),
          ).display === "none",
      );
    }
  }
  await compact.goto(`http://127.0.0.1:${address.port}/?notification=1`);
  const notifications = compact.locator(".k-toast-viewport");
  await compact.getByRole("button", { name: "Undo", exact: true }).waitFor();
  await compact.waitForFunction(() => window.notificationHeights.at(-1) > 0);
  await compact.evaluate(() => window.setNotificationVisible(false));
  await compact.waitForFunction(
    () =>
      document
        .querySelector(".k-toast-viewport")
        .getAttribute("aria-hidden") === "true",
  );
  assert.equal(await notifications.getAttribute("aria-hidden"), "true");
  assert.equal(await notifications.evaluate((element) => element.inert), true);
  await compact.waitForFunction(() => !document.querySelector(".k-toast"));
  await compact.waitForFunction(() => window.notificationHeights.at(-1) === 0);
  await compact.emulateMedia({ reducedMotion: "reduce" });
  await compact.goto(`http://127.0.0.1:${address.port}/?toolbar=1`);
  const reducedBar = compact.locator(".k-map-zone-editor__dirty-actions");
  assert.equal(
    await reducedBar.evaluate(
      (element) => getComputedStyle(element).transitionDuration,
    ),
    "0s",
  );
  await compact.goto(`http://127.0.0.1:${address.port}/?notification=1`);
  assert.equal(
    await notifications.evaluate(
      (element) => getComputedStyle(element).transitionDuration,
    ),
    "0s",
  );
  await compact.evaluate(() => window.setNotificationVisible(false));
  await compact.waitForFunction(() => !document.querySelector(".k-toast"));
  await compact.waitForFunction(() => window.notificationHeights.at(-1) === 0);
  // The same surface grows into properties and back without replacing the dialog.
  await compact.emulateMedia({ reducedMotion: "no-preference" });
  for (const width of [390, 1100]) {
    await compact.setViewportSize({ width, height: 850 });
    await compact.goto(`http://127.0.0.1:${address.port}`);
    await compact.waitForFunction(() => !!window.externalZones);
    await compact.evaluate(() =>
      window.externalZones([
        {
          id: "review",
          name: "Reviewgebiet",
          kind: "polygon",
          color: "#155dfc",
          coordinates: [
            [13.3, 52.5],
            [13.4, 52.5],
            [13.4, 52.6],
            [13.3, 52.6],
          ],
        },
      ]),
    );
    await compact.getByRole("button", { name: "Alle", exact: true }).click();
    const surface = compact.locator(".k-map-zone-editor__floating-dialog");
    await compact.waitForFunction(() =>
      document
        .getAnimations()
        .every(
          (a) =>
            a.playState !== "running" ||
            a.effect?.getTiming().iterations === Infinity,
        ),
    );
    const listBox = await surface.boundingBox();
    const handle = await surface.elementHandle();
    await compact
      .getByRole("button", {
        name: "Zone bearbeiten: Reviewgebiet",
        exact: true,
      })
      .click();
    await compact.waitForFunction(
      () =>
        document
          .querySelector(
            '.k-map-zone-editor__floating-dialog[data-mode="properties"]',
          )
          ?.getAnimations().length === 0,
    );
    const editBox = await surface.boundingBox();
    assert.ok(editBox.height > listBox.height && editBox.y < listBox.y);
    assert.ok(editBox.x >= 0 && editBox.x + editBox.width <= width);
    assert.ok(
      Math.abs(editBox.y + editBox.height - listBox.y - listBox.height) < 2,
      JSON.stringify({ listBox, editBox }),
    );
    assert.equal(
      await handle.evaluate(
        (el) =>
          el === document.querySelector(".k-map-zone-editor__floating-dialog"),
      ),
      true,
    );
    assert.equal(
      await compact
        .getByRole("button", { name: "Fertig", exact: true })
        .count(),
      0,
    );
    assert.notEqual(
      await compact.evaluate(() => document.activeElement?.tagName),
      "INPUT",
    );
    await compact.getByRole("button", { name: "Farbe", exact: true }).click();
    assert.equal(
      await compact
        .locator(".k-map-zone-editor__color-summary")
        .getAttribute("aria-expanded"),
      "true",
    );
    await compact
      .getByRole("button", { name: "Farbe", exact: true })
      .press("Escape");
    assert.equal(await surface.getAttribute("data-mode"), "properties");
    assert.equal(
      await compact
        .locator(".k-map-zone-editor__color-summary")
        .getAttribute("aria-expanded"),
      "false",
    );
    await compact
      .getByRole("button", { name: "Zur\u00fcck", exact: true })
      .click();
    assert.equal(await surface.getAttribute("data-mode"), "list");
    await compact
      .getByRole("button", {
        name: "Reviewgebiet Individuelle Fläche",
        exact: true,
      })
      .click();
    await compact
      .getByRole("button", {
        name: "Zoneneigenschaften bearbeiten",
        exact: true,
      })
      .click();
    assert.equal(await surface.getAttribute("data-mode"), "properties");
    const nameBox = await compact
      .getByRole("textbox", { name: "Name", exact: true })
      .boundingBox();
    const colorBox = await compact
      .getByRole("button", { name: "Farbe", exact: true })
      .boundingBox();
    assert.ok(
      Math.abs(
        nameBox.y + nameBox.height / 2 - colorBox.y - colorBox.height / 2,
      ) < 4,
    );
    await compact
      .getByRole("button", { name: "Abbrechen", exact: true })
      .click();
    await compact.getByRole("dialog").waitFor({ state: "hidden" });
  }
  await compact.close();
  console.log(
    "Zone editor browser regression passed: circle apply/pending lifecycle, consumer undo + stale guard, equal-width bars at 320/390/700px, exit presence and reduced motion.",
  );
} finally {
  await browser?.close();
  await server.close();
}
